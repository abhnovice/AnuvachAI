import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { buildApp } from "../src/app.js";
import { seedDemo } from "../src/demo-data.js";

test("dashboard uses actual close transitions, excludes reopened durations, scopes dates and handles empty selections", async () => {
  let clock = new Date("2026-10-01T10:00:00Z");
  const app = await buildApp(":memory:", () => clock);
  const create = async (key: string, type = "support_call") => {
    const r = await app.inject({
      method: "POST",
      url: "/api/v1/reports",
      headers: { "idempotency-key": key },
      payload: {
        employeeId: "demo-employee",
        description: "Synthetic analytics scenario for lifecycle tests",
        language: "english",
        incidentType: type,
        confirmed: true,
      },
    });
    assert.equal(r.statusCode, 201);
    return r.json();
  };
  const old = await create("analytics-old");
  clock = new Date("2026-11-02T10:00:00Z");
  const a = await create("analytics-one");
  const b = await create("analytics-two", "suspicious_message");
  const change = async (
    r: { id: string; version: number },
    kind: string,
    data: Record<string, unknown>,
  ) => {
    const response = await app.inject({
      method: "PATCH",
      url: "/api/v1/reports/" + r.id + "/" + kind,
      payload: { expectedVersion: r.version, ...data },
    });
    assert.equal(response.statusCode, 200);
    Object.assign(r, response.json());
  };
  clock = new Date("2026-11-02T14:00:00Z");
  await change(a, "status", { status: "closed" });
  clock = new Date("2026-11-02T15:00:00Z");
  await change(a, "status", { status: "closed" }); // No-op closure must not add a transition.
  await change(b, "status", { status: "closed" });
  clock = new Date("2026-11-03T10:00:00Z");
  await change(b, "status", { status: "in_review" });
  clock = new Date("2026-11-04T10:00:00Z");
  await change(old, "status", { status: "closed" });
  clock = new Date("2026-11-05T10:00:00Z");
  await change(a, "assignment", {
    team: "data_protection",
    reviewer: "Demo reviewer",
  });
  clock = new Date("2026-11-25T12:00:00Z");
  const response = await app.inject("/api/v1/dashboard?days=30");
  assert.equal(response.statusCode, 200);
  const d = response.json();
  assert.equal(d.metrics.received, 2);
  assert.equal(d.metrics.open, 1);
  assert.equal(d.metrics.closed, 1);
  assert.equal(d.metrics.closedSharePercent, 50);
  assert.equal(d.metrics.meanCloseHours, 4);
  assert.equal(d.metrics.closeSampleSize, 1);
  assert.equal(
    d.turnaround.reduce((n: number, r: { count: number }) => n + r.count, 0),
    1,
  );
  assert.equal(
    d.monthly.reduce((n: number, r: { closed: number }) => n + r.closed, 0),
    3,
  );
  assert.equal(d.weekly.at(-1).open, 1);
  assert.equal(d.weekly.at(-1).closed, 2);
  assert.equal(
    d.incidentMix.reduce((n: number, r: { count: number }) => n + r.count, 0),
    2,
  );
  assert.equal(
    d.statusMatrix
      .flatMap((r: { counts: Record<string, number> }) =>
        Object.values(r.counts),
      )
      .reduce((a: number, b: number) => a + b, 0),
    2,
  );
  const filtered = (
    await app.inject(
      "/api/v1/dashboard?days=30&incidentType=suspicious_message",
    )
  ).json();
  assert.equal(filtered.metrics.received, 1);
  assert.equal(filtered.metrics.meanCloseHours, null);
  const empty = (
    await app.inject("/api/v1/dashboard?days=30&incidentType=mistaken_report")
  ).json();
  assert.equal(empty.metrics.received, 0);
  assert.equal(empty.metrics.closedSharePercent, null);
  assert.equal(empty.metrics.meanFirstActionHours, null);
  assert.equal((await app.inject("/api/v1/reports?days=30")).json().length, 2);
  assert.equal((await app.inject("/api/v1/dashboard?days=7")).statusCode, 400);
  assert.equal(
    (await app.inject("/api/v1/dashboard?incidentType=unknown")).statusCode,
    400,
  );
  assert.equal(
    (await app.inject("/api/v1/reports?days=invalid")).statusCode,
    400,
  );
  await app.close();
});

test("48 historical fixtures reconcile and re-seeding preserves administrator edits", async () => {
  const path = join(
    mkdtempSync(join(tmpdir(), "anuvach-fixtures-")),
    "demo.sqlite",
  );
  const anchor = new Date("2026-11-25T12:00:00Z");
  assert.equal((await seedDemo(path, anchor)).added, 48);
  let app = await buildApp(path, () => anchor);
  const cases = (await app.inject("/api/v1/reports")).json();
  assert.equal(cases.length, 48);
  assert.equal(new Set(cases.map((r: { status: string }) => r.status)).size, 5);
  assert.equal(
    new Set(
      cases.map(
        (r: { facts: { incidentType: string } }) => r.facts.incidentType,
      ),
    ).size,
    4,
  );
  const d = (await app.inject("/api/v1/dashboard?days=180")).json();
  assert.equal(d.metrics.received, 48);
  assert.equal(
    Object.values(d.statusCounts).reduce((a: any, b: any) => a + b, 0),
    48,
  );
  assert.equal(
    d.incidentMix.reduce((n: number, r: { count: number }) => n + r.count, 0),
    48,
  );
  assert.equal(d.metrics.closeSampleSize, d.metrics.closed);
  const selected = cases[0];
  const changed = (
    await app.inject({
      method: "PATCH",
      url: "/api/v1/reports/" + selected.id + "/assignment",
      payload: {
        expectedVersion: selected.version,
        team: "security",
        reviewer: "Preserve this demo edit",
      },
    })
  ).json();
  await app.close();
  assert.equal(
    (await seedDemo(path, new Date("2026-12-25T12:00:00Z"))).added,
    0,
  );
  app = await buildApp(path, () => anchor);
  const after = (
    await app.inject("/api/v1/reports/" + selected.id + "?view=admin")
  ).json();
  assert.equal(after.assignment.reviewer, "Preserve this demo edit");
  assert.equal(after.version, changed.version);
  assert.equal((await app.inject("/api/v1/reports")).json().length, 48);
  assert.equal(after.audit.length, changed.audit.length);
  await app.close();
});
