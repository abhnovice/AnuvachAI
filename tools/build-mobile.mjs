import { spawn } from "node:child_process";
import { existsSync, statSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

if (process.argv.length > 2)
  throw new Error("Configure the API with API_BASE_URL.");
const api = process.env.API_BASE_URL ?? "http://10.0.2.2:3000";
const url = new URL(api);
if (
  !["http:", "https:"].includes(url.protocol) ||
  url.username ||
  url.password
) {
  throw new Error(
    "API_BASE_URL must be an HTTP(S) URL without embedded credentials.",
  );
}
const localFlutter = resolve(root, ".tooling/flutter/bin/flutter");
const flutter =
  process.env.FLUTTER_BIN ??
  (existsSync(localFlutter) ? localFlutter : "flutter");
const firebaseConfig = resolve(
  root,
  process.env.FIREBASE_CONFIG_FILE ?? "apps/mobile/.env.firebase.json",
);
if (!existsSync(firebaseConfig)) {
  throw new Error("Missing Firebase configuration. See README Firebase setup.");
}
const args = [
  "build",
  "apk",
  "--release",
  "--dart-define-from-file=" + firebaseConfig,
  "--split-per-abi",
  "--dart-define=API_BASE_URL=" + api,
];
const child = spawn(flutter, args, {
  cwd: resolve(root, "apps/mobile"),
  stdio: "inherit",
  env: {
    ...process.env,
    ORG_GRADLE_PROJECT_allowLocalDemoHttp: String(url.protocol === "http:"),
  },
});
child.once("error", (error) => {
  console.error(error.message);
  process.exitCode = 1;
});
child.once("exit", (code) => {
  if (code !== 0) {
    process.exitCode = code ?? 1;
    return;
  }
  const outputs = [
    "app-armeabi-v7a-release.apk",
    "app-arm64-v8a-release.apk",
    "app-x86_64-release.apk",
  ];
  for (const name of outputs) {
    const path = resolve(
      root,
      "apps/mobile/build/app/outputs/flutter-apk",
      name,
    );
    const bytes = statSync(path).size;
    console.log(name + ": " + (bytes / 1_000_000).toFixed(2) + " MB");
    if (bytes > 50_000_000) {
      console.error("Distribution APK exceeds the 50 MB budget: " + name);
      process.exitCode = 1;
    }
  }
});
