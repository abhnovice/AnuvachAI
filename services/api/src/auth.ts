import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import type { FastifyInstance, FastifyRequest } from "fastify";

export type Identity = { uid: string; role: "employee" | "admin" };
export type Access = (
  token: string,
) => Promise<{ uid: string; role: Identity["role"] | "both" } | null>;

export function firebaseApp() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) throw new Error("FIREBASE_PROJECT_ID is required");
  return (
    getApps()[0] ??
    initializeApp({ credential: applicationDefault(), projectId })
  );
}

export function firebaseAccess(): Access {
  const employee = process.env.FIREBASE_EMPLOYEE_UID?.trim();
  const admin = process.env.FIREBASE_ADMIN_UID?.trim();
  if (!employee || !admin || employee === admin)
    throw new Error("Configure two distinct Firebase UIDs for the trial");
  const auth = getAuth(firebaseApp());
  return async (token) => {
    const { uid } = await auth.verifyIdToken(token, true);
    if (uid === employee || uid === admin) return { uid, role: "both" };
    return null;
  };
}

declare module "fastify" {
  interface FastifyRequest {
    identity: Identity | null;
  }
}

export function registerAccess(app: FastifyInstance, access?: Access) {
  app.decorateRequest("identity", null);
  if (!access) return;
  app.addHook("onRequest", async (request, reply) => {
    const route = request.routeOptions.url;
    if (!route?.startsWith("/api/v1/")) return;
    reply.header("Cache-Control", "private, no-store");
    const token = /^Bearer ([^\s]+)$/i.exec(
      request.headers.authorization ?? "",
    )?.[1];
    if (!token) return reply.code(401).send({ error: "Sign in to continue" });
    let grant: Awaited<ReturnType<Access>>;
    try {
      grant = await access(token);
    } catch {
      return reply.code(401).send({ error: "Invalid or expired sign-in" });
    }
    const query = request.query as { view?: string; employeeId?: string };
    const viewing = request.method === "GET" || request.method === "HEAD";
    const adminAction =
      route === "/api/v1/dashboard" ||
      route.startsWith("/api/v1/admin/") ||
      (route === "/api/v1/reports" &&
        viewing &&
        query.employeeId === undefined) ||
      (route === "/api/v1/reports/:id" && query.view === "admin") ||
      route.startsWith("/api/v1/reports/:id/");
    const required = adminAction ? "admin" : "employee";
    if (grant?.role !== required && grant?.role !== "both")
      return reply
        .code(403)
        .send({ error: "This account cannot perform this action" });
    request.identity = { uid: grant.uid, role: required };
  });
}

export function employeeUid(request: FastifyRequest) {
  return request.identity?.role === "employee"
    ? request.identity.uid
    : undefined;
}
