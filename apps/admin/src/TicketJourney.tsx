import type { Report } from "./App";
import { useLocalization } from "./localization";
const label = (value: string) => value.replaceAll("_", " ");
export function TicketJourney({ report }: { report: Report }) {
  const { t, enumLabel } = useLocalization();
  return (
    <section className="ticket-journey" aria-label={t("ticketJourney")}>
      <div className="journey-heading">
        <h3>{t("ticketJourney")}</h3>
        <span className={"badge status-" + report.status}>
          {enumLabel(report.status)}
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
      {!report.audit?.length && <p>{t("noAudit")}</p>}
    </section>
  );
}
