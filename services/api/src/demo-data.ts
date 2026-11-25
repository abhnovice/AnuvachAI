import { DatabaseSync } from "node:sqlite";
import { buildApp } from "./app.js";
import type { SubmittedFacts } from "./contracts.js";

const DAY = 86_400_000,
  HOUR = 3_600_000;
const scenarios = [
  {
    type: "support_call",
    description:
      "A caller claiming to be IT support asked me to install a remote-access tool and read out its session code. I ended the call.",
    app: "Remote Assist Demo",
    notes:
      "No password or session code is included. Caller identity has not been verified.",
  },
  {
    type: "suspicious_message",
    description:
      "I received an email saying my account would expire today. The message asked me to open a sign-in link that I did not recognise.",
    app: "",
    notes:
      "Synthetic message description only; no live URL or attachment was submitted.",
  },
  {
    type: "other",
    description:
      "An unexpected browser pop-up displayed a helpdesk number and asked me to call for support. I closed the tab.",
    app: "Demo browser",
    notes:
      "The pop-up text is employee-reported. Device compromise has not been established.",
  },
  {
    type: "mistaken_report",
    description:
      "I reported a helpdesk reminder, then found it matched a support appointment I had booked. Please review before closing.",
    app: "Demo helpdesk",
    notes:
      "Employee clarification supplied. Closure is an administrative workflow decision.",
  },
  {
    type: "support_call",
    description:
      "The caller asked me to approve an unexpected access prompt while claiming to fix a laptop issue. I did not approve it.",
    app: "Demo Remote Help",
    notes:
      "No automatic device observation confirms what the caller could access.",
  },
  {
    type: "suspicious_message",
    description:
      "मुझे एक संदेश मिला जिसमें सहायता टीम के नाम पर पासवर्ड रीसेट करने को कहा गया। मैंने लिंक नहीं खोला।",
    app: "",
    notes:
      "Synthetic Hindi account. No translation or AI assessment has been performed.",
  },
  {
    type: "other",
    description:
      "Someone at the office asked me to scan an unfamiliar setup QR code. I paused and asked the known helpdesk to verify the request.",
    app: "Demo onboarding",
    notes:
      "Synthetic scenario; the QR destination has not been scanned or analysed.",
  },
  {
    type: "support_call",
    description:
      "IT support बोलकर caller ने remote app install करने को कहा। मैंने call रोककर अपने known helpdesk से verify करने का फैसला किया।",
    app: "Demo Connect",
    notes: "Synthetic mixed-language account; no audio was recorded.",
  },
];
const workflows = [
  "closed",
  "in_review",
  "closed",
  "submitted",
  "escalated",
  "closed",
  "awaiting_employee",
  "closed",
] as const;
export async function seedDemo(filename: string, reference = new Date()) {
  // Pin the fixture epoch so repeated runs produce identical request payloads.
  const meta = new DatabaseSync(filename);
  meta.exec(
    "CREATE TABLE IF NOT EXISTS demo_fixture_meta (key TEXT PRIMARY KEY, epoch TEXT NOT NULL)",
  );
  meta
    .prepare("INSERT OR IGNORE INTO demo_fixture_meta VALUES(?,?)")
    .run("dashboard-v1", reference.toISOString());
  const anchor = Date.parse(
    meta
      .prepare("SELECT epoch FROM demo_fixture_meta WHERE key=?")
      .get("dashboard-v1")!.epoch as string,
  );
  meta.close();
  let clock = anchor;
  const app = await buildApp(filename, () => new Date(clock));
  let added = 0;
  try {
    for (let i = 0; i < 48; i++) {
      const scenario = scenarios[i % scenarios.length],
        index = String(i + 1).padStart(2, "0");
      const ageDays = 2 + i * 3;
      const created = anchor - ageDays * DAY - (i % 7) * HOUR;
      clock = created;
      const facts: SubmittedFacts = {
        employeeId: "demo-employee",
        description:
          "Synthetic scenario " + index + ": " + scenario.description,
        language: i % 8 === 5 ? "hindi" : i % 8 === 7 ? "mixed" : "english",
        incidentType: scenario.type as SubmittedFacts["incidentType"],
        appName: scenario.app,
        evidenceNotes: scenario.notes,
        confirmed: true,
        observations:
          i % 6 === 0
            ? [
                {
                  check: "secure_screen_lock",
                  platform: "android",
                  value: i % 12 === 0,
                  checkedAt: new Date(created - 5 * 60_000).toISOString(),
                  source: "client_public_api",
                },
              ]
            : [],
      };
      const response = await app.inject({
        method: "POST",
        url: "/api/v1/reports",
        headers: { "idempotency-key": "dashboard-demo-v1-" + index },
        payload: facts,
      });
      if (response.statusCode === 200) continue;
      if (response.statusCode !== 201) throw new Error(response.body);
      added++;
      let report = response.json();
      const base = "/api/v1/reports/" + report.id;
      const finalStatus = workflows[(i + Math.floor(i / 8)) % workflows.length];
      const action = async (
        kind: string,
        data: Record<string, unknown>,
        time: number,
      ) => {
        clock = time;
        const res = await app.inject({
          method: kind === "status" || kind === "assignment" ? "PATCH" : "POST",
          url: base + "/" + kind,
          payload: { expectedVersion: report.version, ...data },
        });
        if (res.statusCode !== 200) throw new Error(res.body);
        report = res.json();
      };
      if (finalStatus !== "submitted") {
        const first = created + (1 + (i % 5) * 2) * HOUR;
        await action(
          "assignment",
          {
            team: i % 3 === 0 ? "data_protection" : "security",
            reviewer: "Demo reviewer " + ["A", "B", "C"][i % 3],
          },
          first,
        );
        await action("status", { status: "in_review" }, first + 15 * 60_000);
        await action(
          "notes",
          {
            text: "Synthetic training case. Review the employee account separately from optional device observations; no AI severity or policy citation is available.",
          },
          first + 30 * 60_000,
        );
        if (finalStatus === "closed") {
          const turnaround = [4, 10, 18, 30, 52, 82, 110][
            Math.floor(i / 2) % 7
          ];
          const closedAt =
            created + Math.max(turnaround, (first - created) / HOUR + 1) * HOUR;
          // The newest fixture is two days old; keep every event in the past.
          await action(
            "status",
            { status: "closed" },
            Math.min(closedAt, anchor - HOUR),
          );
        } else if (finalStatus === "awaiting_employee") {
          await action(
            "status",
            { status: "awaiting_employee" },
            first + 4 * HOUR,
          );
        } else if (finalStatus === "escalated") {
          await action(
            "escalations",
            {
              confirmed: true,
              decision: "escalate",
              reason:
                "Synthetic decision: obtain a reviewer assessment of the reported access request.",
            },
            first + 3 * HOUR,
          );
        }
      }
    }
  } finally {
    await app.close();
  }
  return { added, totalFixtures: 48 };
}
