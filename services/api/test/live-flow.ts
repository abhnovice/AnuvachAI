import { spawn } from "node:child_process";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { buildApp } from "../src/app.js";
const root = resolve(import.meta.dirname, "../../..");
const app = await buildApp(
  join(mkdtempSync(join(tmpdir(), "anuvach-live-")), "live.sqlite"),
);
await app.listen({ host: "127.0.0.1", port: 3101 });
const env = {
  ...process.env,
  LIVE_E2E: "1",
  LIVE_API_URL: "http://127.0.0.1:3101",
};
function run(command: string, args: string[], cwd: string) {
  return new Promise<void>((resolve, reject) => {
    const child = spawn(command, args, { cwd, env, stdio: "inherit" });
    child.on("error", reject);
    child.on("exit", (code) =>
      code === 0 ? resolve() : reject(new Error(command + " exited " + code)),
    );
  });
}
try {
  const results = await Promise.allSettled([
    run(
      resolve(root, ".tooling/flutter/bin/flutter"),
      ["test", "--dart-define=LIVE_E2E=true", "test/live_flow_test.dart"],
      resolve(root, "apps/mobile"),
    ),
    run(
      "npm",
      ["exec", "--", "vitest", "run", "src/live.test.tsx"],
      resolve(root, "apps/admin"),
    ),
  ]);
  for (const result of results)
    if (result.status === "rejected") throw result.reason;
  console.log(
    "PASS: Flutter draft/review/confirm -> SQLite -> React displays and updates -> Flutter refresh",
  );
} finally {
  await app.close();
}
