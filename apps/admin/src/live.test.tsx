import { it, expect, vi } from "vitest";
import { render, screen, waitFor, cleanup } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { App, type Report } from "./App";

it.skipIf(!process.env.LIVE_E2E)(
  "real dashboard displays Flutter ticket and persists a status change",
  async () => {
    const nativeFetch = globalThis.fetch;
    const base = process.env.LIVE_API_URL ?? "http://127.0.0.1:3101";
    let report: Report | undefined;
    for (let i = 0; i < 90; i++) {
      const reports: Report[] = await (
        await nativeFetch(base + "/api/v1/reports")
      ).json();
      report = reports.find((r) => r.facts.description.startsWith("LIVE-E2E"));
      if (report) break;
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
    expect(report).toBeDefined();
    vi.stubGlobal("fetch", (path: string, options: RequestInit) =>
      nativeFetch(base + path, options),
    );
    try {
      const user = userEvent.setup();
      render(<App />);
      await user.click(await screen.findByRole("button", { name: report!.id }));
      await user.selectOptions(
        await screen.findByLabelText("New status"),
        "in_review",
      );
      await user.click(screen.getByRole("button", { name: "Save status" }));
      await waitFor(() =>
        expect(screen.getByRole("status").textContent).toContain("saved"),
      );
      const saved = await (
        await nativeFetch(
          base + "/api/v1/reports/" + report!.id + "?view=admin",
        )
      ).json();
      expect(saved.status).toBe("in_review");
      expect(saved.audit.at(-1).action).toBe("status");
    } finally {
      cleanup();
      vi.unstubAllGlobals();
    }
  },
  100000,
);
