import { useState } from "react";

export type LocalTriage = {
  status: "pending" | "completed" | "human_review";
  failure?: "unavailable" | "invalid_analysis";
  result?: {
    responder?: string;
    model?: string;
    proposal: {
      proposal_id: string;
      incident_type: string;
      proposed_severity: string;
      proposed_team: string;
      reasons: { text: string; fact_ids: string[] }[];
      evidence_references: { fact_id: string; explains: string }[];
      unknowns: string[];
      recommended_next_questions: string[];
    };
  };
  evidence?: { fact_id: string; text: string }[];
  review?: { decision: "accepted" | "amended"; severity: string; team: string };
};

const label = (value: string) => value.replaceAll("_", " ");

export function TriageReview({
  triage,
  save,
}: {
  triage: LocalTriage;
  save: (review: {
    proposalId: string;
    severity: string;
    team: string;
  }) => void;
}) {
  const proposal = triage.result?.proposal;
  const [severity, setSeverity] = useState(
    triage.review?.severity ?? proposal?.proposed_severity ?? "unassessed",
  );
  const [team, setTeam] = useState(
    triage.review?.team ?? proposal?.proposed_team ?? "unknown",
  );
  if (!proposal) {
    return (
      <section aria-label="AI proposal">
        <h3>AI proposal</h3>
        <p>
          {triage.failure === "invalid_analysis"
            ? "Analysis could not be validated. Human review required."
            : triage.failure === "unavailable"
              ? "Triage temporarily unavailable. Human review required. The API will retry."
              : "Triage pending. You can review the confirmed ticket now."}
        </p>
      </section>
    );
  }
  return (
    <section aria-label="AI proposal">
      <h3>AI proposal</h3>
      {triage.result?.responder && (
        <p>
          {triage.result.responder}
          {triage.result.model ? ` · ${triage.result.model}` : ""}
        </p>
      )}
      <p>
        Human review required. Suggested severity{" "}
        {label(proposal.proposed_severity)}, team{" "}
        {label(proposal.proposed_team)}, incident type{" "}
        {label(proposal.incident_type)}.
      </p>
      <ul>
        {proposal.reasons.map((reason, index) => (
          <li key={index}>
            {reason.text} ({reason.fact_ids.join(", ")})
          </li>
        ))}
      </ul>
      <dl>
        {proposal.evidence_references.map((ref, index) => (
          <div key={index}>
            <dt>{ref.fact_id}</dt>
            <dd>
              {
                triage.evidence?.find((item) => item.fact_id === ref.fact_id)
                  ?.text
              }{" "}
              · {ref.explains}
            </dd>
          </div>
        ))}
      </dl>
      {proposal.unknowns.length > 0 && (
        <p>Unknowns: {proposal.unknowns.join(" · ")}</p>
      )}
      {proposal.recommended_next_questions.length > 0 && (
        <p>Next questions: {proposal.recommended_next_questions.join(" · ")}</p>
      )}
      {triage.review && (
        <p role="status">
          AI proposal {triage.review.decision}. Reviewed severity{" "}
          {label(triage.review.severity)}, team {label(triage.review.team)}.
        </p>
      )}
      <form
        onSubmit={(event) => {
          event.preventDefault();
          save({ proposalId: proposal.proposal_id, severity, team });
        }}
      >
        <label>
          Reviewed severity
          <select
            value={severity}
            onChange={(event) => setSeverity(event.target.value)}
          >
            {["unassessed", "low", "moderate", "high", "critical"].map(
              (value) => (
                <option key={value} value={value}>
                  {label(value)}
                </option>
              ),
            )}
          </select>
        </label>
        <label>
          Reviewed team
          <select
            value={team}
            onChange={(event) => setTeam(event.target.value)}
          >
            {["unknown", "security", "it_support", "data_protection"].map(
              (value) => (
                <option key={value} value={value}>
                  {label(value)}
                </option>
              ),
            )}
          </select>
        </label>
        <button type="submit">
          {severity === proposal.proposed_severity &&
          team === proposal.proposed_team
            ? "Accept AI proposal"
            : "Save amended proposal"}
        </button>
      </form>
    </section>
  );
}
