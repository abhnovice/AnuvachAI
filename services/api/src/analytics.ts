import { incidentGroup, type IncidentGroup } from "./incident-groups.js";
import {
  incidentTypes,
  statuses,
  ticketIncidentType,
  type Report,
} from "./contracts.js";

const DAY = 86_400_000;
export type AuditRow = {
  report_id: string;
  action: string;
  at: string;
  sequence: number;
  data: Record<string, unknown>;
};
export function windowStart(days: number, now: Date) {
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()) -
      (days - 1) * DAY,
  );
}
const isoDay = (time: number) => new Date(time).toISOString().slice(0, 10);
const dateLabel = (time: number) =>
  new Date(time).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    timeZone: "UTC",
  });
const mean = (values: number[]) =>
  values.length ? values.reduce((a, b) => a + b, 0) / values.length : null;
const median = (values: number[]) => {
  const sorted = [...values].sort((a, b) => a - b),
    n = sorted.length;
  return n
    ? n % 2
      ? sorted[Math.floor(n / 2)]
      : (sorted[n / 2 - 1] + sorted[n / 2]) / 2
    : null;
};

export function buildDashboard(
  reports: Report[],
  audit: AuditRow[],
  now: Date,
  days = 90,
  incidentType?: string,
  group?: IncidentGroup,
) {
  const end = now.getTime(),
    start = windowStart(days, now).getTime();
  const duration = end - start,
    previousStart = start - duration;
  const population = reports.filter(
    (r) =>
      (!incidentType || ticketIncidentType(r) === incidentType) &&
      (!group || incidentGroup(ticketIncidentType(r)) === group) &&
      Date.parse(r.createdAt) <= end,
  );
  const cohort = population.filter((r) => Date.parse(r.createdAt) >= start);
  const events = new Map<string, AuditRow[]>();
  for (const event of audit) {
    if (Date.parse(event.at) > end) continue;
    const rows = events.get(event.report_id) ?? [];
    rows.push(event);
    events.set(event.report_id, rows);
  }
  for (const rows of events.values())
    rows.sort(
      (a, b) => Date.parse(a.at) - Date.parse(b.at) || a.sequence - b.sequence,
    );
  const lifecycle = new Map<
    string,
    {
      closedAt: number | null;
      firstAction: number | null;
      changes: { at: number; status: string }[];
      closures: number[];
    }
  >();
  for (const report of population) {
    let state = "submitted",
      closedAt: number | null = null,
      firstAction: number | null = null;
    const changes: { at: number; status: string }[] = [],
      closures: number[] = [];
    for (const event of events.get(report.id) ?? []) {
      const at = Date.parse(event.at);
      if (at < Date.parse(report.createdAt)) continue;
      if (event.action !== "created" && firstAction === null) firstAction = at;
      let next: string | undefined;
      if (event.action === "status" && typeof event.data.status === "string")
        next = event.data.status;
      if (event.action === "escalations" && event.data.decision === "escalate")
        next = "escalated";
      if (next && next !== state) {
        if (next === "closed") {
          closedAt = at;
          closures.push(at);
        } else closedAt = null;
        state = next;
        changes.push({ at, status: state });
      }
    }
    lifecycle.set(report.id, { closedAt, firstAction, changes, closures });
  }
  const closed = cohort.filter((r) => r.status === "closed"),
    open = cohort.filter((r) => r.status !== "closed");
  const closeHours = closed.flatMap((r) => {
    const at = lifecycle.get(r.id)?.closedAt;
    return at == null ? [] : [(at - Date.parse(r.createdAt)) / 3_600_000];
  });
  const firstActionHours = cohort.flatMap((r) => {
    const at = lifecycle.get(r.id)?.firstAction;
    return at == null ? [] : [(at - Date.parse(r.createdAt)) / 3_600_000];
  });
  const previousReceived = population.filter(
    (r) =>
      Date.parse(r.createdAt) >= previousStart &&
      Date.parse(r.createdAt) < start,
  ).length;
  const daily = Array.from({ length: days }, (_, i) => {
    const from = start + i * DAY,
      until = Math.min(from + DAY - 1, end);
    let opened = 0,
      archived = 0,
      received = 0,
      closedTransitions = 0;
    for (const r of population) {
      const created = Date.parse(r.createdAt),
        history = lifecycle.get(r.id)!;
      if (created >= from && created <= until) received++;
      closedTransitions += history.closures.filter(
        (at) => at >= from && at <= until,
      ).length;
      if (created > until) continue;
      let status = "submitted";
      for (const change of history.changes) {
        if (change.at <= until) status = change.status;
        else break;
      }
      if (status === "closed") archived++;
      else opened++;
    }
    return {
      date: isoDay(from),
      time: from,
      received,
      closedTransitions,
      open: opened,
      closed: archived,
    };
  });
  const weekly = [];
  for (let i = 0; i < daily.length; i += 7) {
    const rows = daily.slice(i, i + 7),
      last = rows.at(-1)!;
    weekly.push({
      date: rows[0].date,
      endDate: last.date,
      label: dateLabel(rows[0].time),
      received: rows.reduce((n, r) => n + r.received, 0),
      open: last.open,
      closed: last.closed,
    });
  }
  const monthlyMap = new Map<
    string,
    { month: string; label: string; received: number; closed: number }
  >();
  for (const row of daily) {
    const key = row.date.slice(0, 7);
    const month = monthlyMap.get(key) ?? {
      month: key,
      label: new Date(key + "-01T00:00:00Z").toLocaleDateString("en-GB", {
        month: "short",
        year: "2-digit",
        timeZone: "UTC",
      }),
      received: 0,
      closed: 0,
    };
    month.received += row.received;
    month.closed += row.closedTransitions;
    monthlyMap.set(key, month);
  }
  const statusCounts = Object.fromEntries(
    statuses.map((s) => [s, cohort.filter((r) => r.status === s).length]),
  ) as Record<(typeof statuses)[number], number>;
  return {
    scope: {
      days,
      start: new Date(start).toISOString(),
      end: now.toISOString(),
      previousStart: new Date(previousStart).toISOString(),
      incidentType: incidentType ?? null,
      timeZone: "UTC",
      source: "Reports and append-only audit events",
      classification: "Synthetic demonstration",
    },
    metrics: {
      received: cohort.length,
      previousReceived,
      receivedChangePercent: previousReceived
        ? ((cohort.length - previousReceived) / previousReceived) * 100
        : null,
      open: open.length,
      closed: closed.length,
      closedSharePercent: cohort.length
        ? (closed.length / cohort.length) * 100
        : null,
      meanCloseHours: mean(closeHours),
      medianCloseHours: median(closeHours),
      closeSampleSize: closeHours.length,
      meanFirstActionHours: mean(firstActionHours),
      firstActionSampleSize: firstActionHours.length,
      unassigned: cohort.filter((r) => !r.assignment).length,
      awaitingEmployee: statusCounts.awaiting_employee,
      escalated: statusCounts.escalated,
      oldestOpenHours: open.length
        ? Math.max(
            ...open.map((r) => (end - Date.parse(r.createdAt)) / 3_600_000),
          )
        : null,
    },
    weekly,
    monthly: [...monthlyMap.values()],
    incidentMix: incidentTypes.map((type) => ({
      type,
      count: cohort.filter((r) => ticketIncidentType(r) === type).length,
    })),
    statusCounts,
    statusMatrix: incidentTypes.map((type) => ({
      type,
      counts: Object.fromEntries(
        statuses.map((s) => [
          s,
          cohort.filter((r) => ticketIncidentType(r) === type && r.status === s)
            .length,
        ]),
      ) as typeof statusCounts,
    })),
    turnaround: [
      { label: "Under 8h", count: closeHours.filter((h) => h < 8).length },
      {
        label: "8–24h",
        count: closeHours.filter((h) => h >= 8 && h < 24).length,
      },
      {
        label: "1–3 days",
        count: closeHours.filter((h) => h >= 24 && h < 72).length,
      },
      { label: "3+ days", count: closeHours.filter((h) => h >= 72).length },
    ],
    assignments: ["security", "data_protection", "unassigned"].map((team) => ({
      team,
      count: cohort.filter((r) => (r.assignment?.team ?? "unassigned") === team)
        .length,
    })),
  };
}
export type DashboardData = ReturnType<typeof buildDashboard>;
