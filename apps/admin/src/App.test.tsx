import { afterEach, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { App } from "./App";
import { buildDashboard } from "../../../services/api/src/analytics";
import type { Report } from "../../../services/api/src/contracts";
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});
it("loads a ticket, persists a status change and confirms escalation separately", async () => {
  let report: Report & { audit: [] } = {
    id: "ANV-demo",
    status: "submitted",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    version: 1,
    assignment: null,
    facts: {
      employeeId: "demo-employee",
      confirmed: true,
      description: "Synthetic support call",
      incidentType: "support_call",
      language: "english",
      appName: "",
      evidenceNotes: "",
      observations: [],
    },
    audit: [],
  };
  const changes: string[] = [];
  vi.stubGlobal(
    "fetch",
    vi.fn(async (path: string, options: RequestInit) => {
      if (options.method !== "GET") {
        const body = JSON.parse(options.body as string);
        changes.push(path);
        report = {
          ...report,
          status: body.status ?? "escalated",
          version: report.version + 1,
        };
      }
      return {
        ok: true,
        json: async () =>
          path.includes("/dashboard")
            ? buildDashboard([report], [], new Date())
            : path.includes("?view=admin") || options.method !== "GET"
              ? report
              : [report],
      };
    }),
  );
  const user = userEvent.setup();
  render(<App />);
  await user.click(await screen.findByRole("button", { name: "ANV-demo" }));
  expect(
    screen.queryByRole("img", { name: "Weekly incoming report counts" }),
  ).toBeNull();
  expect(screen.getByRole("region", { name: "Report detail" })).toBeTruthy();
  await user.selectOptions(
    await screen.findByLabelText("New status"),
    "in_review",
  );
  await user.click(screen.getByRole("button", { name: "Save status" }));
  await waitFor(() =>
    expect(changes).toContain("/api/v1/reports/ANV-demo/status"),
  );
  await user.type(
    screen.getByLabelText("Decision reason"),
    "Synthetic review needed",
  );
  await user.click(
    screen.getByRole("button", { name: "Review escalation decision" }),
  );
  expect(changes.length).toBe(1);
  await user.click(screen.getByRole("button", { name: "Cancel" }));
  expect(changes.length).toBe(1);
  await user.click(
    screen.getByRole("button", { name: "Review escalation decision" }),
  );
  await user.click(screen.getByRole("button", { name: "Confirm decision" }));
  await waitFor(() => expect(changes.length).toBe(2));
});
