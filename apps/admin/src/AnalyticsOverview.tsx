import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import type { DashboardData } from "../../../services/api/src/analytics";
import { Icon } from "./Icon";
import {
  incidentGroup,
  incidentGroups,
} from "../../../services/api/src/incident-groups";
import { incidentCategories, useLocalization } from "./localization";
import "./analytics.css";
import "./queue-layout.css";

export type { DashboardData };
const colors = [
  "#006b60",
  "#4a9eae",
  "#84cbbb",
  "#b6cf92",
  "#225fa9",
  "#8246a2",
  "#b35237",
  "#ad7915",
  "#96335a",
  "#466326",
  "#365567",
];
const states = [
  "submitted",
  "in_review",
  "awaiting_employee",
  "escalated",
  "closed",
] as const;
const fmtHours = (n: number | null) =>
  n === null ? "—" : n < 24 ? n.toFixed(1) + "h" : (n / 24).toFixed(1) + "d";
const fmtDate = (s: string, locale: string) =>
  new Date(s).toLocaleDateString(locale, {
    day: "numeric",
    month: "short",
    timeZone: "UTC",
  });

function DataTable({
  headers,
  rows,
}: {
  headers: string[];
  rows: (string | number)[][];
}) {
  const { t } = useLocalization();
  return (
    <details className="chart-data">
      <summary>{t("viewValues")}</summary>
      <div>
        <table>
          <thead>
            <tr>
              {headers.map((h) => (
                <th key={h}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, i) => (
              <tr key={i}>
                {row.map((cell, j) => (
                  <td key={j}>{cell}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </details>
  );
}
function ChartCard({
  title,
  subtitle,
  children,
  definition,
  headers,
  rows,
  className = "",
}: {
  title: string;
  subtitle: string;
  children: ReactNode;
  definition: string;
  headers: string[];
  rows: (string | number)[][];
  className?: string;
}) {
  const selectedPoint = useRef<Element | null>(null);
  const [hover, setHover] = useState<{
    text: string;
    x: number;
    y: number;
  } | null>(null);
  return (
    <section
      className={"chart-card " + className}
      onMouseMove={(event) => {
        const target = event.target as Element;
        const point = target.closest(
          "circle, .bar, .heat-cell, .mix-legend button, .turnaround-bars > div, svg[aria-label]",
        );
        const text =
          point?.getAttribute("aria-label") ||
          point?.getAttribute("title") ||
          point?.querySelector("title")?.textContent ||
          (point?.textContent ?? "");
        setHover(
          text.trim()
            ? { text: text.trim(), x: event.clientX, y: event.clientY }
            : null,
        );
      }}
      onMouseLeave={() => setHover(null)}
      onClick={(event) => {
        const point = (event.target as Element).closest(
          ".trend-chart circle[tabindex], .bar[tabindex]",
        );
        if (!point) return;
        selectedPoint.current?.removeAttribute("data-selected");
        point.setAttribute("data-selected", "true");
        selectedPoint.current = point;
        (point as HTMLElement | SVGElement).focus();
      }}
    >
      {hover && (
        <div
          className="chart-hover-value"
          role="tooltip"
          style={{
            left: `max(8px, min(${hover.x + 12}px, calc(100vw - 250px)))`,
            top: hover.y + 12,
          }}
        >
          {hover.text}
        </div>
      )}
      <div className="chart-heading">
        <h2
          tabIndex={0}
          title={subtitle + ". " + definition}
          aria-label={title + ". " + subtitle + ". " + definition}
        >
          {title}
          <span className="chart-help-mark" aria-hidden="true">
            {" "}
            ⓘ
          </span>
        </h2>
      </div>
      <div className="chart-body">{children}</div>
      <DataTable headers={headers} rows={rows} />
    </section>
  );
}
function Trend({
  rows,
  series,
  label,
  brush,
  onBrush,
}: {
  rows: { label: string; values: number[] }[];
  brush: [number, number] | null;
  onBrush: (range: [number, number]) => void;
  series: { name: string; color: string }[];
  label: string;
}) {
  const id = useId().replaceAll(":", "");
  const drag = useRef<number | null>(null);
  const w = 360,
    h = 190,
    left = 35,
    right = 12,
    top = 16,
    bottom = 35,
    innerW = w - left - right,
    innerH = h - top - bottom;
  const max = Math.max(1, ...rows.flatMap((r) => r.values)),
    ceiling = Math.max(2, Math.ceil(max / 2) * 2);
  const x = (i: number) =>
      left + (rows.length <= 1 ? innerW / 2 : (i * innerW) / (rows.length - 1)),
    y = (n: number) => top + innerH - (n / ceiling) * innerH;
  const pointerIndex = (
    svg: SVGSVGElement,
    clientX: number,
    clientY: number,
  ) => {
    const matrix = svg.getScreenCTM();
    if (!matrix) return 0;
    const point = svg.createSVGPoint();
    point.x = clientX;
    point.y = clientY;
    const localX = point.matrixTransform(matrix.inverse()).x;
    return Math.max(
      0,
      Math.min(
        rows.length - 1,
        Math.round(((localX - left) / innerW) * (rows.length - 1)),
      ),
    );
  };
  return (
    <>
      <svg
        viewBox={"0 0 " + w + " " + h}
        className="trend-chart"
        role="img"
        aria-label={label}
        onPointerDown={(event) => {
          if (!rows.length || event.button !== 0) return;
          const index = pointerIndex(
            event.currentTarget,
            event.clientX,
            event.clientY,
          );
          drag.current = index;
          event.currentTarget.setPointerCapture(event.pointerId);
        }}
        onPointerMove={(event) => {
          if (drag.current === null) return;
          const index = pointerIndex(
            event.currentTarget,
            event.clientX,
            event.clientY,
          );
          if (index !== drag.current)
            onBrush([
              Math.min(index, drag.current),
              Math.max(index, drag.current),
            ]);
        }}
        onPointerUp={() => {
          drag.current = null;
        }}
        onPointerCancel={() => {
          drag.current = null;
        }}
      >
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={series[0].color} stopOpacity=".16" />
            <stop offset="100%" stopColor={series[0].color} stopOpacity="0" />
          </linearGradient>
        </defs>
        {[0, 0.5, 1].map((t) => (
          <g key={t}>
            <line
              x1={left}
              x2={w - right}
              y1={y(ceiling * t)}
              y2={y(ceiling * t)}
              stroke="#e1ebe5"
              strokeDasharray={t ? "3 4" : undefined}
            />
            <text x={left - 9} y={y(ceiling * t) + 4} textAnchor="end">
              {ceiling * t}
            </text>
          </g>
        ))}
        {rows.length > 0 && (
          <path
            d={
              "M" +
              x(0) +
              "," +
              y(0) +
              " " +
              rows.map((r, i) => "L" + x(i) + "," + y(r.values[0])).join(" ") +
              " L" +
              x(rows.length - 1) +
              "," +
              y(0) +
              " Z"
            }
            fill={"url(#" + id + ")"}
          />
        )}
        {brush && (
          <rect
            className="brush-band"
            x={Math.max(
              left,
              x(brush[0]) - innerW / Math.max(rows.length - 1, 1) / 2,
            )}
            y={top}
            width={
              Math.min(
                w - right,
                x(brush[1]) + innerW / Math.max(rows.length - 1, 1) / 2,
              ) -
              Math.max(
                left,
                x(brush[0]) - innerW / Math.max(rows.length - 1, 1) / 2,
              )
            }
            height={innerH}
          />
        )}
        {series.map((s, j) => (
          <g key={s.name}>
            <polyline
              fill="none"
              stroke={s.color}
              strokeWidth="2.4"
              strokeDasharray={j ? "5 4" : undefined}
              points={rows.map((r, i) => x(i) + "," + y(r.values[j])).join(" ")}
            />
            {rows.map((r, i) => (
              <circle
                key={i}
                cx={x(i)}
                cy={y(r.values[j])}
                r="3.3"
                className={
                  brush
                    ? i >= brush[0] && i <= brush[1]
                      ? "brush-match"
                      : "brush-dim"
                    : undefined
                }
                fill="white"
                stroke={s.color}
                strokeWidth="2"
                tabIndex={0}
                aria-label={r.label + ", " + s.name + ": " + r.values[j]}
              >
                <title>
                  {r.label} · {s.name}: {r.values[j]}
                </title>
              </circle>
            ))}
          </g>
        ))}
        {rows.map(
          (r, i) =>
            (i === 0 ||
              i === rows.length - 1 ||
              i === Math.floor((rows.length - 1) / 2)) && (
              <text
                key={i}
                x={x(i)}
                y={h - 9}
                textAnchor={
                  i === 0 ? "start" : i === rows.length - 1 ? "end" : "middle"
                }
              >
                {r.label}
              </text>
            ),
        )}
      </svg>
      <div className="chart-legend">
        {series.map((s, j) => (
          <span key={s.name}>
            <i style={{ background: s.color, borderRadius: j ? 0 : 8 }} />
            {s.name}
          </span>
        ))}
      </div>
    </>
  );
}
function MonthlyBars({
  data,
  start,
  end,
}: {
  data: DashboardData["monthly"];
  start?: string;
  end?: string;
}) {
  const max = Math.max(2, ...data.flatMap((r) => [r.received, r.closed]));
  return (
    <div
      className="monthly-chart"
      role="img"
      aria-label="Reports received and closed transitions by calendar month"
    >
      <div className="bar-scale">
        <span>{max}</span>
        <span>{Math.round(max / 2)}</span>
        <span>0</span>
      </div>
      <div className="bar-columns">
        {data.map((r) => (
          <div
            className={
              "bar-month" +
              (start && end
                ? r.month >= start.slice(0, 7) && r.month <= end.slice(0, 7)
                  ? " brush-match"
                  : " brush-dim"
                : "")
            }
            key={r.month}
          >
            <div className="paired-bars">
              <span
                className="bar received-bar"
                style={{ height: (r.received / max) * 100 + "%" }}
                tabIndex={0}
                aria-label={r.label + ": " + r.received + " received"}
                title={r.label + ": " + r.received + " received"}
              >
                <b>{r.received}</b>
              </span>
              <span
                className="bar closed-bar"
                style={{ height: (r.closed / max) * 100 + "%" }}
                tabIndex={0}
                aria-label={r.label + ": " + r.closed + " closed transitions"}
                title={r.label + ": " + r.closed + " closed transitions"}
              >
                <b>{r.closed}</b>
              </span>
            </div>
            <span className="bar-label">{r.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export function AnalyticsOverview({
  data,
  loading,
  days,
  type,
  onDays,
  onType,
  onStatus,
}: {
  data: DashboardData | null;
  loading: boolean;
  days: string;
  type: string;
  onDays: (value: string) => void;
  onType: (value: string) => void;
  onStatus: (status: string, type?: string) => void;
}) {
  const { t, enumLabel, locale } = useLocalization();
  const names = new Proxy({} as Record<string, string>, {
    get: (_target, key) =>
      typeof key === "string" ? enumLabel(key) : undefined,
  });
  const [brush, setBrush] = useState<[number, number] | null>(null);
  const [category, setCategory] = useState<string | null>(null);
  useEffect(() => {
    setBrush(null);
    setCategory(null);
  }, [days, type]);
  const turnaroundLabels = [
    t("turnaroundUnderHours"),
    t("turnaroundHours"),
    t("turnaroundDays"),
    t("turnaroundOverDays"),
  ];
  const monthly =
    data?.monthly.map((row) => ({
      ...row,
      label: new Intl.DateTimeFormat(locale, {
        month: "short",
        year: "2-digit",
        timeZone: "UTC",
      }).format(new Date(row.month + "-01T00:00:00Z")),
    })) ?? [];
  const m = data?.metrics,
    total = m?.received ?? 0;
  const effectiveBrush =
    brush && data?.weekly[brush[0]] && data.weekly[brush[1]] ? brush : null;
  const mix = incidentGroups.map((group) => ({
    type: `group:${group}`,
    count:
      data?.incidentMix.reduce(
        (sum, row) => sum + (incidentGroup(row.type) === group ? row.count : 0),
        0,
      ) ?? 0,
  }));
  const matrix = incidentGroups.map((group) => ({
    type: `group:${group}`,
    counts: Object.fromEntries(
      states.map((status) => [
        status,
        data?.statusMatrix.reduce(
          (sum, row) =>
            sum + (incidentGroup(row.type) === group ? row.counts[status] : 0),
          0,
        ) ?? 0,
      ]),
    ),
  }));
  const maxStatus = Math.max(
    1,
    ...matrix.flatMap((row) => Object.values(row.counts)),
  );
  let offset = 0;
  return (
    <section
      className="analytics-overview"
      aria-label={t("analytics")}
      aria-busy={loading}
    >
      <div className="overview-scope">
        <div>
          <p>
            {data
              ? fmtDate(data.scope.start, locale) +
                " – " +
                fmtDate(data.scope.end, locale) +
                " " +
                new Date(data.scope.end).getUTCFullYear() +
                " · UTC"
              : ""}
          </p>
        </div>
        <div className="overview-controls">
          <label>
            {t("reportingWindow")}
            <select
              aria-label={t("reportingWindow")}
              value={days}
              onChange={(e) => onDays(e.target.value)}
            >
              <option value="30">{t("last30")}</option>
              <option value="90">{t("last90")}</option>
              <option value="180">{t("last180")}</option>
            </select>
          </label>
          <label>
            {t("incidentCategory")}
            <select
              aria-label={t("dashboardIncidentType")}
              value={type}
              onChange={(e) => onType(e.target.value)}
            >
              <option value="">{t("allIncidentTypes")}</option>
              {incidentGroups.map((group) => (
                <option key={group} value={`group:${group}`}>
                  {names[`group:${group}`]}
                </option>
              ))}
              {incidentCategories.map((t) => (
                <option key={t} value={t}>
                  {names[t]}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>
      {!data ? (
        <div className="analytics-placeholder">
          {loading ? (
            <>
              <span className="loading-line" />
              <p>{t("loadingAnalytics")}</p>
            </>
          ) : (
            <p>{t("analyticsUnavailable")}</p>
          )}
        </div>
      ) : (
        <>
          <div className="brush-controls">
            <span>{t("brushWeeks")}</span>
            <label>
              {t("from")}{" "}
              <select
                aria-label={t("brushFromWeek")}
                value={effectiveBrush?.[0] ?? 0}
                onChange={(e) => {
                  const value = Number(e.target.value);
                  setBrush([
                    Math.min(
                      value,
                      effectiveBrush?.[1] ?? data.weekly.length - 1,
                    ),
                    Math.max(
                      value,
                      effectiveBrush?.[1] ?? data.weekly.length - 1,
                    ),
                  ]);
                }}
              >
                {data.weekly.map((w, i) => (
                  <option key={w.date} value={i}>
                    {fmtDate(w.date, locale)}
                  </option>
                ))}
              </select>
            </label>
            <label>
              {t("through")}{" "}
              <select
                aria-label={t("brushThroughWeek")}
                value={
                  effectiveBrush?.[1] ?? Math.max(0, data.weekly.length - 1)
                }
                onChange={(e) => {
                  const value = Number(e.target.value);
                  setBrush([
                    Math.min(value, effectiveBrush?.[0] ?? 0),
                    Math.max(value, effectiveBrush?.[0] ?? 0),
                  ]);
                }}
              >
                {data.weekly.map((w, i) => (
                  <option key={w.date} value={i}>
                    {fmtDate(w.endDate, locale)}
                  </option>
                ))}
              </select>
            </label>
            <button disabled={!effectiveBrush} onClick={() => setBrush(null)}>
              {t("clearBrush")}
            </button>
            <small>
              {effectiveBrush
                ? `Highlighting ${data.weekly[effectiveBrush[0]].date}–${data.weekly[effectiveBrush[1]].endDate} UTC. Monthly bars represent whole overlapping months; totals remain unchanged.`
                : t("dragBrushHint")}
            </small>
          </div>
          <div className="metric-grid">
            <button
              type="button"
              className="metric-card"
              onClick={() => onStatus("")}
              aria-label={t("viewReceived")}
            >
              <div className="metric-label">
                <Icon name="reports" />
                {t("reportsReceived")}
              </div>
              <strong>{m!.received}</strong>
              <div className="metric-context">
                {m!.receivedChangePercent === null
                  ? t("noPreviousBaseline")
                  : (m!.receivedChangePercent >= 0 ? "+" : "") +
                    m!.receivedChangePercent.toFixed(0) +
                    "% vs preceding period"}
              </div>
            </button>
            <button
              type="button"
              className="metric-card"
              onClick={() => onStatus("open")}
              aria-label={t("viewOpen")}
            >
              <div className="metric-label">
                <Icon name="clock" />
                {t("stillOpen")}
              </div>
              <strong>{m!.open}</strong>
              <div className="metric-context">
                <small>
                  {m!.awaitingEmployee} awaiting employee · {m!.escalated}{" "}
                  escalated
                </small>
              </div>
            </button>
            <button
              type="button"
              className="metric-card"
              onClick={() => onStatus("closed")}
              aria-label={t("viewClosed")}
            >
              <div className="metric-label">
                <Icon name="check" />
                {t("currentlyClosed")}
              </div>
              <strong>
                {m!.closed}
                <em>
                  {m!.closedSharePercent === null
                    ? "—"
                    : m!.closedSharePercent.toFixed(0) + "%"}
                </em>
              </strong>
            </button>
            <button
              type="button"
              className="metric-card"
              onClick={() => onStatus("closed")}
              aria-label={t("viewClosureTime")}
            >
              <div className="metric-label">
                <Icon name="refresh" />
                {t("meanClose")}
              </div>
              <strong>{fmtHours(m!.meanCloseHours)}</strong>
              <div className="metric-context">
                <small>
                  {m!.closeSampleSize} {t("currentlyClosed")} ·{" "}
                  {t("medianTurnaround")} {fmtHours(m!.medianCloseHours)}
                </small>
              </div>
            </button>
          </div>
          <div className="operational-strip">
            <span>
              <i />
              {t("unassigned")} <strong>{m!.unassigned}</strong>
            </span>
            <span>
              {t("firstAdminAction")}{" "}
              <strong>{fmtHours(m!.meanFirstActionHours)}</strong>
              <small>
                ({m!.firstActionSampleSize} {t("reportLabel")})
              </small>
            </span>
            <span>
              {t("oldestOpen")} <strong>{fmtHours(m!.oldestOpenHours)}</strong>
            </span>
          </div>
          {!total && (
            <div className="analytics-empty">
              <Icon name="reports" />
              <div>
                <strong>No reports received in this selection.</strong>
                <p>
                  Try a wider window or another category. Historical activity
                  may still include older reports.
                </p>
              </div>
            </div>
          )}
          <div className="analytics-grid">
            <ChartCard
              title={t("incomingReports")}
              subtitle={t("chartSubtitle1")}
              definition={t("chartDefinition1")}
              headers={[
                `${t("from")} (UTC)`,
                `${t("through")} (UTC)`,
                t("receivedLabel"),
              ]}
              rows={data.weekly.map((r) => [r.date, r.endDate, r.received])}
            >
              <Trend
                rows={data.weekly.map((r) => ({
                  label: fmtDate(r.date, locale),
                  values: [r.received],
                }))}
                series={[{ name: t("receivedLabel"), color: "#006b60" }]}
                brush={effectiveBrush}
                onBrush={setBrush}
                label="Weekly incoming report counts"
              />
            </ChartCard>
            <ChartCard
              title={t("incidentMix")}
              className="grouped-chart"
              subtitle={t("chartSubtitle2")}
              definition={t("chartDefinition2")}
              headers={[t("categoryLabel"), t("reportLabel"), t("shareLabel")]}
              rows={mix.map((r) => [
                names[r.type],
                r.count,
                total ? ((r.count / total) * 100).toFixed(1) + "%" : "—",
              ])}
            >
              <div className="mix-visual">
                <svg
                  viewBox="0 0 160 160"
                  role="img"
                  aria-label={
                    "Incident category distribution across " +
                    total +
                    " reports"
                  }
                >
                  <circle
                    cx="80"
                    cy="80"
                    r="58"
                    fill="none"
                    stroke="#edf3ef"
                    strokeWidth="23"
                  />
                  {mix.map((r, i) => {
                    const length = total ? (r.count / total) * 100 : 0;
                    const current = offset;
                    offset += length;
                    return (
                      <circle
                        key={r.type}
                        className={
                          category
                            ? category === r.type
                              ? "category-match"
                              : "category-dim"
                            : undefined
                        }
                        onPointerEnter={() => setCategory(r.type)}
                        onPointerLeave={() => setCategory(null)}
                        cx="80"
                        cy="80"
                        r="58"
                        pathLength="100"
                        fill="none"
                        stroke={colors[i]}
                        strokeWidth="23"
                        strokeDasharray={length + " " + (100 - length)}
                        strokeDashoffset={-current}
                        transform="rotate(-90 80 80)"
                      >
                        <title>
                          {names[r.type]}: {r.count}
                        </title>
                      </circle>
                    );
                  })}
                  <text
                    x="80"
                    y="78"
                    textAnchor="middle"
                    className="donut-value"
                  >
                    {total}
                  </text>
                  <text
                    x="80"
                    y="98"
                    textAnchor="middle"
                    className="donut-caption"
                  >
                    {t("reportLabel")}
                  </text>
                </svg>
                <div className="mix-legend">
                  {mix.map((r, i) => (
                    <button
                      key={r.type}
                      onPointerEnter={() => setCategory(r.type)}
                      onPointerLeave={() => setCategory(null)}
                      onFocus={() => setCategory(r.type)}
                      onBlur={() => setCategory(null)}
                      className={
                        (type === r.type ? "active " : "") +
                        (category
                          ? category === r.type
                            ? "category-match"
                            : "category-dim"
                          : "")
                      }
                      onClick={() => onType(type === r.type ? "" : r.type)}
                      aria-pressed={type === r.type}
                    >
                      <i style={{ background: colors[i] }} />
                      <span>{names[r.type]}</span>
                      <b>{r.count}</b>
                      <small>
                        {total
                          ? ((r.count / total) * 100).toFixed(0) + "%"
                          : "—"}
                      </small>
                    </button>
                  ))}
                </div>
              </div>
            </ChartCard>
            <ChartCard
              title={t("receivedClosed")}
              subtitle={t("chartSubtitle3")}
              definition={t("chartDefinition3")}
              headers={[
                t("monthLabel"),
                t("receivedLabel"),
                t("closedTransitions"),
              ]}
              rows={monthly.map((r) => [r.label, r.received, r.closed])}
            >
              <MonthlyBars
                data={monthly}
                start={
                  effectiveBrush
                    ? data.weekly[effectiveBrush[0]].date
                    : undefined
                }
                end={
                  effectiveBrush
                    ? data.weekly[effectiveBrush[1]].endDate
                    : undefined
                }
              />
              <div className="chart-legend">
                <span>
                  <i style={{ background: "#006b60" }} />
                  {t("receivedLabel")}
                </span>
                <span>
                  <i style={{ background: "#8ccbbb" }} />
                  {t("closedTransitions")}
                </span>
              </div>
            </ChartCard>
            <ChartCard
              title={t("closureTurnaround")}
              subtitle={t("chartSubtitle4")}
              definition={t("chartDefinition4")}
              headers={[t("durationLabel"), t("closed")]}
              rows={data.turnaround.map((r, i) => [
                turnaroundLabels[i],
                r.count,
              ])}
            >
              <div className="closure-visual">
                <svg
                  viewBox="0 0 180 115"
                  role="img"
                  aria-label={
                    m!.closedSharePercent === null
                      ? "Closed share unavailable: no reports in this window"
                      : "Closed share: " +
                        m!.closedSharePercent.toFixed(1) +
                        " percent"
                  }
                >
                  <path
                    d="M20 88 A70 70 0 0 1 160 88"
                    fill="none"
                    stroke="#e5eee8"
                    strokeWidth="14"
                    strokeLinecap="round"
                  />
                  {(m!.closedSharePercent ?? 0) > 0 && (
                    <path
                      d="M20 88 A70 70 0 0 1 160 88"
                      pathLength="100"
                      fill="none"
                      stroke="#006b60"
                      strokeWidth="14"
                      strokeLinecap="round"
                      strokeDasharray={(m!.closedSharePercent ?? 0) + " 100"}
                    />
                  )}
                  <text
                    x="90"
                    y="78"
                    textAnchor="middle"
                    className="gauge-value"
                  >
                    {m!.closedSharePercent === null
                      ? "—"
                      : m!.closedSharePercent.toFixed(0) + "%"}
                  </text>
                  <text x="90" y="101" textAnchor="middle">
                    {t("currentlyClosed")}
                  </text>
                </svg>
                <div>
                  <span>{t("medianTurnaround")}</span>
                  <strong>{fmtHours(m!.medianCloseHours)}</strong>
                  <small>
                    {m!.closeSampleSize} {t("recordedClosures")}
                  </small>
                </div>
              </div>
              <div className="turnaround-bars">
                {data.turnaround.map((r, i) => (
                  <div key={r.label}>
                    <span>{turnaroundLabels[i]}</span>
                    <i>
                      <b
                        style={{
                          width:
                            (m!.closeSampleSize
                              ? (r.count / m!.closeSampleSize) * 100
                              : 0) + "%",
                        }}
                      />
                    </i>
                    <strong>{r.count}</strong>
                  </div>
                ))}
              </div>
              {m!.closed > m!.closeSampleSize && (
                <small>
                  {m!.closed - m!.closeSampleSize} closed reports lack a
                  recorded closure timestamp.
                </small>
              )}
            </ChartCard>
            <ChartCard
              title={t("statusByType")}
              className="grouped-chart"
              subtitle={t("chartSubtitle5")}
              definition={t("chartDefinition5")}
              headers={[t("type"), ...states.map((s) => names[s])]}
              rows={matrix.map((r) => [
                names[r.type],
                ...states.map((s) => r.counts[s]),
              ])}
            >
              <div className="heatmap-scroll">
                <table className="status-heatmap">
                  <thead>
                    <tr>
                      <th>{t("type")}</th>
                      {states.map((s, i) => (
                        <th key={s} title={names[states[i]]}>
                          {names[s]}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {matrix.map((row) => (
                      <tr
                        key={row.type}
                        className={
                          category
                            ? category === row.type
                              ? "category-match"
                              : "category-dim"
                            : undefined
                        }
                        onPointerEnter={() => setCategory(row.type)}
                        onPointerLeave={() => setCategory(null)}
                        onFocus={() => setCategory(row.type)}
                        onBlur={() => setCategory(null)}
                      >
                        <th>{names[row.type]}</th>
                        {states.map((s) => {
                          const n = row.counts[s],
                            max = maxStatus,
                            alpha = n ? 0.13 + (n / max) * 0.72 : 0.035;
                          return (
                            <td key={s}>
                              <button
                                className="heat-cell"
                                style={{
                                  background:
                                    "rgba(var(--heat-rgb, 0,107,96)," +
                                    alpha +
                                    ")",
                                  color:
                                    n / max > 0.6
                                      ? "var(--heat-high, white)"
                                      : "var(--heat-low, #245d4b)",
                                }}
                                onClick={() => onStatus(s, row.type)}
                                aria-label={
                                  names[row.type] +
                                  ", " +
                                  names[s] +
                                  ": " +
                                  n +
                                  " reports; show queue"
                                }
                              >
                                {n}
                              </button>
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="heatmap-scale">
                <span>{t("fewer")}</span>
                <i />
                <span>{t("moreReports")}</span>
              </div>
            </ChartCard>
            <ChartCard
              title={t("openClosedWorkload")}
              subtitle={t("chartSubtitle6")}
              definition={t("chartDefinition6")}
              headers={[`${t("through")} (UTC)`, t("stillOpen"), t("closed")]}
              rows={data.weekly.map((r) => [r.endDate, r.open, r.closed])}
            >
              <Trend
                rows={data.weekly.map((r) => ({
                  label: fmtDate(r.endDate, locale),
                  values: [r.open, r.closed],
                }))}
                series={[
                  { name: t("stillOpen"), color: "#006b60" },
                  { name: t("closed"), color: "#8a9e56" },
                ]}
                brush={effectiveBrush}
                onBrush={setBrush}
                label="Open and closed report workload over time"
              />
            </ChartCard>
          </div>
          <div className="assignment-summary">
            <span>{t("responsibilityCohort")}</span>
            {data.assignments.map((r) => (
              <span key={r.team}>
                {names[r.team]} <strong>{r.count}</strong>
              </span>
            ))}
          </div>
        </>
      )}
    </section>
  );
}
