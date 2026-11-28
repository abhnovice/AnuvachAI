import { afterEach, expect, it, vi } from "vitest";
import {
  cleanup,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
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

it("groups dashboard categories, opens notices in All Reports and chats about a selected ticket", async () => {
  history.replaceState(null, "", "#dashboard");
  vi.spyOn(window, "scrollTo").mockImplementation(() => {});
  const createdAt = new Date().toISOString();
  const notifications = [
    { id: "ANV-alert", summary: "Caller asked for an access code", createdAt },
  ];
  const report: Report = {
    id: "ANV-alert",
    status: "submitted",
    createdAt,
    updatedAt: createdAt,
    version: 1,
    assignment: null,
    facts: {
      employeeId: "demo-employee",
      confirmed: true,
      description: notifications[0].summary,
      incidentType: "voice_phishing",
      language: "english",
      appName: "",
      evidenceNotes: "",
      observations: [],
    },
  };
  const requests: unknown[] = [];
  const fetch = vi.fn(async (path: string, options: RequestInit) => {
    const json = path.includes("/notifications")
      ? notifications
      : path.includes("/assistant")
        ? (requests.push(JSON.parse(options.body as string)),
          { reply: "Open All reports to review the caller’s statement." })
        : path.includes("/dashboard")
          ? buildDashboard([report], [], new Date())
          : path.includes("?view=admin")
            ? report
            : [
                {
                  ...report,
                  queueSeverity: { severity: "moderate", source: "suggested" },
                },
              ];
    return { ok: true, json: async () => json };
  });
  vi.stubGlobal("fetch", fetch);
  const user = userEvent.setup();
  render(<App />);
  const categories = await screen.findByRole("img", {
    name: "Incident category distribution across 1 reports",
  });
  const mix = categories.closest("section")!;
  const labels = within(mix).getAllByRole("button");
  expect(labels.at(-1)?.textContent).toContain("Other");
  await user.click(within(mix).getByRole("button", { name: /Vishing/ }));
  await waitFor(() =>
    expect(
      fetch.mock.calls.some(([url]) => url.includes("incidentGroup=vishing")),
    ).toBe(true),
  );

  await user.click(
    await screen.findByRole("button", { name: /Incident notifications/ }),
  );
  await user.click(
    screen.getByRole("button", {
      name: /Caller asked for an access code.*ANV-alert/,
    }),
  );
  const detail = await screen.findByRole("region", { name: "Report detail" });
  expect(await within(detail).findByText("ANV-alert")).toBeTruthy();
  expect(screen.getAllByRole("columnheader")[0].textContent).toBe(
    "Issue description",
  );
  expect(screen.getByRole("columnheader", { name: "Severity" })).toBeTruthy();
  expect(screen.getByText("Moderate")).toBeTruthy();
  expect(
    screen.queryByRole("region", { name: "Website assistant" }),
  ).toBeNull();

  await user.click(screen.getByRole("button", { name: "Website assistant" }));
  const chat = screen.getByRole("region", { name: "Website assistant" });
  await user.type(within(chat).getByRole("textbox"), "Summarize this ticket");
  await user.click(within(chat).getByRole("button", { name: "Send question" }));
  expect(
    await within(chat).findByText(
      "Open All reports to review the caller’s statement.",
    ),
  ).toBeTruthy();
  expect(requests[0]).toMatchObject({ ticketId: "ANV-alert", view: "reports" });
  history.replaceState(null, "", "#reports");
});
