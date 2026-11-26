import Fastify from "fastify";
import { registerVoice } from "./voice.js";
import {
  AgentError,
  agentPost,
  analyze,
  reportingTurn,
  reportingResult,
  severities,
  teams,
} from "./agents.js";
import { buildDashboard, windowStart, type AuditRow } from "./analytics.js";
import cors from "@fastify/cors";
import { DatabaseSync } from "node:sqlite";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import {
  createReport,
  assignmentChange,
  statusChange,
  noteChange,
  escalationChange,
  incidentTypes,
  statuses,
  type Report,
} from "./contracts.js";

export async function buildApp(
  filename = process.env.DB_PATH ?? "anuvach.sqlite",
  now: () => Date = () => new Date(),
  agentBase = process.env.AGENTS_BASE_URL,
) {
  if (agentBase) {
    const url = new URL(agentBase);
    if (
      url.protocol !== "http:" ||
      url.hostname !== "127.0.0.1" ||
      url.username ||
      url.password
    )
      throw new Error("AGENTS_BASE_URL must be a local loopback HTTP address");
  }
  const db = new DatabaseSync(filename);
  db.exec(`PRAGMA journal_mode=WAL;
    CREATE TABLE IF NOT EXISTS reports (id TEXT PRIMARY KEY, data TEXT NOT NULL, request_key TEXT UNIQUE NOT NULL, request_body TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS audit (sequence INTEGER PRIMARY KEY AUTOINCREMENT, report_id TEXT NOT NULL, actor TEXT NOT NULL, action TEXT NOT NULL, at TEXT NOT NULL, data TEXT NOT NULL);
    CREATE TRIGGER IF NOT EXISTS audit_no_update BEFORE UPDATE ON audit BEGIN SELECT RAISE(ABORT, 'append only'); END;
    CREATE TRIGGER IF NOT EXISTS audit_no_delete BEFORE DELETE ON audit BEGIN SELECT RAISE(ABORT, 'append only'); END;
    PRAGMA user_version=1;`);
  const app = Fastify({ bodyLimit: 131072 });
  await app.register(cors, {
    origin: [process.env.ADMIN_ORIGIN ?? "http://localhost:5173"],
  });
  let worker: Promise<void> | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;
  let closing = false;
  app.addHook("onClose", async () => {
    closing = true;
    clearInterval(timer);
    await worker;
    db.close();
  });
  app.setErrorHandler((error, _req, reply) => {
    if (error instanceof z.ZodError)
      return reply
        .code(400)
        .send({ error: "Invalid input", details: error.issues });
    const e = error as Error & { statusCode?: number };
    return reply.code(e.statusCode ?? 500).send({
      error: e.statusCode
        ? e.message
        : "Storage or server error. Retry safely.",
    });
  });
  function fail(statusCode: number, message: string): never {
    throw Object.assign(new Error(message), { statusCode });
  }
  function get(id: string): Report {
    const row = db.prepare("SELECT data FROM reports WHERE id=?").get(id);
    if (!row) return fail(404, "Report not found");
    return JSON.parse(row.data as string);
  }
  function events(id: string) {
    return db
      .prepare(
        "SELECT sequence,actor,action,at,data FROM audit WHERE report_id=? ORDER BY sequence",
      )
      .all(id)
      .map((r) => ({ ...r, data: JSON.parse(r.data as string) }));
  }
  function transaction<T>(fn: () => T): T {
    db.exec("BEGIN IMMEDIATE");
    try {
      const result = fn();
      db.exec("COMMIT");
      return result;
    } catch (e) {
      db.exec("ROLLBACK");
      throw e;
    }
  }
  function audit(id: string, actor: string, action: string, data: unknown) {
    db.prepare(
      "INSERT INTO audit(report_id,actor,action,at,data) VALUES(?,?,?,?,?)",
    ).run(id, actor, action, now().toISOString(), JSON.stringify(data));
  }
  function employeeView({ triage: _triage, ...report }: Report) {
    return report;
  }

  function save(report: Report) {
    db.prepare("UPDATE reports SET data=? WHERE id=?").run(
      JSON.stringify(report),
      report.id,
    );
  }

  async function processTriage(base: string) {
    const row = db
      .prepare(
        `SELECT id FROM reports
      WHERE json_extract(data, '$.triage.status') = 'pending'
        AND COALESCE(json_extract(data, '$.triage.nextAttemptAt'), '') <= ?
      ORDER BY COALESCE(json_extract(data, '$.triage.nextAttemptAt'), ''), rowid LIMIT 1`,
      )
      .get(now().toISOString());
    if (!row) return;
    const report = get(row.id as string);
    const attempts = (report.triage?.attempts ?? 0) + 1;
    let triage: NonNullable<Report["triage"]>;
    try {
      triage = {
        status: "completed",
        attempts,
        ...(await analyze(base, report)),
      };
    } catch (error) {
      triage =
        error instanceof AgentError && error.invalid
          ? { status: "human_review", attempts, failure: "invalid_analysis" }
          : {
              status: "pending",
              attempts,
              failure: "unavailable",
              nextAttemptAt: new Date(
                now().getTime() +
                  Math.min(60, 2 ** Math.min(attempts, 6)) * 1000,
              ).toISOString(),
            };
    }
    transaction(() => {
      const current = get(report.id);
      if (current.triage?.status !== "pending") return;
      current.triage = triage;
      current.version++;
      save(current);
      audit(report.id, "local-agents", "triage_" + triage.status, {
        attempts,
        failure: triage.failure,
        taskId: triage.result?.taskId,
        responder: triage.result?.responder,
      });
    });
  }

  function kickTriage() {
    if (!agentBase || worker || closing) return;
    worker = processTriage(agentBase)
      .catch(() => app.log.error("Could not persist local triage state"))
      .finally(() => {
        worker = undefined;
      });
  }

  app.addHook("onReady", async () => {
    if (!agentBase) return;
    timer = setInterval(kickTriage, 1000);
    timer.unref();
    kickTriage();
  });

  registerVoice(app, agentBase);

  app.post("/api/v1/reporting/turns", async (req, reply) => {
    const turn = reportingTurn.parse(req.body);
    if (!agentBase)
      return reply.code(503).send({
        error: "Reporting assistant is unavailable. Continue with text.",
      });
    try {
      return reportingResult.parse(
        await agentPost(agentBase, "/internal/reporting/turn", turn, 35_000),
      );
    } catch {
      return reply.code(503).send({
        error: "Reporting assistant is unavailable. Continue with text.",
      });
    }
  });

  app.get("/health", async () => ({
    ok: true,
    mode: "synthetic-demo-no-auth",
  }));
  app.post("/api/v1/reports", async (req, reply) => {
    const facts = createReport.parse(req.body);
    const key = z
      .string()
      .min(8)
      .max(128)
      .parse(req.headers["idempotency-key"]);
    const body = JSON.stringify(facts);
    const report = transaction(() => {
      const previous = db
        .prepare("SELECT id,request_body FROM reports WHERE request_key=?")
        .get(key);
      if (previous) {
        if (previous.request_body !== body)
          return fail(409, "Retry key belongs to a different payload");
        return get(previous.id as string);
      }
      const timestamp = now().toISOString();
      const report: Report = {
        id: "ANV-" + randomUUID(),
        facts,
        createdAt: timestamp,
        updatedAt: timestamp,
        status: "submitted",
        assignment: null,
        version: 1,
        ...(agentBase
          ? { triage: { status: "pending", attempts: 0 } as const }
          : {}),
      };
      db.prepare("INSERT INTO reports VALUES(?,?,?,?)").run(
        report.id,
        JSON.stringify(report),
        key,
        body,
      );
      audit(report.id, "demo-employee", "created", facts);
      reply.code(201);
      return report;
    });
    if (reply.statusCode === 201) kickTriage();
    return employeeView(report);
  });
  function allReports(): Report[] {
    return db
      .prepare("SELECT data FROM reports ORDER BY rowid DESC")
      .all()
      .map((r) => JSON.parse(r.data as string) as Report);
  }
  const dayRange = z.enum(["30", "90", "180"]).transform(Number);
  app.get("/api/v1/dashboard", async (req) => {
    const q = z
      .object({
        days: dayRange.default(90),
        incidentType: z.enum(incidentTypes).optional(),
      })
      .strict()
      .parse(req.query);
    const rows = db
      .prepare(
        "SELECT report_id,action,at,sequence,data FROM audit ORDER BY sequence",
      )
      .all()
      .map((row) => ({
        ...row,
        data: JSON.parse(row.data as string),
      })) as AuditRow[];
    return buildDashboard(allReports(), rows, now(), q.days, q.incidentType);
  });
  app.get("/api/v1/reports", async (req) => {
    const q = z
      .object({
        employeeId: z.literal("demo-employee").optional(),
        status: z.enum(statuses).optional(),
        incidentType: z.enum(incidentTypes).optional(),
        days: dayRange.optional(),
      })
      .strict()
      .parse(req.query);
    const current = now(),
      since = q.days ? windowStart(q.days, current).getTime() : null;
    return allReports()
      .filter(
        (r) =>
          (!q.employeeId || r.facts.employeeId === q.employeeId) &&
          (!q.status || r.status === q.status) &&
          (!q.incidentType || r.facts.incidentType === q.incidentType) &&
          (since === null ||
            (Date.parse(r.createdAt) >= since &&
              Date.parse(r.createdAt) <= current.getTime())),
      )
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .map(employeeView);
  });
  app.get("/api/v1/reports/:id", async (req) => {
    const { id } = req.params as { id: string };
    const q = z
      .object({ view: z.enum(["employee", "admin"]).default("employee") })
      .strict()
      .parse(req.query);
    const report = get(id);
    return q.view === "admin"
      ? {
          ...report,
          audit: events(id),
          policyCitations: null,
          aiSeverity: null,
        }
      : employeeView(report);
  });
  for (const kind of [
    "status",
    "assignment",
    "notes",
    "escalations",
    "triage-review",
  ] as const) {
    const handler = async (req: { params: unknown; body: unknown }) => {
      const { id } = req.params as { id: string };
      const schema = {
        status: statusChange,
        assignment: assignmentChange,
        notes: noteChange,
        escalations: escalationChange,
        "triage-review": z
          .object({
            expectedVersion: z.number().int().positive(),
            proposalId: z.string().min(1),
            severity: z.enum(severities),
            team: z.enum(teams),
          })
          .strict(),
      }[kind];
      const change = schema.parse(req.body);
      return transaction(() => {
        const report = get(id);
        if (report.version !== change.expectedVersion)
          return fail(
            409,
            "Report changed. Refresh and review before retrying.",
          );
        if (kind === "triage-review") {
          const c = change as {
            proposalId: string;
            severity: (typeof severities)[number];
            team: (typeof teams)[number];
          };
          const proposal = report.triage?.result?.proposal;
          if (
            !report.triage ||
            !proposal ||
            proposal.proposal_id !== c.proposalId
          )
            return fail(
              409,
              "The proposal is unavailable. Refresh the ticket.",
            );
          report.triage.review = {
            proposalId: c.proposalId,
            severity: c.severity,
            team: c.team,
            decision:
              c.severity === proposal.proposed_severity &&
              c.team === proposal.proposed_team
                ? "accepted"
                : "amended",
            at: now().toISOString(),
          };
        }
        if (kind === "status")
          report.status = statusChange.parse(change).status;
        if (kind === "assignment") {
          const c = assignmentChange.parse(change);
          report.assignment = { team: c.team, reviewer: c.reviewer };
        }
        if (
          kind === "escalations" &&
          escalationChange.parse(change).decision === "escalate"
        )
          report.status = "escalated";
        report.updatedAt = now().toISOString();
        report.version++;
        save(report);
        audit(
          id,
          "demo-admin",
          kind,
          kind === "triage-review" ? report.triage?.review : change,
        );
        return {
          ...report,
          audit: events(id),
          policyCitations: null,
          aiSeverity: null,
        };
      });
    };
    if (kind === "status" || kind === "assignment")
      app.patch("/api/v1/reports/:id/" + kind, handler);
    else app.post("/api/v1/reports/:id/" + kind, handler);
  }
  return app;
}
