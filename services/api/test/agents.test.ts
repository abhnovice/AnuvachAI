import assert from "node:assert/strict";
import { once } from "node:events";
import { createServer } from "node:http";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { test } from "node:test";
import { buildApp } from "../src/app.js";

test("existing ticket survives peer outage, restart, and duplicate submission", async () => {
  let available = false;
  let calls = 0;
  const context = [
    { speaker: "employee", text: "A caller claimed to be from IT." },
  ];
  const reportingRequests: unknown[] = [];
  const translations: unknown[] = [];
  const assistantRequests: any[] = [];
  const peer = createServer(async (request, response) => {
    let body = "";
    for await (const chunk of request) body += chunk;
    response.setHeader("Content-Type", "application/json");
    if (request.url === "/internal/reporting/turn") {
      reportingRequests.push(JSON.parse(body).context);
      response.end(
        JSON.stringify({ reply: "When did it happen?", unknowns: ["Time"] }),
      );
      return;
    }
    if (request.url === "/internal/reporting/translate") {
      translations.push(JSON.parse(body));
      response.end(JSON.stringify({ translation: "किसी ने कोड माँगा।" }));
      return;
    }
    if (request.url === "/internal/admin/assistant") {
      assistantRequests.push(JSON.parse(body));
      response.end(
        JSON.stringify({
          reply: "Open All Reports to view the selected ticket.",
        }),
      );
      return;
    }
    calls++;
    if (!available) {
      response.writeHead(503).end("{}");
      return;
    }
    const { report_id } = JSON.parse(body);
    response.end(
      JSON.stringify({
        taskId: "local-task-1",
        latencyMs: 5,
        responder: "synthetic responder",
        proposal: {
          proposal_id: "local-proposal-1",
          report_id,
          report_revision: 1,
          incident_type: "voice_phishing",
          proposed_severity: "unassessed",
          proposed_team: "security",
          human_review_required: true,
          reasons: [
            { text: "Employee reports a request.", fact_ids: ["F001"] },
          ],
          evidence_references: [
            { fact_id: "F001", explains: "Reported request." },
          ],
          unknowns: [],
          recommended_next_questions: [],
        },
      }),
    );
  });
  peer.listen(0, "127.0.0.1");
  await once(peer, "listening");
  const address = peer.address();
  assert(address && typeof address === "object");
  const directory = await mkdtemp(join(tmpdir(), "anuvach-agent-api-"));
  const path = join(directory, "api.sqlite");
  const base = "http://127.0.0.1:" + address.port;
  let clock = Date.now();
  let app = await buildApp(path, () => new Date(clock), base);
  try {
    const draft = await app.inject({
      method: "POST",
      url: "/api/v1/reporting/turns",
      payload: {
        sessionId: "c5a6866b-69ed-4d14-baf3-32d43093dfa0",
        language: "en",
        text: "A caller asked for a code.",
        context,
      },
    });
    assert.equal(draft.statusCode, 200);
    assert.deepEqual(reportingRequests, [context]);
    assert.equal((await app.inject("/api/v1/reports")).json().length, 0);
    const submission = {
      method: "POST" as const,
      url: "/api/v1/reports",
      headers: { "idempotency-key": "local-stage3-retry" },
      payload: {
        employeeId: "demo-employee",
        description: "A caller asked for a pairing code.",
        language: "english",
        incidentType: "support_call",
        confirmed: true,
      },
    };
    const created = await app.inject(submission);
    assert.equal(created.statusCode, 201);
    const { id } = created.json();
    const translated = await app.inject(
      "/api/v1/reports/" + id + "?translate=hi",
    );
    assert.equal(translated.statusCode, 200);
    assert.deepEqual(translated.json(), { translation: "किसी ने कोड माँगा।" });
    assert.deepEqual(translations, [
      { language: "hi", text: submission.payload.description },
    ]);
    assert.equal(
      (await app.inject("/api/v1/reports/" + id)).json().facts.description,
      submission.payload.description,
    );
    const notices = await app.inject("/api/v1/admin/notifications");
    assert.equal(notices.statusCode, 200);
    assert.equal(notices.json()[0].id, id);
    assert.equal(notices.json()[0].summary, submission.payload.description);
    const assistant = await app.inject({
      method: "POST",
      url: "/api/v1/admin/assistant",
      payload: {
        message: "Summarize this report.",
        view: "reports",
        ticketId: id,
        scope: { days: 30, group: "vishing" },
      },
    });
    assert.equal(assistant.statusCode, 200);
    assert.equal(
      assistantRequests[0].context.selected.description,
      submission.payload.description,
    );
    assert.equal(assistantRequests[0].context.reportCount, 1);
    assert.equal(
      (await app.inject("/api/v1/reports?incidentGroup=vishing")).json()[0].id,
      id,
    );
    const adminPath = "/api/v1/reports/" + id + "?view=admin";
    const poll = async (predicate: (data: any) => boolean) => {
      for (let i = 0; i < 100; i++) {
        const data = (await app.inject(adminPath)).json();
        if (predicate(data)) return data;
        await delay(25);
      }
      assert.fail("Expected ticket state was unavailable");
    };
    const pending = await poll(
      (data) => data.triage?.failure === "unavailable",
    );
    assert.equal(pending.triage.status, "pending");
    assert.equal((await app.inject(submission)).json().id, id);
    assert.equal(calls, 1);
    await app.close();
    available = true;
    clock += 5000;
    app = await buildApp(path, () => new Date(clock), base);
    const completed = await poll((data) => data.triage?.status === "completed");
    assert.equal(completed.triage.result.taskId, "local-task-1");
    assert.equal(completed.incidentCategory, "voice_phishing");
    assert.equal(completed.facts.incidentType, "support_call");
    const queue = await app.inject(
      "/api/v1/reports?incidentType=voice_phishing",
    );
    assert.equal(queue.json()[0].id, id);
    assert.equal((await app.inject(submission)).json().id, id);
    assert.equal(calls, 2);
    const review = {
      method: "POST" as const,
      url: "/api/v1/reports/" + id + "/triage-review",
      payload: {
        expectedVersion: completed.version,
        proposalId: "local-proposal-1",
        incidentType: "remote_access_scam",
        severity: "unassessed",
        team: "security",
      },
    };
    assert.equal(
      (await app.inject(review)).json().triage.review.decision,
      "amended",
    );
    assert.equal((await app.inject(review)).statusCode, 409);
    const dashboard = (
      await app.inject("/api/v1/dashboard?incidentType=remote_access_scam")
    ).json();
    assert.equal(
      dashboard.incidentMix.find(
        (row: { type: string }) => row.type === "remote_access_scam",
      ).count,
      1,
    );
    const oldQueue = await app.inject(
      "/api/v1/reports?incidentType=voice_phishing",
    );
    assert.deepEqual(oldQueue.json(), []);
    assert.equal(
      (await app.inject("/api/v1/reports/" + id)).json().triage,
      undefined,
    );
  } finally {
    await app.close();
    await new Promise<void>((resolve) => peer.close(() => resolve()));
    await rm(directory, { recursive: true });
  }
});

