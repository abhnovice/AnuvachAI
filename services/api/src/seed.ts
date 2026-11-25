import { buildApp } from "./app.js";
const app = await buildApp();
for (const [key, incidentType, description] of [
  [
    "seed-support-call",
    "support_call",
    "Synthetic case: a caller claiming to be IT support asked me to install a remote-access app and share a session code. I ended the call.",
  ],
  [
    "seed-mistaken-report",
    "mistaken_report",
    "Synthetic case: I reported an unexpected support message, then recognised my own scheduled helpdesk request. Please review.",
  ],
]) {
  const response = await app.inject({
    method: "POST",
    url: "/api/v1/reports",
    headers: { "idempotency-key": key },
    payload: {
      employeeId: "demo-employee",
      description,
      language: "english",
      incidentType,
      confirmed: true,
    },
  });
  if (response.statusCode >= 400) throw new Error(response.body);
  console.log(response.json().id);
}
await app.close();
