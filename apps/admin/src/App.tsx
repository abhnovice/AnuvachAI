import { useEffect, useRef, useState } from "react";
import { flushSync } from "react-dom";
import { usePageScroll } from "./usePageScroll";
import { AnalyticsOverview, type DashboardData } from "./AnalyticsOverview";
import { Icon } from "./Icon";
import { IncidentNotifications, WebsiteAssistant } from "./WorkspaceTools";
import { incidentGroups } from "../../../services/api/src/incident-groups";
import { TriageReview, type LocalTriage } from "./TriageReview";
import { TicketJourney } from "./TicketJourney";
import { ThemePicker } from "./ThemePicker";
import { MaterialNavIcon } from "./MaterialNavIcon";
import { adminToken } from "./AuthGate";
import {
  incidentCategories,
  LanguagePicker,
  useLocalization,
} from "./localization";
export type Report = {
  id: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  version: number;
  triage?: LocalTriage;
  incidentCategory?: string;
  queueSeverity?: { severity: string; source: "reviewed" | "suggested" | null };
  facts: {
    employeeId: string;
    description: string;
    language: string;
    incidentType: string;
    appName: string;
    evidenceNotes: string;
    observations: {
      check: string;
      value: boolean;
      checkedAt: string;
      source: string;
      platform: string;
    }[];
  };
  assignment: { team: string; reviewer: string } | null;
  audit?: {
    sequence: number;
    actor: string;
    action: string;
    at: string;
    data: Record<string, unknown>;
  }[];
};
const statuses = [
  "submitted",
  "in_review",
  "awaiting_employee",
  "escalated",
  "closed",
];
const label = (s: string) => s.replaceAll("_", " ");
const apiBase = (import.meta.env.VITE_API_BASE_URL ?? "").replace(/\/+$/, "");
const elapsedSince = (createdAt: string) => {
  const minutes = Math.max(
    0,
    Math.floor((Date.now() - Date.parse(createdAt)) / 60000),
  );
  return minutes < 60
    ? minutes + " min"
    : minutes < 1440
      ? (minutes / 60).toFixed(1) + " h"
      : (minutes / 1440).toFixed(1) + " d";
};
export async function request<T>(
  path: string,
  method = "GET",
  body?: unknown,
): Promise<T> {
  const token = await adminToken();
  const response = await fetch(apiBase + "/api/v1" + path, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: "Bearer " + token } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.error ?? "API unavailable. Please retry.");
  }
  return response.json();
}
const loadNotices = () =>
  request<{ id: string; summary: string; createdAt: string }[]>(
    "/admin/notifications",
  );
const severityLabels = {
  low: "severityLow",
  moderate: "severityModerate",
  high: "severityHigh",
  critical: "severityCritical",
} as const;

