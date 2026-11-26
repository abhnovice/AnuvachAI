import type { FastifyInstance } from "fastify";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import { agentLanguage } from "./agents.js";

export function registerVoice(app: FastifyInstance, agentBase?: string) {
  const sessions = new Map<
    string,
    { socket: WebSocket; events: unknown[]; touched: number }
  >();
  const expiry = setInterval(() => {
    for (const [id, session] of sessions) {
      if (Date.now() - session.touched > 15_000) {
        session.socket.close();
        sessions.delete(id);
      }
    }
  }, 5000);
  expiry.unref();
  app.addHook("onClose", async () => {
    clearInterval(expiry);
    for (const session of sessions.values()) session.socket.close();
    sessions.clear();
  });

  app.post("/api/v1/reporting/voice", async (request, reply) => {
    const { language } = z
      .object({ language: agentLanguage })
      .strict()
      .parse(request.body);
    if (!agentBase || sessions.size >= 8)
      return reply
        .code(503)
        .send({ error: "Voice unavailable. Continue with text." });
    const id = randomUUID();
    const url = new URL("/api/live", agentBase);
    url.protocol = "ws:";
    url.search = new URLSearchParams({
      language,
      session_id: id,
      preview: "1",
    }).toString();
    const socket = new WebSocket(url);
    const session = { socket, events: [] as unknown[], touched: Date.now() };
    let failed = false;
    const disconnect = () => {
      if (failed) return;
      failed = true;
      session.events = [
        {
          type: "error",
          message: "Voice disconnected. Start again or continue with text.",
        },
      ];
    };
    socket.addEventListener("close", disconnect);
    socket.addEventListener("error", disconnect);
    socket.addEventListener("message", ({ data }) => {
      if (failed || typeof data !== "string") return;
      if (data.length > 256_000 || session.events.length >= 100) {
        disconnect();
        socket.close();
        return;
      }
      try {
        const event = JSON.parse(data);
        // Preview sessions never forward standalone draft or report identifiers.
        const {
          type,
          state,
          role,
          text,
          partial,
          mime_type,
          data: audio,
          message,
        } = event;
        if (state === "interrupted") {
          session.events = session.events.filter(
            (item) => (item as { type: string }).type !== "audio",
          );
        }
        session.events.push({
          type,
          state,
          role,
          text,
          partial,
          mime_type,
          data: audio,
          message,
        });
      } catch {
        disconnect();
        socket.close();
      }
    });
    sessions.set(id, session);
    const ready = await new Promise<boolean>((resolve) => {
      const timeout = setTimeout(() => resolve(false), 3000);
      const done = (opened: boolean) => {
        clearTimeout(timeout);
        resolve(opened);
      };
      socket.addEventListener("open", () => done(true), { once: true });
      socket.addEventListener("error", () => done(false), { once: true });
      socket.addEventListener("close", () => done(false), { once: true });
    });
    if (!ready) {
      socket.close();
      sessions.delete(id);
      return reply
        .code(503)
        .send({ error: "Voice unavailable. Continue with text." });
    }
    return { id };
  });

  app.post<{ Params: { id: string } }>(
    "/api/v1/reporting/voice/:id",
    async (request, reply) => {
      const body = z
        .object({
          frames: z.array(z.base64().max(4600)).max(8).default([]),
          end: z.boolean().default(false),
        })
        .strict()
        .parse(request.body);
      const session = sessions.get(request.params.id);
      if (!session)
        return reply.code(404).send({
          error: "Voice session ended. Start again or continue with text.",
        });
      session.touched = Date.now();
      if (session.socket.readyState === WebSocket.OPEN) {
        for (const data of body.frames)
          session.socket.send(JSON.stringify({ type: "audio", data }));
        if (body.end)
          session.socket.send(JSON.stringify({ type: "audio_end" }));
      }
      return { events: session.events.splice(0) };
    },
  );

  app.delete<{ Params: { id: string } }>(
    "/api/v1/reporting/voice/:id",
    async (request, reply) => {
      sessions.get(request.params.id)?.socket.close();
      sessions.delete(request.params.id);
      return reply.code(204).send();
    },
  );
}
