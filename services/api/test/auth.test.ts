import assert from "node:assert/strict";
import { test } from "node:test";
import { buildApp } from "../src/app.js";
import type { Access } from "../src/auth.js";

const access: Access = async (token) => {
  if (token === "employee")
    return { uid: "employee-fixture", role: "employee" };
  if (token === "admin") return { uid: "admin-fixture", role: "admin" };
  if (token === "first" || token === "second")
    return { uid: token, role: "both" };
  if (token === "unlisted") return null;
  throw new Error("expired");
};

test("API rejects missing, invalid and unlisted credentials and separates roles", async () => {
  const app = await buildApp(":memory:", undefined, undefined, { access });
  try {
    const headers = (token: string) => ({ authorization: "Bearer " + token });
    const check = (url: string, token?: string) =>
      app.inject({ url, headers: token ? headers(token) : {} });
    assert.equal((await check("/health")).statusCode, 200);
    assert.equal((await check("/api/v1/reports")).statusCode, 401);
    assert.equal((await check("/api/v1/reports", "expired")).statusCode, 401);
    assert.equal((await check("/api/v1/reports", "unlisted")).statusCode, 403);
    assert.equal((await check("/api/v1/reports", "employee")).statusCode, 403);
    assert.equal(
      (await check("/api/v1/dashboard", "employee")).statusCode,
      403,
    );
    assert.equal(
      (await check("/api/v1/reports/example?view=admin", "employee"))
        .statusCode,
      403,
    );
    assert.equal(
      (await check("/api/v1/reports?employeeId=demo-employee", "admin"))
        .statusCode,
      403,
    );
    assert.equal(
      (await check("/api/v1/reports?employeeId=demo-employee", "employee"))
        .statusCode,
      200,
    );
    assert.equal(
      (await check("/api/v1/reports", "admin")).headers["cache-control"],
      "private, no-store",
    );
    for (const [method, url, token] of [
      ["PATCH", "/api/v1/reports/example/status", "employee"],
      ["POST", "/api/v1/reports/example/triage-review", "employee"],
      ["POST", "/api/v1/reports", "admin"],
      ["POST", "/api/v1/reporting/turns", "admin"],
      ["POST", "/api/v1/reporting/voice", "admin"],
    ] as const) {
      assert.equal(
        (
          await app.inject({
            method,
            url,
            headers: headers(token),
            payload: {},
          })
        ).statusCode,
        403,
      );
    }
  } finally {
    await app.close();
  }
});

test("both trial users can submit employee reports and perform admin actions", async () => {
  const app = await buildApp(":memory:", undefined, undefined, { access });
  try {
    for (const token of ["first", "second"]) {
      const headers = { authorization: "Bearer " + token };
      const created = await app.inject({
        method: "POST",
        url: "/api/v1/reports",
        headers: { ...headers, "idempotency-key": "dual-role-" + token },
        payload: {
          employeeId: "demo-employee",
          description: "Synthetic trial report for the role check.",
          language: "english",
          incidentType: "support_call",
          confirmed: true,
        },
      });
      assert.equal(created.statusCode, 201);
      const { id, version } = created.json();
      const updated = await app.inject({
        method: "PATCH",
        url: "/api/v1/reports/" + id + "/status",
        headers,
        payload: { expectedVersion: version, status: "in_review" },
      });
      assert.equal(updated.statusCode, 200);
      assert.equal(updated.json().audit.at(-1).actor, token);
    }
  } finally {
    await app.close();
  }
});
