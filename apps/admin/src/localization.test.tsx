import { afterEach, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import {
  LocalizationProvider,
  LanguagePicker,
  useLocalization,
} from "./localization";
import { App } from "./App";

const remote = vi.hoisted(() => ({
  supported: false,
  values: {} as Record<string, string>,
}));
vi.mock("firebase/app", () => ({
  initializeApp: () => ({}),
  getApps: () => [],
  getApp: () => ({}),
}));
vi.mock("firebase/remote-config", () => ({
  isSupported: async () => remote.supported,
  getRemoteConfig: () => ({ settings: {} }),
  fetchAndActivate: async () => true,
  getString: (_: unknown, key: string) => remote.values[key] ?? "",
}));
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  document.documentElement.dir = "ltr";
  remote.supported = false;
  remote.values = {};
});
function storage(initial: Record<string, string> = {}) {
  const values = new Map(Object.entries(initial));
  return {
    getItem: (key: string) => values.get(key) ?? null,
    setItem: (key: string, value: string) => values.set(key, value),
  };
}
function Label() {
  const { t } = useLocalization();
  return <p>{t("dashboard")}</p>;
}
it("uses cached overrides, switches languages, and mirrors Urdu", async () => {
  vi.stubGlobal(
    "localStorage",
    storage({
      "anuvach-admin-language": "hi",
      "anuvach-admin-arb-hi": JSON.stringify({
        admin_dashboard: "कस्टम डैशबोर्ड",
        "@admin_dashboard": {},
      }),
    }),
  );
  render(
    <LocalizationProvider>
      <LanguagePicker />
      <Label />
    </LocalizationProvider>,
  );
  expect(screen.getByText("कस्टम डैशबोर्ड")).toBeTruthy();
  await userEvent.selectOptions(screen.getByRole("combobox"), "ur");
  expect(screen.getByText("ڈیش بورڈ")).toBeTruthy();
  expect(document.documentElement.dir).toBe("rtl");
});
it("activates a remote override and saves it for the next session", async () => {
  const cache = storage();
  vi.stubGlobal("localStorage", cache);
  remote.supported = true;
  remote.values = {
    arb_overrides_en: JSON.stringify({ admin_dashboard: "Live dashboard" }),
  };
  render(
    <LocalizationProvider>
      <Label />
    </LocalizationProvider>,
  );
  expect(screen.getByText("Dashboard")).toBeTruthy();
  await screen.findByText("Live dashboard");
  expect(cache.getItem("anuvach-admin-arb-en")).toContain("Live dashboard");
});
it("applies Tamil remote translations and safely falls back for unknown enum values", async () => {
  vi.stubGlobal("localStorage", storage({ "anuvach-admin-language": "ta" }));
  remote.supported = true;
  remote.values = {
    arb_overrides_ta: JSON.stringify({
      admin_dashboard: "தொலைநிலை பலகை",
      admin_supportCall: "ஆதரவு அழைப்பு",
    }),
  };
  function Category() {
    const { enumLabel } = useLocalization();
    return (
      <>
        <p>{enumLabel("support_call")}</p>
        <p>{enumLabel("unknown_value")}</p>
      </>
    );
  }
  render(
    <LocalizationProvider>
      <Label />
      <Category />
    </LocalizationProvider>,
  );
  await screen.findByText("தொலைநிலை பலகை");
  expect(screen.getByText("ஆதரவு அழைப்பு")).toBeTruthy();
  expect(screen.getByText("unknown_value")).toBeTruthy();
});
it("closed subnavigation requests the closed reports", async () => {
  vi.stubGlobal("localStorage", storage());
  vi.spyOn(window, "scrollTo").mockImplementation(() => {});
  const fetchMock = vi.fn(async (url: string) => ({
    ok: true,
    json: async () => (url.includes("/dashboard") ? null : []),
  }));
  vi.stubGlobal("fetch", fetchMock);
  render(<App />);
  await userEvent.click(screen.getByRole("button", { name: "Closed" }));
  await waitFor(() =>
    expect(
      fetchMock.mock.calls.some(([url]) => url.includes("status=closed")),
    ).toBe(true),
  );
  expect((screen.getByLabelText("Status") as HTMLSelectElement).value).toBe(
    "closed",
  );
});
