import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { buildApp } from "../src/app.js";
const payload = {
  employeeId: "demo-employee",
  description: "A synthetic suspicious support call",
  language: "english",
  incidentType: "support_call",
  confirmed: true,
};
test("validation, confirmation, retry safety, admin updates, audit and durable storage", async () => {
  const path = join(mkdtempSync(join(tmpdir(), "anuvach-")), "test.sqlite");
  let app = await buildApp(path);
  const create = (body: Record<string, unknown>) =>
    app.inject({
      method: "POST",
      url: "/api/v1/reports",
      headers: { "idempotency-key": "test-key-123" },
      payload: body,
    });
  assert.equal(
    (await create({ ...payload, confirmed: false })).statusCode,
    400,
  );
  assert.equal(
    (await create({ ...payload, description: "x" })).statusCode,
    400,
  );
  const first = await create(payload);
  assert.equal(first.statusCode, 201);
  const report = first.json();
  assert.equal((await create(payload)).json().id, report.id);
  assert.equal(
    (await create({ ...payload, description: "Different synthetic incident" }))
      .statusCode,
    409,
  );
  const base = "/api/v1/reports/" + report.id;
  assert.equal(
    (
      await app.inject({
        method: "PATCH",
        url: base + "/status",
        payload: { expectedVersion: 1, status: "escalated" },
      })
    ).statusCode,
    400,
  );
  let response = await app.inject({
    method: "PATCH",
    url: base + "/status",
    payload: { expectedVersion: 1, status: "in_review" },
  });
  assert.equal(response.json().status, "in_review");
  assert.equal(
    (
      await app.inject({
        method: "PATCH",
        url: base + "/status",
        payload: { expectedVersion: 1, status: "closed" },
      })
    ).statusCode,
    409,
  );
  response = await app.inject({
    method: "PATCH",
    url: base + "/assignment",
    payload: {
      expectedVersion: 2,
      team: "data_protection",
      reviewer: "Demo reviewer",
    },
  });
  assert.equal(response.json().assignment.team, "data_protection");
  await app.inject({
    method: "POST",
    url: base + "/notes",
    payload: { expectedVersion: 3, text: "Synthetic admin note" },
  });
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: base + "/escalations",
        payload: {
          expectedVersion: 4,
          confirmed: false,
          decision: "escalate",
          reason: "Review needed",
        },
      })
    ).statusCode,
    400,
  );
  await app.inject({
    method: "POST",
    url: base + "/escalations",
    payload: {
      expectedVersion: 4,
      confirmed: true,
      decision: "escalate",
      reason: "Review needed",
    },
  });
  await app.close();
  app = await buildApp(path);
  const detail = (await app.inject(base + "?view=admin")).json();
  assert.equal(detail.status, "escalated");
  assert.equal(detail.audit.length, 5);
  assert.deepEqual(
    detail.audit.map((e: { action: string }) => e.action),
    ["created", "status", "assignment", "notes", "escalations"],
  );
  assert.equal((await app.inject(base)).json().audit, undefined);
  assert.equal(
    (await app.inject("/api/v1/reports?status=escalated")).json().length,
    1,
  );
  assert.equal(
    (await app.inject("/api/v1/reports?status=bogus")).statusCode,
    400,
  );
  await app.close();
});
