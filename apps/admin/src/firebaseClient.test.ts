import { afterEach, expect, it, vi } from "vitest";

const { initialize } = vi.hoisted(() => ({ initialize: vi.fn() }));
vi.mock("firebase/app", () => ({
  getApps: () => [],
  getApp: vi.fn(),
  initializeApp: initialize,
}));
afterEach(() => {
  vi.resetModules();
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  initialize.mockReset();
});

it("loads the hosted configuration once when a production build omits Firebase settings", async () => {
  vi.stubEnv("PROD", true);
  vi.stubEnv("VITE_FIREBASE_API_KEY", "");
  vi.stubEnv("VITE_FIREBASE_PROJECT_ID", "");
  vi.stubEnv("VITE_FIREBASE_APP_ID", "");
  const config = { apiKey: "web-client-key", projectId: "demo", appId: "test" };
  const fetchConfig = vi
    .fn()
    .mockResolvedValue({ ok: true, json: async () => config });
  vi.stubGlobal("fetch", fetchConfig);
  initialize.mockReturnValue({ name: "test" });
  const { firebaseClient } = await import("./firebaseClient");
  const [auth, remoteConfig] = await Promise.all([
    firebaseClient(),
    firebaseClient(),
  ]);
  expect(auth).toBe(remoteConfig);
  expect(fetchConfig).toHaveBeenCalledTimes(1);
  expect(fetchConfig).toHaveBeenCalledWith(
    "/__/firebase/init.json",
    expect.anything(),
  );
  expect(initialize).toHaveBeenCalledWith(config);
});
