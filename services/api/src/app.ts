import websocket from "@fastify/websocket";
import Fastify from "fastify";
import { registerVoice } from "./voice.js";
import {
  AgentError,
  agentLanguage,
  agentPost,
  analyze,
  reportingTurn,
  reportingResult,
  severities,
  teams,
} from "./agents.js";
import { buildDashboard, windowStart } from "./analytics.js";
import { incidentGroup, incidentGroups } from "./incident-groups.js";
import cors from "@fastify/cors";
import { createHash } from "node:crypto";
import { employeeUid, registerAccess, type Access } from "./auth.js";
import { fail, sqliteStore, type ReportStore } from "./report-store.js";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import {
  createReport,
  assignmentChange,
  statusChange,
  noteChange,
  escalationChange,
  incidentTypes,
  ticketIncidentType,
  statuses,
  type Report,
} from "./contracts.js";

export async function buildApp(
  filename = process.env.DB_PATH ?? "anuvach.sqlite",
  now: () => Date = () => new Date(),
  agentBase = process.env.AGENTS_BASE_URL,
  options: { store?: ReportStore; access?: Access } = {},
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
  const store = options.store ?? sqliteStore(filename);
  const app = Fastify({ bodyLimit: 131072 });
  await app.register(cors, {
    origin: [
      new URL(process.env.ADMIN_ORIGIN ?? "http://localhost:5173").origin,
    ],
    methods: ["GET", "HEAD", "POST", "PATCH"],
  });
  await app.register(websocket, { options: { maxPayload: 4096 } });
  registerAccess(app, options.access);
  let worker: Promise<void> | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;
  let closing = false;
  app.addHook("onClose", async () => {
    closing = true;
    clearInterval(timer);
    await worker;
    store.close();
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
  function employeeView({ triage: _triage, ...report }: Report) {
    return report;
  }

  async function processTriage(base: string) {
    const claim = await store.claim(now().toISOString());
    if (!claim) return;
    const { report, lease } = claim;
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
                  (options.store
                    ? Math.min(600, 30 * 2 ** Math.min(attempts - 1, 5))
                    : Math.min(60, 2 ** Math.min(attempts, 6))) *
                    1000,
              ).toISOString(),
            };
    }
    await store.update(
      report.id,
      ({ report: current }) => {
        if (current.triage?.status !== "pending") return;
        current.triage = triage;
        current.version++;
        return {
          actor: "local-agents",
          action: "triage_" + triage.status,
          at: now().toISOString(),
          data: {
            attempts,
            failure: triage.failure,
            taskId: triage.result?.taskId,
            responder: triage.result?.responder,
          },
        };
      },
      lease,
    );
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
    timer = setInterval(kickTriage, options.store ? 30_000 : 1000);
    timer.unref();
    kickTriage();
  });

  registerVoice(app, agentBase);

  app.post("/api/v1/reporting/turns", async (req, reply) => {
    const turn = reportingTurn.parse(req.body);
    const uid = employeeUid(req);
    if (uid) {
      // Namespace client-supplied session IDs by authenticated employee.
      const digest = createHash("sha256")
        .update(JSON.stringify([uid, turn.sessionId]))
        .digest("hex");
      turn.sessionId = `${digest.slice(0, 8)}-${digest.slice(8, 12)}-4${digest.slice(13, 16)}-8${digest.slice(17, 20)}-${digest.slice(20, 32)}`;
    }
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
    mode: options.access ? "firebase-authenticated" : "synthetic-demo-no-auth",
  }));
  function queueSeverity(report: Report) {
    const reviewed = report.triage?.review?.severity;
    const proposed = report.triage?.result?.proposal.proposed_severity;
    return reviewed
      ? { severity: reviewed, source: "reviewed" as const }
      : proposed && proposed !== "unassessed"
        ? { severity: proposed, source: "suggested" as const }
        : { severity: "unassessed" as const, source: null };
  }

  function reportSummary(report: Report) {
    return {
      id: report.id,
      createdAt: report.createdAt,
      status: report.status,
      category: ticketIncidentType(report),
      summary: report.facts.description
        .replace(/\s+/g, " ")
        .trim()
        .slice(0, 180),
      ...queueSeverity(report),
    };
  }

  app.get("/api/v1/admin/notifications", async () =>
    (await store.recent(12)).map(({ report }) => reportSummary(report)),
  );

  app.post("/api/v1/admin/assistant", async (req) => {
    const body = z
      .object({
        message: z.string().trim().min(1).max(800),
        history: z
          .array(
            z
              .object({
                role: z.enum(["user", "assistant"]),
                text: z.string().min(1).max(2000),
              })
              .strict(),
          )
          .max(6)
          .default([]),
        view: z.enum(["dashboard", "reports"]),
        scope: z
          .object({
            days: z.union([z.literal(30), z.literal(90), z.literal(180)]),
            category: z.enum(incidentTypes).optional(),
            group: z.enum(incidentGroups).optional(),
            status: z.enum([...statuses, "open"]).optional(),
          })
          .strict()
          .default({ days: 90 }),
        ticketId: z
          .string()
          .regex(/^ANV-[a-zA-Z0-9-]+$/)
          .max(64)
          .optional(),
        language: agentLanguage.default("en"),
      })
      .strict()
      .parse(req.body);
    if (!agentBase) fail(503, "Website assistant is unavailable.");
    try {
      const ticketId =
        body.message.match(/\bANV-[a-zA-Z0-9-]{4,60}\b/)?.[0] ?? body.ticketId;
      const selected = ticketId
        ? await store
            .get(ticketId)
            .then(({ report }) => report)
            .catch((error) => {
              if (error?.statusCode === 404) return null;
              throw error;
            })
        : null;
      const current = now();
      const end = current.toISOString();
      const { days, category, group, status } = body.scope;
      const start = windowStart(days, current).toISOString();
      const cohort = (await store.list())
        .map(({ report }) => report)
        .filter(
          (report) =>
            report.createdAt >= start &&
            report.createdAt <= end &&
            (!category || ticketIncidentType(report) === category) &&
            (!group || incidentGroup(ticketIncidentType(report)) === group) &&
            (!status ||
              (status === "open"
                ? report.status !== "closed"
                : report.status === status)),
        );
      const result = await agentPost(
        agentBase,
        "/internal/admin/assistant",
        {
          ...body,
          context: {
            since: start,
            reportCount: cohort.length,
            statusCounts: Object.fromEntries(
              statuses.map((status) => [
                status,
                cohort.filter((report) => report.status === status).length,
              ]),
            ),
            groups: Object.fromEntries(
              incidentGroups.map((group) => [
                group,
                cohort.filter(
                  (report) =>
                    incidentGroup(ticketIncidentType(report)) === group,
                ).length,
              ]),
            ),
            recent: (await store.recent(5)).map(({ report }) =>
              reportSummary(report),
            ),
            selected: selected
              ? {
                  ...reportSummary(selected),
                  description: selected.facts.description,
                }
              : null,
          },
        },
        20_000,
      );
      return z.object({ reply: z.string().min(1).max(2000) }).parse(result);
    } catch {
      fail(503, "Website assistant is unavailable. Try again.");
    }
  });

  app.post("/api/v1/reports", async (req, reply) => {
    const facts = createReport.parse(req.body);
    const key = z
      .string()
      .min(8)
      .max(128)
      .parse(req.headers["idempotency-key"]);
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
    const owner = employeeUid(req);
    const { entry, created } = await store.create(
      { report, ...(owner ? { owner } : {}) },
      key,
      {
        actor: owner ?? "demo-employee",
        action: "created",
        at: timestamp,
        data: facts,
      },
    );
    if (created) {
      reply.code(201);
      kickTriage();
    }
    return employeeView(entry.report);
  });
  const dayRange = z.enum(["30", "90", "180"]).transform(Number);
  app.get("/api/v1/dashboard", async (req) => {
    const q = z
      .object({
        days: dayRange.default(90),
        incidentType: z.enum(incidentTypes).optional(),
        incidentGroup: z.enum(incidentGroups).optional(),
      })
      .strict()
      .parse(req.query);
    const [entries, rows] = await Promise.all([store.list(), store.events()]);
    return buildDashboard(
      entries.map(({ report }) => report),
      rows,
      now(),
      q.days,
      q.incidentType,
      q.incidentGroup,
    );
  });
  app.get("/api/v1/reports", async (req) => {
    const q = z
      .object({
        employeeId: z.literal("demo-employee").optional(),
        status: z.enum(statuses).optional(),
        incidentType: z.enum(incidentTypes).optional(),
        incidentGroup: z.enum(incidentGroups).optional(),
        days: dayRange.optional(),
      })
      .strict()
      .parse(req.query);
    const current = now(),
      since = q.days ? windowStart(q.days, current).getTime() : null;
    const owner = employeeUid(req);
    const adminQueue = !owner && !q.employeeId;
    return (await store.list())
      .filter((entry) => !owner || entry.owner === owner)
      .map((entry) => entry.report)
      .filter(
        (r) =>
          (!q.employeeId || r.facts.employeeId === q.employeeId) &&
          (!q.status || r.status === q.status) &&
          (!q.incidentType ||
            (adminQueue ? ticketIncidentType(r) : r.facts.incidentType) ===
              q.incidentType) &&
          (!q.incidentGroup ||
            incidentGroup(
              adminQueue ? ticketIncidentType(r) : r.facts.incidentType,
            ) === q.incidentGroup) &&
          (since === null ||
            (Date.parse(r.createdAt) >= since &&
              Date.parse(r.createdAt) <= current.getTime())),
      )
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .map((report) =>
        adminQueue
          ? {
              ...employeeView(report),
              incidentCategory: ticketIncidentType(report),
              queueSeverity: queueSeverity(report),
            }
          : employeeView(report),
      );
  });
  app.get("/api/v1/reports/:id", async (req) => {
    const { id } = req.params as { id: string };
    const q = z
      .object({
        view: z.enum(["employee", "admin"]).default("employee"),
        translate: agentLanguage.optional(),
      })
      .strict()
      .parse(req.query);
    const { report, owner } = await store.get(id);
    if (employeeUid(req) && employeeUid(req) !== owner)
      fail(404, "Report not found");
    if (q.translate) {
      if (!agentBase) fail(503, "Description translation is unavailable");
      try {
        const translated = await agentPost(
          agentBase,
          "/internal/reporting/translate",
          {
            language: q.translate,
            text: report.facts.description,
          },
          25_000,
        );
        return z
          .object({ translation: z.string().min(1).max(16000) })
          .parse(translated);
      } catch {
        fail(503, "Description translation is unavailable");
      }
    }
    return q.view === "admin"
      ? {
          ...report,
          audit: await store.events(id),
          incidentCategory: ticketIncidentType(report),
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
    const handler = async (req: import("fastify").FastifyRequest) => {
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
            incidentType: z.enum(incidentTypes).optional(),
            severity: z.enum(severities),
            team: z.enum(teams),
          })
          .strict(),
      }[kind];
      const change = schema.parse(req.body);
      const { report } = await store.update(id, ({ report }) => {
        if (report.version !== change.expectedVersion)
          return fail(
            409,
            "Report changed. Refresh and review before retrying.",
          );
        if (kind === "triage-review") {
          const c = change as {
            proposalId: string;
            incidentType?: (typeof incidentTypes)[number];
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
          const incidentType = c.incidentType ?? proposal.incident_type;
          report.triage.review = {
            proposalId: c.proposalId,
            incidentType,
            severity: c.severity,
            team: c.team,
            decision:
              c.severity === proposal.proposed_severity &&
              c.team === proposal.proposed_team &&
              (c.incidentType ?? proposal.incident_type) ===
                proposal.incident_type
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
        return {
          actor: req.identity?.uid ?? "demo-admin",
          action: kind,
          at: report.updatedAt,
          data: kind === "triage-review" ? report.triage!.review! : change,
        };
      });
      return {
        ...report,
        incidentCategory: ticketIncidentType(report),
        audit: await store.events(id),
        policyCitations: null,
        aiSeverity: null,
      };
    };
    if (kind === "status" || kind === "assignment")
      app.patch("/api/v1/reports/:id/" + kind, handler);
    else app.post("/api/v1/reports/:id/" + kind, handler);
  }
  return app;
}
