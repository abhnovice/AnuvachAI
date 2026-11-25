import { useEffect, useState } from "react";
export type Report = {
  id: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  version: number;
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
const types = [
  "support_call",
  "suspicious_message",
  "mistaken_report",
  "other",
];
const statuses = [
  "submitted",
  "in_review",
  "awaiting_employee",
  "escalated",
  "closed",
];
const label = (s: string) => s.replaceAll("_", " ");
export async function request<T>(
  path: string,
  method = "GET",
  body?: unknown,
): Promise<T> {
  const response = await fetch("/api/v1" + path, {
    method,
    headers: { "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(
      error.error ?? "API unavailable. Start the local API and retry.",
    );
  }
  return response.json();
}
export function App() {
  const [reports, setReports] = useState<Report[]>([]),
    [detail, setDetail] = useState<Report | null>(null);
  const [status, setStatus] = useState(""),
    [type, setType] = useState(""),
    [error, setError] = useState(""),
    [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false),
    [team, setTeam] = useState("security"),
    [reviewer, setReviewer] = useState(""),
    [note, setNote] = useState("");
  const [newStatus, setNewStatus] = useState("in_review"),
    [decision, setDecision] = useState("escalate"),
    [reason, setReason] = useState(""),
    [confirm, setConfirm] = useState(false);
  const [message, setMessage] = useState("");
  async function load() {
    setLoading(true);
    setError("");
    try {
      const q = new URLSearchParams();
      if (status) q.set("status", status);
      if (type) q.set("incidentType", type);
      setReports(await request<Report[]>("/reports?" + q));
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    void load();
  }, [status, type]);
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
      <header>
        <div className="brand">
          <span aria-hidden="true" className="logo">
            A
          </span>
          <div>
            Anuvach.AI<small>INCIDENT DESK · STAGES 1–2</small>
          </div>
        </div>
        <span className="badge">Synthetic demo · No authentication</span>
      </header>
      <main>
        <div className="intro">
          <div>
            <p className="eyebrow">SECURITY OPERATIONS</p>
            <h1>Listen. Review. Respond.</h1>
            <p>Employee reports, with facts kept separate from conclusions.</p>
          </div>
          <button onClick={() => void load()} disabled={loading}>
            Refresh queue
          </button>
        </div>
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
        <div className="workspace">
          <section className="panel">
            <h2>
              Report queue <span className="count">{reports.length}</span>
            </h2>
            <div className="filters">
              <label>
                Status
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value)}
                >
                  <option value="">All statuses</option>
                  {statuses.map((s) => (
                    <option key={s}>{s}</option>
                  ))}
                </select>
              </label>
              <label>
                Incident type
                <select value={type} onChange={(e) => setType(e.target.value)}>
                  <option value="">All types</option>
                  {types.map((t) => (
                    <option key={t}>{t}</option>
                  ))}
                </select>
              </label>
            </div>
            {loading && <p role="status">Loading reports…</p>}
            {!loading && !reports.length && !error && (
              <p>No reports match these filters.</p>
            )}
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Ticket / received</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Elapsed</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map((r) => (
                    <tr key={r.id}>
                      <td>
                        <button
                          className="ticket"
                          onClick={() => void open(r.id)}
                        >
                          {r.id}
                        </button>
                        <small>{new Date(r.createdAt).toLocaleString()}</small>
                      </td>
                      <td>{label(r.facts.incidentType)}</td>
                      <td>
                        <span className="badge">{label(r.status)}</span>
                      </td>
                      <td>
                        {Math.max(
                          0,
                          Math.floor(
                            (Date.now() - Date.parse(r.createdAt)) / 60000,
                          ),
                        )}{" "}
                        min
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
          <section className="panel detail" aria-label="Report detail">
            {!detail ? (
              <>
                <h2>Review a report</h2>
                <p>
                  Select a ticket to read the submitted facts and decide a next
                  step.
                </p>
                <p>
                  Policy citations: not available in this stage.
                  <br />
                  AI-assigned severity: not available in this stage.
                </p>
              </>
            ) : (
              <>
                <div className="detail-top">
                  <h2>Report detail</h2>
                  <button onClick={() => void open(detail.id)} disabled={busy}>
                    Refresh detail
                  </button>
                </div>
                <p className="id">{detail.id}</p>
                <p>
                  <span className="badge">{label(detail.status)}</span>
                </p>
                <small>
                  Received {new Date(detail.createdAt).toLocaleString()}
                  <br />
                  Updated {new Date(detail.updatedAt).toLocaleString()}
                </small>
                <h3>Employee statements</h3>
                <p className="statement">{detail.facts.description}</p>
                <dl>
                  <dt>Report language</dt>
                  <dd>{detail.facts.language}</dd>
                  <dt>Incident type</dt>
                  <dd>{label(detail.facts.incidentType)}</dd>
                  <dt>App name</dt>
                  <dd>{detail.facts.appName || "Not supplied"}</dd>
                  <dt>Evidence notes</dt>
                  <dd>{detail.facts.evidenceNotes || "Not supplied"}</dd>
                </dl>
                <h3>Device observations</h3>
                {!detail.facts.observations.length ? (
                  <p>No automatic checks supplied.</p>
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
                  Policy citations: <strong>not available in this stage</strong>
                  <br />
                  AI-assigned severity:{" "}
                  <strong>not available in this stage</strong>
                </p>
                <fieldset disabled={busy}>
                  <legend>Administrator actions · Demo administrator</legend>
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      void mutate("status", { status: newStatus });
                    }}
                  >
                    <label>
                      New status
                      <select
                        value={newStatus}
                        onChange={(e) => setNewStatus(e.target.value)}
                      >
                        {statuses
                          .filter((s) => s !== "escalated")
                          .map((s) => (
                            <option key={s}>{s}</option>
                          ))}
                      </select>
                    </label>
                    <button>Save status</button>
                  </form>
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      void mutate("assignment", { team, reviewer });
                    }}
                  >
                    <label>
                      Responsible team
                      <select
                        value={team}
                        onChange={(e) => setTeam(e.target.value)}
                      >
                        <option value="security">Security</option>
                        <option value="data_protection">Data protection</option>
                      </select>
                    </label>
                    <label>
                      Reviewer
                      <input
                        maxLength={100}
                        value={reviewer}
                        onChange={(e) => setReviewer(e.target.value)}
                      />
                    </label>
                    <button>Save assignment</button>
                  </form>
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      void mutate("notes", { text: note });
                    }}
                  >
                    <label>
                      Administrator note
                      <textarea
                        required
                        maxLength={5000}
                        value={note}
                        onChange={(e) => setNote(e.target.value)}
                      />
                    </label>
                    <button>Add note</button>
                  </form>
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      setConfirm(true);
                    }}
                  >
                    <label>
                      Escalation decision
                      <select
                        value={decision}
                        onChange={(e) => setDecision(e.target.value)}
                      >
                        <option value="escalate">Escalate for review</option>
                        <option value="do_not_escalate">Do not escalate</option>
                      </select>
                    </label>
                    <label>
                      Decision reason
                      <textarea
                        required
                        minLength={3}
                        maxLength={5000}
                        value={reason}
                        onChange={(e) => setReason(e.target.value)}
                      />
                    </label>
                    <button>Review escalation decision</button>
                  </form>
                </fieldset>
                <h3>Administrator notes and audit history</h3>
                <ol className="audit">
                  {detail.audit?.map((a) => (
                    <li key={a.sequence}>
                      <strong>{label(a.action)}</strong> · {a.actor}
                      <small>{new Date(a.at).toLocaleString()}</small>
                      {a.action !== "created" && (
                        <pre>{JSON.stringify(a.data, null, 2)}</pre>
                      )}
                    </li>
                  ))}
                </ol>
              </>
            )}
          </section>
        </div>
      </main>
      {confirm && detail && (
        <div className="modal-backdrop">
          <section
            role="dialog"
            aria-modal="true"
            aria-labelledby="confirm-title"
            className="panel modal"
          >
            <h2 id="confirm-title">Confirm escalation decision</h2>
            <p>{detail.id}</p>
            <p>
              {label(decision)}: {reason}
            </p>
            <p>This decision will be persisted and audited.</p>
            <button autoFocus disabled={busy} onClick={() => setConfirm(false)}>
              Cancel
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
              Confirm decision
            </button>
          </section>
        </div>
      )}
    </>
  );
}
