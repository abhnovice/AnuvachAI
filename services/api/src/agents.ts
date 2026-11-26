import { z } from "zod";
import { incidentTypes, type Report } from "./contracts.js";

export const agentLanguage = z.enum([
  "en",
  "hi",
  "ta",
  "te",
  "bn",
  "kn",
  "ml",
  "ur",
  "pa",
]);
const id = z.string().min(1);
export const severities = [
  "unassessed",
  "low",
  "moderate",
  "high",
  "critical",
] as const;
export const teams = [
  "unknown",
  "security",
  "it_support",
  "data_protection",
] as const;

const proposal = z.object({
  proposal_id: id,
  report_id: id,
  report_revision: z.literal(1),
  incident_type: z.enum(incidentTypes),
  proposed_severity: z.enum(severities),
  proposed_team: z.enum(teams),
  reasons: z.array(z.object({ text: id, fact_ids: z.array(id).min(1) })).min(1),
  evidence_references: z.array(z.object({ fact_id: id, explains: id })).min(1),
  unknowns: z.array(z.string()),
  recommended_next_questions: z.array(z.string()),
  human_review_required: z.literal(true),
});
const result = z.object({
  proposal,
  taskId: id,
  responder: z.enum(["Gemini responder", "synthetic responder"]),
  latencyMs: z.number().nonnegative(),
  model: z.string().optional(),
});

export const reportingTurn = z
  .object({
    sessionId: z.uuid(),
    language: agentLanguage,
    text: z.string().trim().min(1).max(5000),
  })
  .strict();
export const reportingResult = z.object({
  reply: z.string().min(1).max(5000),
  unknowns: z.array(z.string().max(500)).max(12),
});

export type Triage = {
  status: "pending" | "completed" | "human_review";
  attempts: number;
  nextAttemptAt?: string;
  failure?: "unavailable" | "invalid_analysis";
  result?: z.infer<typeof result>;
  evidence?: { fact_id: string; text: string }[];
  review?: {
    proposalId: string;
    incidentType?: (typeof incidentTypes)[number];
    severity: (typeof severities)[number];
    team: (typeof teams)[number];
    decision: "accepted" | "amended";
    at: string;
  };
};

export class AgentError extends Error {
  constructor(readonly invalid: boolean) {
    super(invalid ? "Invalid analysis" : "Agent service unavailable");
  }
}

export async function agentPost(
  base: string,
  path: string,
  body: unknown,
  timeout: number,
) {
  try {
    const response = await fetch(new URL(path, base), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeout),
    });
    if (!response.ok) throw new AgentError(response.status === 422);
    try {
      return await response.json();
    } catch {
      throw new AgentError(true);
    }
  } catch (error) {
    throw error instanceof AgentError ? error : new AgentError(false);
  }
}

export async function analyze(base: string, report: Report) {
  const details = report.facts.reporting;
  const language =
    details?.language ??
    (report.facts.language === "hindi"
      ? "hi"
      : report.facts.language === "english" || report.facts.language === "mixed"
        ? "en"
        : report.facts.language);
  const statements = [
    ...[
      report.facts.description,
      report.facts.appName && `Reported app: ${report.facts.appName}`,
      report.facts.evidenceNotes &&
        `Employee evidence notes: ${report.facts.evidenceNotes}`,
    ]
      .filter(Boolean)
      .flatMap((text) =>
        Array.from(text).reduce<string[]>((chunks, char, index) => {
          if (index % 4000 === 0) chunks.push(char);
          else chunks[chunks.length - 1] += char;
          return chunks;
        }, []),
      )
      .map((text) => ({ source: "employee_statement", text })),
    ...report.facts.observations.map((observation) => ({
      source: "consented_device_observation",
      text: `Device reported Android secure screen lock configured: ${observation.value}.`,
      observed_at: observation.checkedAt,
      consented: true,
      observation_type: observation.check,
    })),
  ];
  const facts = statements.map((item, index) => ({
    ...item,
    fact_id: "F" + String(index + 1).padStart(3, "0"),
  }));
  const response = result.safeParse(
    await agentPost(
      base,
      "/internal/triage",
      {
        report_id: report.id,
        revision: 1,
        preferred_language: language,
        incident_type: report.facts.incidentType,
        facts,
        transcript: [],
        unknowns: details?.unknowns ?? [],
        confirmation_id: report.id,
        confirmed_by: report.facts.employeeId,
        confirmed_at: report.createdAt,
        correlation_id: report.id,
        idempotency_key: report.id,
      },
      40_000,
    ),
  );
  if (!response.success) throw new AgentError(true);
  const output = response.data.proposal;
  const known = new Set(facts.map((item) => item.fact_id));
  const references = [
    ...output.reasons.flatMap((item) => item.fact_ids),
    ...output.evidence_references.map((item) => item.fact_id),
  ];
  if (
    output.report_id !== report.id ||
    references.some((ref) => !known.has(ref)) ||
    ["high", "critical"].includes(output.proposed_severity)
  )
    throw new AgentError(true);
  return {
    result: response.data,
    evidence: facts.map(({ fact_id, text }) => ({ fact_id, text })),
  };
}
