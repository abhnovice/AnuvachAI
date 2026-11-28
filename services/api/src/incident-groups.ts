export const incidentGroups = [
  "vishing",
  "phishing",
  "deepfake",
  "payment",
  "account_access",
  "other",
] as const;

export type IncidentGroup = (typeof incidentGroups)[number];

export function incidentGroup(type: string): IncidentGroup {
  switch (type) {
    case "support_call":
    case "voice_phishing":
      return "vishing";
    case "suspicious_message":
    case "email_phishing":
    case "messaging_phishing":
    case "qr_phishing":
      return "phishing";
    case "deepfake_impersonation":
      return "deepfake";
    case "payment_fraud":
      return "payment";
    case "mfa_fatigue":
    case "remote_access_scam":
      return "account_access";
    default:
      return "other";
  }
}