test("all report languages preserve reviewed native-script descriptions", async () => {
  const app = await buildApp(":memory:", () => new Date(), "");
  const cases = {
    english: "I received a suspicious support call.",
    hindi: "मुझे एक संदिग्ध सहायता कॉल आया।",
    ta: "எனக்கு சந்தேகமான ஆதரவு அழைப்பு வந்தது.",
    te: "నాకు అనుమానాస్పద మద్దతు కాల్ వచ్చింది.",
    bn: "আমি একটি সন্দেহজনক সহায়তা ফোন পেয়েছি।",
    kn: "ನನಗೆ ಅನುಮಾನಾಸ್ಪದ ಬೆಂಬಲ ಕರೆ ಬಂದಿದೆ.",
    ml: "എനിക്ക് സംശയാസ്പദമായ സഹായ കോൾ ലഭിച്ചു.",
    ur: "مجھے ایک مشکوک معاونتی کال موصول ہوئی۔",
    pa: "ਮੈਨੂੰ ਇੱਕ ਸ਼ੱਕੀ ਸਹਾਇਤਾ ਕਾਲ ਆਈ।",
  };
  try {
    for (const [language, text] of Object.entries(cases)) {
      const description = `${text} ${text}`;
      const response = await app.inject({
        method: "POST",
        url: "/api/v1/reports",
        headers: { "idempotency-key": "stage3-language-" + language },
        payload: {
          employeeId: "demo-employee",
          description,
          language,
          incidentType: "support_call",
          confirmed: true,
        },
      });
      assert.equal(response.statusCode, 201);
      const report = (
        await app.inject("/api/v1/reports/" + response.json().id)
      ).json();
      assert.equal(report.facts.description, description);
      assert.equal(report.facts.language, language);
    }
  } finally {
    await app.close();
  }
});