export function App({ onSignOut }: { onSignOut?: () => void } = {}) {
  const { t, enumLabel, locale } = useLocalization();
  const statusLabel = (value: string) => {
    switch (value) {
      case "submitted":
        return t("submitted");
      case "in_review":
        return t("inReview");
      case "awaiting_employee":
        return t("awaitingEmployee");
      case "escalated":
        return t("escalations");
      case "closed":
        return t("closed");
      case "open":
        return t("allOpen");
      default:
        return label(value);
    }
  };
  const [collapsed, setCollapsed] = useState(false);
  const [reportsExpanded, setReportsExpanded] = useState(true);
  const [page, setPage] = useState(() =>
    location.hash === "#dashboard" ? "dashboard" : "reports",
  );
  useEffect(() => {
    const sync = () => {
      setPage(location.hash === "#dashboard" ? "dashboard" : "reports");
      window.scrollTo({ top: 0, behavior: "instant" });
    };
    window.addEventListener("hashchange", sync);
    return () => window.removeEventListener("hashchange", sync);
  }, []);
  const transitionBusy = useRef(false);
  async function navigate(next: string) {
    if (transitionBusy.current) return;
    const commit = () => {
      flushSync(() => setPage(next));
      if (location.hash !== "#" + next) history.pushState(null, "", "#" + next);
      window.scrollTo({ top: 0, behavior: "instant" });
    };
    if (
      next === page ||
      window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    ) {
      commit();
      return;
    }
    transitionBusy.current = true;
    const root = document.documentElement;
    root.dataset.flow = next === "reports" ? "forward" : "back";
    root.dataset.transitioning = "true";
    try {
      const api = document as Document & {
        startViewTransition?: (update: () => void) => {
          finished: Promise<void>;
        };
      };
      if (api.startViewTransition) {
        await api.startViewTransition(commit).finished;
      } else {
        const surface = document.getElementById("workspace");
        const direction = next === "reports" ? 1 : -1;
        await surface?.animate(
          [
            { opacity: 1, transform: "translateY(0)" },
            { opacity: 0, transform: "translateY(" + -direction * 32 + "px)" },
          ],
          { duration: 180, easing: "ease-in", fill: "none" },
        ).finished;
        commit();
        await surface?.animate(
          [
            { opacity: 0, transform: "translateY(" + direction * 32 + "px)" },
            { opacity: 1, transform: "translateY(0)" },
          ],
          { duration: 420, easing: "cubic-bezier(.16,1,.3,1)" },
        ).finished;
      }
    } catch {
      // View transitions and animations can be cancelled by the browser.
      // Ensure the requested destination still becomes active.
      commit();
    } finally {
      transitionBusy.current = false;
      delete root.dataset.transitioning;
      delete root.dataset.flow;
    }
  }
  usePageScroll(page, navigate);
  const [reports, setReports] = useState<Report[]>([]),
    [detail, setDetail] = useState<Report | null>(null);
  const [status, setStatus] = useState(""),
    [type, setType] = useState(""),
    [error, setError] = useState(""),
    [loading, setLoading] = useState(false);
  const [dashboardRange, setDashboardRange] = useState<{
    start: string;
    end: string;
  } | null>(null);
  const [busy, setBusy] = useState(false),
    [team, setTeam] = useState("security"),
    [reviewer, setReviewer] = useState(""),
    [note, setNote] = useState("");
  const [newStatus, setNewStatus] = useState("in_review"),
    [decision, setDecision] = useState("escalate"),
    [reason, setReason] = useState(""),
    [confirm, setConfirm] = useState(false);
  const [message, setMessage] = useState("");
  const [days, setDays] = useState("90");
  const [overview, setOverview] = useState<DashboardData | null>(null);
  const [overviewLoading, setOverviewLoading] = useState(true);
  const [queuePage, setQueuePage] = useState(0);
  const [noticeTicket, setNoticeTicket] = useState<string | null>(null);
  const requestGeneration = useRef(0);
  const pageSize = 10;
  const scopedReports = dashboardRange
    ? reports.filter((report) => {
        const day = new Date(report.createdAt).toISOString().slice(0, 10);
        return day >= dashboardRange.start && day <= dashboardRange.end;
      })
    : reports;
  const effectivePage = Math.min(
    queuePage,
    Math.max(0, Math.ceil(scopedReports.length / pageSize) - 1),
  );
  const visibleReports = scopedReports.slice(
    effectivePage * pageSize,
    (effectivePage + 1) * pageSize,
  );
  const translationCache = useRef(new Map<string, Promise<string>>());
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const translationIds =
    page === "reports"
      ? [
          ...new Set([
            ...(detail ? [detail.id] : []),
            ...visibleReports.map((report) => report.id),
          ]),
        ].join(",")
      : "";
  useEffect(() => {
    if (!translationIds) return;
    let active = true;
    const ids = translationIds.split(",");
    const query = new URLSearchParams({ view: "admin", translate: locale });
    async function translate() {
      while (active && ids.length) {
        const id = ids.shift()!;
        const key = `${locale}:${id}`;
        const cache = translationCache.current;
        let pending = cache.get(key);
        if (!pending) {
          pending = request<{ translation: string }>(
            `/reports/${encodeURIComponent(id)}?${query}`,
          ).then(({ translation }) =>
            typeof translation === "string" ? translation.trim() : "",
          );
          cache.set(key, pending);
        }
        try {
          const text = await pending;
          if (text && active)
            setTranslations((current) =>
              current[key] === text ? current : { ...current, [key]: text },
            );
        } catch {
          if (cache.get(key) === pending) cache.delete(key);
        }
      }
    }
    const concurrency = Math.min(3, ids.length);
    for (let worker = 0; worker < concurrency; worker++) {
      void translate();
    }
    return () => {
      active = false;
    };
  }, [locale, translationIds]);
  const description = (report: Report) =>
    translations[`${locale}:${report.id}`] || report.facts.description;
  async function load() {
    const generation = ++requestGeneration.current;
    setLoading(true);
    setOverviewLoading(true);
    setOverview(null);
    setError("");
    try {
      const q = new URLSearchParams({ days });
      if (status && status !== "open") q.set("status", status);
      const metricsQuery = new URLSearchParams({ days });
      if (type) {
        const [key, value] = type.startsWith("group:")
          ? ["incidentGroup", type.slice(6)]
          : ["incidentType", type];
        q.set(key, value);
        metricsQuery.set(key, value);
      }
      const [rows, metrics] = await Promise.all([
        request<Report[]>("/reports?" + q),
        request<DashboardData>("/dashboard?" + metricsQuery),
      ]);
      if (generation !== requestGeneration.current) return;
      setReports(
        status === "open"
          ? rows.filter((row) => row.status !== "closed")
          : rows,
      );
      setOverview(metrics);
    } catch (e) {
      if (generation === requestGeneration.current) {
        setError((e as Error).message);
        setReports([]);
      }
    } finally {
      if (generation === requestGeneration.current) {
        setLoading(false);
        setOverviewLoading(false);
      }
    }
  }
  useEffect(() => {
    setDetail(null);
    setQueuePage(0);
    void load();
  }, [status, type, days]);
  const pendingTriageId =
    detail?.triage?.status === "pending" ? detail.id : undefined;
  useEffect(() => {
    if (!pendingTriageId || busy) return;
    let active = true;
    let checking = false;
    const timer = window.setInterval(async () => {
      if (checking) return;
      checking = true;
      try {
        const updated = await request<Report>(
          "/reports/" + pendingTriageId + "?view=admin",
        );
        if (active) {
          setDetail((current) =>
            current?.id === updated.id && current.version < updated.version
              ? updated
              : current,
          );
        }
      } catch {
        // The existing manual refresh remains available during a network failure.
      } finally {
        checking = false;
      }
    }, 3000);
    return () => {
      active = false;
      window.clearInterval(timer);
    };
  }, [pendingTriageId, busy]);

  async function open(id: string) {
    setLoading(true);
    setError("");
    setDetail(null);
    setConfirm(false);
    setReason("");
    setNote("");
    setMessage("");
    try {
      const r = await request<Report>("/reports/" + id + "?view=admin");
      setDetail(r);
      setTeam(r.assignment?.team ?? "security");
      setReviewer(r.assignment?.reviewer ?? "");
      setNewStatus(r.status === "escalated" ? "in_review" : r.status);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    if (!noticeTicket || page !== "reports" || status || type) return;
    setNoticeTicket(null);
    void open(noticeTicket);
  }, [noticeTicket, page, status, type]);
  async function mutate(kind: string, body: Record<string, unknown>) {
    if (!detail) return;
    setBusy(true);
    setError("");
    setMessage("");
    try {
      setDetail(
        await request<Report>(
          "/reports/" + detail.id + "/" + kind,
          ["status", "assignment"].includes(kind) ? "PATCH" : "POST",
          { expectedVersion: detail.version, ...body },
        ),
      );
      setConfirm(false);
      setNote("");
      setReason("");
      setMessage("Change saved and audited.");
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <>
      <aside
        className={"sidebar" + (collapsed ? " collapsed" : "")}
        aria-label="Workspace navigation"
      >
        <a className="brand" href="#reports" aria-label="Anuvach incident desk">
          <img
            className="logo"
            src={"/anuvach-logo.png"}
            alt=""
            width={46}
            height={46}
          />
        </a>
        <button
          className="nav-toggle"
          aria-expanded={!collapsed}
          aria-controls="workspace-navigation"
          onClick={() => setCollapsed(!collapsed)}
          aria-label={collapsed ? "Expand navigation" : "Collapse navigation"}
        >
          {collapsed ? "☰" : "←"}
        </button>
        <p className="nav-label">WORKSPACE</p>
        <nav id="workspace-navigation" aria-label="Report views">
          <button
            className={page === "dashboard" ? "nav-item active" : "nav-item"}
            aria-current={page === "dashboard" ? "page" : undefined}
            aria-label={t("dashboard")}
            title={t("dashboard")}
            onClick={() => navigate("dashboard")}
          >
            <MaterialNavIcon name="dashboard" />
            <span>{t("dashboard")}</span>
          </button>
          <div className="report-nav-row">
            <button
              className={
                page === "reports" && status === ""
                  ? "nav-item active"
                  : "nav-item"
              }
              aria-current={
                page === "reports" && status === "" ? "page" : undefined
              }
              onClick={() => {
                navigate("reports");
                setStatus("");
              }}
            >
              <MaterialNavIcon name="reports" />
              <span>{t("allReports")}</span>
            </button>
            <button
              className="report-group-toggle"
              aria-label={
                reportsExpanded
                  ? "Collapse report views"
                  : "Expand report views"
              }
              aria-expanded={reportsExpanded}
              aria-controls="report-subnav"
              onClick={() => setReportsExpanded(!reportsExpanded)}
            >
              {reportsExpanded ? "⌃" : "⌄"}
            </button>
          </div>
          <div
            id="report-subnav"
            hidden={!reportsExpanded}
            className="report-subnav"
            role="group"
            aria-label="All reports views"
          >
            <button
              className={
                page === "reports" && status === "in_review"
                  ? "nav-item active"
                  : "nav-item"
              }
              aria-current={
                page === "reports" && status === "in_review"
                  ? "page"
                  : undefined
              }
              onClick={() => {
                navigate("reports");
                setStatus("in_review");
              }}
            >
              <MaterialNavIcon name="review" />
              <span>{t("inReview")}</span>
            </button>
            <button
              className={
                page === "reports" && status === "escalated"
                  ? "nav-item active"
                  : "nav-item"
              }
              aria-current={
                page === "reports" && status === "escalated"
                  ? "page"
                  : undefined
              }
              onClick={() => {
                navigate("reports");
                setStatus("escalated");
              }}
            >
              <MaterialNavIcon name="escalations" />
              <span>{t("escalations")}</span>
            </button>
            <button
              className={
                page === "reports" && status === "closed"
                  ? "nav-item active"
                  : "nav-item"
              }
              aria-current={
                page === "reports" && status === "closed" ? "page" : undefined
              }
              onClick={() => {
                navigate("reports");
                setStatus("closed");
              }}
            >
              <MaterialNavIcon name="closed" />
              <span>{t("closed")}</span>
            </button>
          </div>
        </nav>
        <div className="sidebar-preferences">
          <LanguagePicker />
          {onSignOut && (
            <button className="sidebar-sign-out" onClick={onSignOut}>
              {t("signOut")}
            </button>
          )}
        </div>
      </aside>

      <main
        id="workspace"
        className="page-dashboard isolated-workspace"
        data-view={page}
      >
        <div className="intro">
          <div>
            <h1 className="page-heading">{t("workspaceTitle")}</h1>
          </div>
          <div className="workspace-actions">
            <IncidentNotifications
              load={loadNotices}
              openReport={(id) => {
                setStatus("");
                setType("");
                setDashboardRange(null);
                setNoticeTicket(id);
                if (!status && !type) void load();
                void navigate("reports");
              }}
            />
            <ThemePicker />
            {page === "dashboard" && (
              <button
                className="dashboard-reports-link"
                onClick={() => {
                  setStatus("");
                  setDashboardRange(null);
                  navigate("reports");
                }}
              >
                {t("viewReports")} <Icon name="arrow" size={16} />
              </button>
            )}
            <button
              className="refresh-button"
              onClick={() => void load()}
              disabled={loading}
            >
              <Icon name="refresh" size={18} />
              {t("refreshQueue")}
            </button>
          </div>
        </div>
        <div
          id="dashboard"
          className="dashboard-page"
          hidden={page !== "dashboard"}
          inert={page !== "dashboard"}
        >
          <AnalyticsOverview
            data={overview}
            loading={overviewLoading}
            days={days}
            type={type}
            onDays={(value) => {
              setDashboardRange(null);
              setDays(value);
            }}
            onType={(value) => {
              setDashboardRange(null);
              setType(value);
            }}
            onStatus={(next, category) => {
              setDashboardRange(null);
              navigate("reports");
              setStatus(next);
              if (category) setType(category);
            }}
            onPeriod={(start, end) => {
              setDashboardRange({ start, end });
              setQueuePage(0);
              setDetail(null);
              navigate("reports");
            }}
          />
        </div>
        <div
          id="reports"
          className="reports-page"
          hidden={page !== "reports"}
          inert={page !== "reports"}
        >
          {error && (
            <div role="alert" className="error">
              {error}{" "}
              <button
                onClick={() => (detail ? void open(detail.id) : void load())}
              >
                Retry / refresh
              </button>
            </div>
          )}
          {message && <p role="status">{message}</p>}
          <div
            className={
              "workspace analytics-workspace" + (detail ? " has-detail" : "")
            }
          >
            <section className="panel queue" id="report-queue">
              <h2>
                {t("reportQueue")}{" "}
                <span className="count">{scopedReports.length}</span>
              </h2>
              <div className="filters">
                <label>
                  {t("status")}
                  <select
                    aria-label={t("status")}
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                  >
                    <option value="">{t("allStatuses")}</option>
                    <option value="open">{t("allOpen")}</option>
                    {statuses.map((s) => (
                      <option key={s} value={s}>
                        {statusLabel(s)}
                      </option>
                    ))}
                  </select>
                </label>
                <label>
                  {t("incidentType")}
                  <select
                    aria-label={t("incidentType")}
                    value={type}
                    onChange={(e) => {
                      setDashboardRange(null);
                      setType(e.target.value);
                    }}
                  >
                    <option value="">{t("allTypes")}</option>
                    {incidentGroups.map((group) => (
                      <option key={group} value={`group:${group}`}>
                        {enumLabel(`group:${group}`)}
                      </option>
                    ))}
                    {incidentCategories.map((t) => (
                      <option key={t} value={t}>
                        {enumLabel(t)}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              {(status || type || dashboardRange) && (
                <p className="queue-scope-note">
                  Showing {status ? statusLabel(status) : t("allStatuses")} ·{" "}
                  {type ? enumLabel(type) : t("allTypes")}
                  {dashboardRange &&
                    ` · ${dashboardRange.start} to ${dashboardRange.end} UTC`}
                  <button
                    className="queue-reset"
                    onClick={() => {
                      setStatus("");
                      setType("");
                      setDashboardRange(null);
                    }}
                  >
                    {t("clearFilters")}
                  </button>
                </p>
              )}
              {loading && <p role="status">{t("loadingReports")}</p>}
              {!loading && !scopedReports.length && !error && (
                <p>{t("emptyReports")}</p>
              )}
              <div className="table-scroll">
                <table>
                  <thead>
                    <tr>
                      <th>{t("issueDescription")}</th>
                      <th title="Receipt times use your browser’s local time zone">
                        {t("ticketReceived")}
                      </th>
                      <th>{t("type")}</th>
                      <th>{t("status")}</th>
                      <th>{t("queueSeverity")}</th>
                      <th>{t("assignment")}</th>
                      <th>{t("elapsed")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {visibleReports.map((r) => {
                      const severity = r.queueSeverity;
                      const value =
                        severity?.severity as keyof typeof severityLabels;
                      return (
                        <tr
                          key={r.id}
                          className={
                            detail?.id === r.id ? "selected" : undefined
                          }
                        >
                          <td className="queue-description">
                            <span dir="auto">{description(r)}</span>
                          </td>
                          <td>
                            <button
                              className="ticket"
                              aria-label={r.id}
                              title={r.id}
                              onClick={() => void open(r.id)}
                            >
                              <span className="ticket-icon">
                                <Icon name="reports" size={16} />
                              </span>{" "}
                              ANV-…{r.id.slice(-8)}
                            </button>
                            <small>
                              {new Date(r.createdAt).toLocaleString()}
                            </small>
                          </td>
                          <td>
                            {enumLabel(
                              r.incidentCategory ?? r.facts.incidentType,
                            )}
                          </td>
                          <td>
                            <span className={"badge status-" + r.status}>
                              {statusLabel(r.status)}
                            </span>
                          </td>
                          <td>
                            <span
                              className={`badge queue-severity severity-${severity?.severity ?? "unassessed"}`}
                            >
                              {t(severityLabels[value] ?? "severityUnassessed")}
                            </span>
                          </td>
                          <td>
                            {r.assignment?.team
                              ? enumLabel(r.assignment.team)
                              : t("unassigned")}
                            {r.assignment?.reviewer && (
                              <small>{r.assignment.reviewer}</small>
                            )}
                          </td>
                          <td>
                            <span title="Time since receipt, including time after closure">
                              {elapsedSince(r.createdAt)}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
              {scopedReports.length > 0 && (
                <div className="queue-pagination">
                  <span>
                    Showing {effectivePage * pageSize + 1}–
                    {Math.min(
                      (effectivePage + 1) * pageSize,
                      scopedReports.length,
                    )}{" "}
                    of {scopedReports.length}
                  </span>
                  <div>
                    <button
                      aria-label="Previous reports"
                      disabled={effectivePage === 0}
                      onClick={() => setQueuePage(effectivePage - 1)}
                    >
                      ← Previous
                    </button>
                    <button
                      aria-label="Next reports"
                      disabled={
                        (effectivePage + 1) * pageSize >= scopedReports.length
                      }
                      onClick={() => setQueuePage(effectivePage + 1)}
                    >
                      Next →
                    </button>
                  </div>
                </div>
              )}
            </section>
            <section className="panel detail" aria-label={t("reportDetail")}>
              {detail && (
                <>
                  <div className="detail-top">
                    <h2>{t("reportDetail")}</h2>
                    <button
                      onClick={() => void open(detail.id)}
                      disabled={busy}
                    >
                      {t("refreshDetail")}
                    </button>
                  </div>
                  <p className="id">{detail.id}</p>
                  <p>
                    <span className={"badge status-" + detail.status}>
                      {statusLabel(detail.status)}
                    </span>
                  </p>
                  <small>
                    Received {new Date(detail.createdAt).toLocaleString()}
                    <br />
                    Updated {new Date(detail.updatedAt).toLocaleString()}
                  </small>
                  <TicketJourney report={detail} />
                  <h3>
                    <Icon name="message" size={18} />
                    {t("employeeStatements")}
                  </h3>
                  <p className="statement" dir="auto">
                    {description(detail)}
                  </p>
                  <dl>
                    <dt>{t("reportLanguage")}</dt>
                    <dd>{detail.facts.language}</dd>
                    <dt>{t("incidentType")}</dt>
                    <dd>
                      {enumLabel(
                        detail.incidentCategory ?? detail.facts.incidentType,
                      )}
                    </dd>
                    {detail.incidentCategory &&
                      detail.incidentCategory !== detail.facts.incidentType && (
                        <>
                          <dt>{t("reportedIncidentType")}</dt>
                          <dd>{enumLabel(detail.facts.incidentType)}</dd>
                        </>
                      )}
                    <dt>{t("appName")}</dt>
                    <dd>{detail.facts.appName || t("notSupplied")}</dd>
                    <dt>{t("evidenceNotes")}</dt>
                    <dd>{detail.facts.evidenceNotes || t("notSupplied")}</dd>
                  </dl>
                  <h3>
                    <Icon name="shield" size={18} />
                    {t("deviceObservations")}
                  </h3>
                  {!detail.facts.observations.length ? (
                    <p>{t("noChecks")}</p>
                  ) : (
                    detail.facts.observations.map((o, i) => (
                      <p key={i}>
                        {label(o.check)}:{" "}
                        {o.value ? "configured" : "not configured"}
                        <br />
                        <small>
                          {o.platform} · {o.source} · {o.checkedAt}
                        </small>
                      </p>
                    ))
                  )}
                  <p className="muted">
                    Client-reported observations do not establish remote access,
                    compromise, or permission use.
                  </p>
                  <p>
                    {t("policyCitations")} <strong>{t("notAvailable")}</strong>
                    {!detail.triage && (
                      <>
                        <br />
                        {t("severity")} <strong>{t("notAvailable")}</strong>
                      </>
                    )}
                  </p>
                  <fieldset disabled={busy}>
                    <legend>{t("adminActions")}</legend>
                    {detail.triage && (
                      <TriageReview
                        key={`${detail.id}:${detail.version}`}
                        triage={detail.triage}
                        save={(review) => void mutate("triage-review", review)}
                      />
                    )}
                    <form
                      onSubmit={(e) => {
                        e.preventDefault();
                        void mutate("status", { status: newStatus });
                      }}
                    >
                      <label>
                        {t("newStatus")}
                        <select
                          aria-label={t("newStatus")}
                          value={newStatus}
                          onChange={(e) => setNewStatus(e.target.value)}
                        >
                          {statuses
                            .filter((s) => s !== "escalated")
                            .map((s) => (
                              <option key={s} value={s}>
                                {statusLabel(s)}
                              </option>
                            ))}
                        </select>
                      </label>
                      <button>{t("saveStatus")}</button>
                      {["in_review", "awaiting_employee", "escalated"].includes(
                        detail.status,
                      ) && (
                        <button
                          type="button"
                          disabled={busy}
                          onClick={() =>
                            void mutate("status", { status: "closed" })
                          }
                        >
                          {t("closeReport")}
                        </button>
                      )}
                    </form>
                    <form
                      onSubmit={(e) => {
                        e.preventDefault();
                        void mutate("assignment", { team, reviewer });
                      }}
                    >
                      <label>
                        {t("responsibleTeam")}
                        <select
                          aria-label={t("responsibleTeam")}
                          value={team}
                          onChange={(e) => setTeam(e.target.value)}
                        >
                          <option value="security">{t("security")}</option>
                          <option value="data_protection">
                            {t("dataProtection")}
                          </option>
                        </select>
                      </label>
                      <label>
                        {t("reviewer")}
                        <input
                          maxLength={100}
                          value={reviewer}
                          onChange={(e) => setReviewer(e.target.value)}
                        />
                      </label>
                      <button>{t("saveAssignment")}</button>
                    </form>
                    <form
                      onSubmit={(e) => {
                        e.preventDefault();
                        void mutate("notes", { text: note });
                      }}
                    >
                      <label>
                        {t("adminNote")}
                        <textarea
                          required
                          maxLength={5000}
                          value={note}
                          onChange={(e) => setNote(e.target.value)}
                        />
                      </label>
                      <button>{t("addNote")}</button>
                    </form>
                    <form
                      onSubmit={(e) => {
                        e.preventDefault();
                        setConfirm(true);
                      }}
                    >
                      <label>
                        {t("escalationDecision")}
                        <select
                          aria-label={t("escalationDecision")}
                          value={decision}
                          onChange={(e) => setDecision(e.target.value)}
                        >
                          <option value="escalate">
                            {t("escalateForReview")}
                          </option>
                          <option value="do_not_escalate">
                            {t("doNotEscalate")}
                          </option>
                        </select>
                      </label>
                      <label>
                        {t("decisionReason")}
                        <textarea
                          required
                          minLength={3}
                          maxLength={5000}
                          value={reason}
                          onChange={(e) => setReason(e.target.value)}
                        />
                      </label>
                      <button>{t("reviewEscalation")}</button>
                    </form>
                  </fieldset>
                </>
              )}
            </section>
          </div>
        </div>

        <footer className="workspace-footer">
          <Icon name="shield" size={15} />
          Security and data protection are separate role concepts. This demo
          does not enforce access controls.
        </footer>
      </main>
      <WebsiteAssistant
        navigate={(view) => {
          if (view === "reports") {
            setStatus("");
            setType("");
          }
          void navigate(view);
        }}
        ask={async (message, history) => {
          const result = await request<{ reply: string }>(
            "/admin/assistant",
            "POST",
            {
              message,
              history,
              view: page,
              language: locale,
              scope: {
                days: Number(days),
                ...(type
                  ? type.startsWith("group:")
                    ? { group: type.slice(6) }
                    : { category: type }
                  : {}),
                ...(page === "reports" && status ? { status } : {}),
              },
              ...(page === "reports" && detail ? { ticketId: detail.id } : {}),
            },
          );
          return result.reply;
        }}
      />
      {confirm && detail && (
        <div className="modal-backdrop">
          <section
            role="dialog"
            aria-modal="true"
            aria-labelledby="confirm-title"
            className="panel modal"
          >
            <h2 id="confirm-title">{t("confirmEscalation")}</h2>
            <p>{detail.id}</p>
            <p>
              {label(decision)}: {reason}
            </p>
            <p>{t("decisionAudited")}</p>
            <button autoFocus disabled={busy} onClick={() => setConfirm(false)}>
              {t("cancel")}
            </button>{" "}
            <button
              disabled={busy}
              onClick={() =>
                void mutate("escalations", {
                  decision,
                  reason,
                  confirmed: true,
                })
              }
            >
              {t("confirmDecision")}
            </button>
          </section>
        </div>
      )}
    </>
  );
}
