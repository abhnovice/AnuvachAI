import type { Report } from "./App";
const label = (value: string) => value.replaceAll("_", " ");
export function TicketJourney({ report }: { report: Report }) {
  return (
    <section className="ticket-journey" aria-label="Ticket journey">
      <div className="journey-heading">
        <h3>Ticket journey</h3>
        <span className={"badge status-" + report.status}>
          {label(report.status)}
        </span>
      </div>
      <ol className="journey-timeline">
        {report.audit?.map((event) => (
          <li key={event.sequence}>
            <span className="journey-node" aria-hidden="true">
              {event.sequence}
            </span>
            <div>
              <strong>{label(event.action)}</strong>
              <time dateTime={event.at}>
                {new Date(event.at).toLocaleString()}
              </time>
              <small>{event.actor}</small>
              {event.action !== "created" && (
                <dl>
                  {Object.entries(event.data).map(([key, value]) => (
                    <div key={key}>
                      <dt>{label(key)}</dt>
                      <dd>
                        {typeof value === "object"
                          ? JSON.stringify(value)
                          : String(value)}
                      </dd>
                    </div>
                  ))}
                </dl>
              )}
            </div>
          </li>
        ))}
      </ol>
      {!report.audit?.length && <p>No audit events available.</p>}
    </section>
  );
}
