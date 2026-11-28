import { z } from "zod";
import type { Triage } from "./agents.js";
export const incidentTypes = [
  "support_call",
  "suspicious_message",
  "mistaken_report",
  "other",
  "email_phishing",
  "messaging_phishing",
  "voice_phishing",
  "deepfake_impersonation",
  "qr_phishing",
  "payment_fraud",
  "mfa_fatigue",
  "remote_access_scam",
] as const;
export const statuses = [
  "submitted",
  "in_review",
  "awaiting_employee",
  "escalated",
  "closed",
] as const;
export type Role = "security" | "data_protection";
export const observation = z
  .object({
    check: z.literal("secure_screen_lock"),
    platform: z.literal("android"),
    value: z.boolean(),
    checkedAt: z.iso.datetime(),
    source: z.literal("client_public_api"),
  })
  .strict();
export const createReport = z
  .object({
    employeeId: z.literal("demo-employee"),
    description: z.string().trim().min(10).max(5000),
    language: z.enum([
      "english",
      "hindi",
      "mixed",
      "ta",
      "te",
      "bn",
      "kn",
      "ml",
      "ur",
      "pa",
    ]),
    incidentType: z.enum(incidentTypes),
    appName: z.string().trim().max(200).default(""),
    evidenceNotes: z.string().trim().max(5000).default(""),
    observations: z.array(observation).max(10).default([]),
    reporting: z
      .object({
        language: z.enum([
          "en",
          "hi",
          "ta",
          "te",
          "bn",
          "kn",
          "ml",
          "ur",
          "pa",
        ]),
        transcript: z
          .array(
            z
              .object({
                speaker: z.enum(["employee", "agent"]),
                text: z.string().min(1).max(5000),
              })
              .strict(),
          )
          .max(12),
        unknowns: z.array(z.string().max(500)).max(12),
      })
      .strict()
      .optional(),
    confirmed: z.literal(true),
  })
  .strict();
export type SubmittedFacts = z.infer<typeof createReport>;
export type Report = {
  id: string;
  facts: SubmittedFacts;
  createdAt: string;
  updatedAt: string;
  status: (typeof statuses)[number];
  assignment: { team: Role; reviewer: string } | null;
  version: number;
  triage?: Triage;
};
export function ticketIncidentType(report: Report) {
  return (
    report.triage?.review?.incidentType ??
    report.triage?.result?.proposal.incident_type ??
    report.facts.incidentType
  );
}
export const adminChange = z.object({
  expectedVersion: z.number().int().positive(),
});
export const assignmentChange = adminChange
  .extend({
    team: z.enum(["security", "data_protection"]),
    reviewer: z.string().trim().max(100).default(""),
  })
  .strict();
export const statusChange = adminChange
  .extend({
    status: z.enum(["submitted", "in_review", "awaiting_employee", "closed"]),
  })
  .strict();
export const noteChange = adminChange
  .extend({ text: z.string().trim().min(1).max(5000) })
  .strict();
export const escalationChange = adminChange
  .extend({
    confirmed: z.literal(true),
    decision: z.enum(["escalate", "do_not_escalate"]),
    reason: z.string().trim().min(3).max(5000),
  })
  .strict();
