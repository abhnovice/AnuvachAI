import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { firestoreStore } from "../src/report-store.js";
import type { Report } from "../src/contracts.js";

test(
  "Firestore carries ticket, replay, triage lease and amended audit into a fresh SDK client",
  {
    skip: !process.env.FIRESTORE_EMULATOR_HOST,
  },
  async () => {
    const projectId = "demo-anuvach-" + randomUUID().slice(0, 8);
    const first = initializeApp({ projectId }, projectId + "-first");
    const second = initializeApp({ projectId }, projectId + "-second");
    try {
      const a = firestoreStore(getFirestore(first));
      const b = firestoreStore(getFirestore(second));
      const at = "2026-11-26T12:00:00.000Z";
      const report: Report = {
        id: "ANV-" + randomUUID(),
        facts: {
          employeeId: "demo-employee",
          description: "Synthetic caller requested a password.",
          incidentType: "support_call",
          language: "english",
          appName: "",
          evidenceNotes: "",
          observations: [],
          confirmed: true,
        },
        createdAt: at,
        updatedAt: at,
        version: 1,
        status: "submitted",
        assignment: null,
        triage: { status: "pending", attempts: 0 },
      };
      const entry = { report, owner: "employee-fixture" };
      const event = {
        actor: entry.owner,
        action: "created",
        at,
        data: report.facts,
      };
      const key = "synthetic-retry-key";
      assert.equal((await a.create(entry, key, event)).created, true);
      const replay = await b.create(
        { ...entry, report: { ...report, id: "ANV-other" } },
        key,
        event,
      );
      assert.equal(replay.created, false);
      assert.equal(replay.entry.report.id, report.id);
      const claims = await Promise.all([a.claim(at), b.claim(at)]);
      assert.equal(claims.filter(Boolean).length, 1);
      const lease = claims.find(Boolean)!.lease!;
      await a.update(
        report.id,
        ({ report }) => {
          report.triage = {
            status: "pending",
            attempts: 1,
            nextAttemptAt: "2026-11-26T12:01:00.000Z",
          };
          return {
            actor: "local-agents",
            action: "triage_pending",
            at,
            data: { attempts: 1 },
          };
        },
        lease,
      );
      assert.equal(await b.claim(at), undefined);
      const retry = await b.claim("2026-11-26T12:01:00.000Z");
      assert.equal(retry?.report.id, report.id);
      const review = {
        proposalId: "synthetic-proposal",
        severity: "low",
        team: "it_support",
        decision: "amended",
        at,
      } as const;
      await b.update(
        report.id,
        ({ report }) => {
          report.triage = { status: "completed", attempts: 2, review };
          return {
            actor: "admin-fixture",
            action: "triage-review",
            at,
            data: review,
          };
        },
        retry!.lease,
      );
      assert.deepEqual((await a.get(report.id)).report.triage?.review, review);
      assert.deepEqual(
        (await a.events(report.id)).map((event) => event.action),
        ["created", "triage_pending", "triage-review"],
      );
    } finally {
      await Promise.all(
        [first, second].map(async (app) => {
          await getFirestore(app).terminate();
          await deleteApp(app);
        }),
      );
    }
  },
);
