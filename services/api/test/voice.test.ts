import assert from "node:assert/strict";
import { once } from "node:events";
import { test } from "node:test";
import Fastify from "fastify";
import websocket from "@fastify/websocket";
import { buildApp } from "../src/app.js";

test(
  "voice upgrade enforces employee auth and streams PCM with the selected language",
  { timeout: 8000 },
  async () => {
    const peer = Fastify();
    await peer.register(websocket);
    const languages: string[] = [];
    const input: unknown[] = [];
    const draft = {
      description: "Someone asked for my ExampleApp pairing code.",
      app_name: "ExampleApp",
      evidence_notes: "",
      incident_type: "support_call",
      unknowns: ["Caller identity"],
    };
    peer.get("/api/live", { websocket: true }, (socket, req) => {
      const query = req.query as {
        language: string;
        preview: string;
        ticket_draft?: string;
      };
      assert.equal(query.preview, "1");
      languages.push(query.language);
      socket.send(
        JSON.stringify({
          type: "state",
          state: "Microphone stream open",
          voice_cues: true,
        }),
      );
      socket.on("message", (data) => {
        const message = JSON.parse(data.toString());
        input.push(message);
        if (message.type === "greet") return;
        if (message.type === "finish" && query.ticket_draft === "1") {
          socket.send(
            JSON.stringify({
              type: "ticket_draft",
              draft: { ...draft, private: true },
            }),
          );
          return;
        }
        socket.send(
          JSON.stringify({
            type: "state",
            state: "interrupted",
            report_id: "private",
          }),
        );
      });
    });
    const base = await peer.listen({ host: "127.0.0.1", port: 0 });
    const app = await buildApp(":memory:", () => new Date(), base, {
      access: async (token) =>
        token === "employee" || token === "admin"
          ? { uid: token, role: token }
          : null,
    });
    const url = "/api/v1/reporting/voice/stream?language=ur";
    await app.ready();
    try {
      await assert.rejects(app.injectWS(url), /401/);
      await assert.rejects(
        app.injectWS(url, {
          headers: { authorization: "Bearer admin" },
        }),
        /403/,
      );
      for (let i = 0; i < 2; i++) {
        const socket = await app.injectWS(
          i === 1 ? url + "&ticketDraft=1" : url,
          {
            headers: { authorization: "Bearer employee" },
          },
        );
        const [ready] = await once(socket, "message");
        assert.deepEqual(JSON.parse(ready.toString()), {
          type: "state",
          state: "ready",
          voice_cues: true,
        });
        socket.send("greet");
        const interrupted = once(socket, "message");
        socket.send(Buffer.from([1, 0, 255, 255]));
        const [event] = await interrupted;
        assert.deepEqual(JSON.parse(event.toString()), {
          type: "state",
          state: "interrupted",
        });
        const ended = once(socket, "message");
        socket.send("end");
        const [endEvent] = await ended;
        assert.deepEqual(
          JSON.parse(endEvent.toString()),
          i === 1
            ? { type: "ticket_draft", draft }
            : { type: "state", state: "interrupted" },
        );
        const closed = once(socket, "close");
        socket.close();
        await closed;
      }
      assert.deepEqual(languages, ["ur", "ur"]);
      assert.deepEqual(input, [
        { type: "greet" },
        { type: "audio", data: "AQD//w==" },
        { type: "finish" },
        { type: "greet" },
        { type: "audio", data: "AQD//w==" },
        { type: "finish" },
      ]);
    } finally {
      await app.close();
      await peer.close();
    }
  },
);
