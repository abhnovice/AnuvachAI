import {
  createContext,
  useContext,
  useEffect,
  useLayoutEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import hi from "./hi.json";
import te from "./te.json";
import kn from "./kn.json";
import bn from "./bn.json";
import ml from "./ml.json";
import ur from "./ur.json";
import pa from "./pa.json";

export const languages = {
  en: "English",
  hi: "हिन्दी",
  ta: "தமிழ்",
  te: "తెలుగు",
  bn: "বাংলা",
  kn: "ಕನ್ನಡ",
  ml: "മലയാളം",
  ur: "اردو",
  pa: "ਪੰਜਾਬੀ",
} as const;
export type Language = keyof typeof languages;

const en = {
    syntheticData: "Synthetic demonstration data",
    localApiHistory: "Reports and audit history from the local API",
    dashboardIncidentType: "Dashboard incident type",
    loadingAnalytics: "Loading report analytics…",
    analyticsUnavailable: "Analytics unavailable. Refresh the queue to retry.",
    brushWeeks: "Brush weeks",
    brushFromWeek: "Brush from week",
    brushThroughWeek: "Brush through week",
    from: "From",
    through: "Through",
    clearBrush: "Clear brush",
    dragBrushHint: "Drag across either weekly chart or choose weeks. Totals remain unchanged.",
    viewReceived: "View reports received",
    viewOpen: "View open reports",
    viewClosed: "View closed reports",
    viewClosureTime: "View reports contributing to closure time",
    noPreviousBaseline: "No previous-period baseline",
    medianTurnaround: "Median turnaround",
    fewer: "Fewer",
    moreReports: "More reports",
    responsibilityCohort: "Responsibility in this cohort",
    assignmentIdentityNote: "Team assignment is separate from employee identity.",
  chartSubtitle1: "New reports in consecutive seven-day buckets",
  chartDefinition1:
    "Counts reports by receipt time within the selected window. The final bucket may be shorter than seven days.",
  chartSubtitle2: "Employee-selected categories · click to filter",
  chartDefinition2:
    "Each report appears in exactly one category. Percentages use reports received in the selected window.",
  chartSubtitle3: "Activity by calendar month within this window",
  chartDefinition3:
    "Received counts new reports; closed counts transitions into closed, including reports received before this window. Partial months are included.",
  chartSubtitle4: "Currently closed reports received in this window",
  chartDefinition4:
    "The gauge shows the closed share, not an SLA target. Duration bins use receipt to latest closure; reopened reports are excluded until closed again.",
  chartSubtitle5: "Current workflow state · click a cell for its queue",
  chartDefinition5:
    "Counts the current statuses of reports received in this window. Status indicates workflow, not severity or a security conclusion.",
  chartSubtitle6: "Historical state at the end of each plotted bucket",
  chartDefinition6:
    "Includes all matching reports received by each snapshot, even before this reporting window. Closed is an administrative status; reopening moves a report back to open.",
  policyCitations: "Policy citations:",
  severity: "AI-assigned severity:",
  notAvailable: "not available in this stage",
  adminActions: "Administrator actions · Demo administrator",
  newStatus: "New status",
  saveStatus: "Save status",
  responsibleTeam: "Responsible team",
  reviewer: "Reviewer",
  saveAssignment: "Save assignment",
  adminNote: "Administrator note",
  addNote: "Add note",
  escalationDecision: "Escalation decision",
  escalateForReview: "Escalate for review",
  doNotEscalate: "Do not escalate",
  decisionReason: "Decision reason",
  reviewEscalation: "Review escalation decision",
  decisionAudited: "This decision will be persisted and audited.",
  dashboard: "Dashboard",
  allReports: "All reports",
  inReview: "In review",
  escalations: "Escalations",
  closed: "Closed",
  language: "Language",
  appearance: "Appearance",
  light: "Light",
  dark: "Dark",
  system: "System",
  reportQueue: "Report queue",
  status: "Status",
  incidentType: "Incident type",
  allStatuses: "All statuses",
  allOpen: "All open",
  allTypes: "All types",
  refreshQueue: "Refresh queue",
  viewReports: "View reports",
  reportsReview: "Reports requiring review",
  loadingReports: "Loading reports…",
  emptyReports: "No reports match these filters.",
  clearFilters: "Clear filters",
  submitted: "Submitted",
  awaitingEmployee: "Awaiting employee",
  ticketReceived: "Ticket / received",
  type: "Type",
  assignment: "Assignment",
  elapsed: "Elapsed",
  unassigned: "Unassigned",
  noReviewer: "No reviewer",
  analytics: "Incident analytics",
  reportingWindow: "Reporting window",
  last30: "Last 30 days",
  last90: "Last 90 days",
  last180: "Last 180 days",
  incidentCategory: "Incident category",
  allIncidentTypes: "All incident types",
  reportsReceived: "Reports received",
  stillOpen: "Still open",
  currentlyClosed: "Currently closed",
  meanClose: "Mean time to close",
  incomingReports: "Incoming reports",
  incidentMix: "Incident mix",
  receivedClosed: "Received vs closed",
  closureTurnaround: "Closure & turnaround",
  statusByType: "Status by incident type",
  openClosedWorkload: "Open & closed workload",
  supportCall: "Support call",
  suspiciousMessage: "Suspicious message",
  mistakenReport: "Mistaken report",
  other: "Other",
  security: "Security",
  dataProtection: "Data protection",
  escalated: "Escalated",
  viewValues: "View values & definitions",
  ticketJourney: "Ticket journey",
  noAudit: "No audit events available.",
  reportDetail: "Report detail",
  refreshDetail: "Refresh detail",
  employeeStatements: "Employee statements",
  reportLanguage: "Report language",
  appName: "App name",
  evidenceNotes: "Evidence notes",
  notSupplied: "Not supplied",
  deviceObservations: "Device observations",
  noChecks: "No automatic checks supplied.",
  cancel: "Cancel",
  confirmDecision: "Confirm decision",
  confirmEscalation: "Confirm escalation decision",
} as const;
export type TranslationKey = keyof typeof en;
// A missing translation always falls back to English.
const dictionaries: Record<
  Language,
  Partial<Record<TranslationKey, string>>
> = {
  en,
  hi,
  ta: {
    syntheticData: "செயற்கை விளக்கத் தரவு",
    localApiHistory: "உள்ளூர் API-இன் அறிக்கைகள் மற்றும் தணிக்கை வரலாறு",
    dashboardIncidentType: "முகப்புப் பலகை சம்பவ வகை",
    loadingAnalytics: "அறிக்கை பகுப்பாய்வு ஏற்றப்படுகிறது…",
    analyticsUnavailable: "பகுப்பாய்வு கிடைக்கவில்லை. மீண்டும் முயற்சிக்க வரிசையைப் புதுப்பிக்கவும்.",
    brushWeeks: "வாரங்களைத் தேர்ந்தெடு",
    brushFromWeek: "தொடக்க வாரம்",
    brushThroughWeek: "இறுதி வாரம்",
    from: "முதல்",
    through: "வரை",
    clearBrush: "தேர்வை நீக்கு",
    dragBrushHint: "வார விளக்கப்படத்தில் இழுக்கவும் அல்லது வாரங்களைத் தேர்ந்தெடுக்கவும். மொத்த எண்ணிக்கை மாறாது.",
    viewReceived: "பெறப்பட்ட அறிக்கைகளைக் காண்க",
    viewOpen: "திறந்துள்ள அறிக்கைகளைக் காண்க",
    viewClosed: "மூடப்பட்ட அறிக்கைகளைக் காண்க",
    viewClosureTime: "முடிவு நேரத்தில் சேர்க்கப்பட்ட அறிக்கைகளைக் காண்க",
    noPreviousBaseline: "முந்தைய கால அடிப்படை இல்லை",
    medianTurnaround: "இடைநிலை செயலாக்க நேரம்",
    fewer: "குறைவு",
    moreReports: "அதிக அறிக்கைகள்",
    responsibilityCohort: "இந்தக் குழுவின் பொறுப்புகள்",
    assignmentIdentityNote: "குழு ஒதுக்கீடு பணியாளர் அடையாளத்திலிருந்து தனியானது.",
    chartSubtitle1: "தொடர்ச்சியான ஏழு நாள் காலப்பகுதிகளில் புதிய அறிக்கைகள்",
    chartDefinition1:
      "தேர்ந்தெடுத்த காலப்பகுதியில் பெறப்பட்ட நேரத்தின் அடிப்படையில் அறிக்கைகளை எண்ணுகிறது. இறுதிக் காலப்பகுதி ஏழு நாட்களுக்குக் குறைவாக இருக்கலாம்.",
    chartSubtitle2: "பணியாளர் தேர்ந்தெடுத்த வகைகள் · வடிகட்ட கிளிக் செய்யவும்",
    chartDefinition2:
      "ஒவ்வொரு அறிக்கையும் ஒரு வகையில் மட்டும் இடம்பெறும். தேர்ந்தெடுத்த காலத்தில் பெறப்பட்ட அறிக்கைகளின் அடிப்படையில் சதவீதங்கள் கணக்கிடப்படுகின்றன.",
    chartSubtitle3: "இந்தக் காலப்பகுதியில் காலண்டர் மாத வாரியான செயல்பாடு",
    chartDefinition3:
      "பெறப்பட்டவை புதிய அறிக்கைகளைக் கணக்கிடுகின்றன; மூடப்பட்டவை இந்தக் காலத்திற்கு முன் பெறப்பட்ட அறிக்கைகள் உட்பட மூடப்பட்ட நிலைக்கு மாறிய நிகழ்வுகளைக் கணக்கிடுகின்றன. பகுதி மாதங்களும் சேர்க்கப்பட்டுள்ளன.",
    chartSubtitle4: "இந்தக் காலத்தில் பெறப்பட்டு தற்போது மூடப்பட்ட அறிக்கைகள்",
    chartDefinition4:
      "அளவுகோல் மூடப்பட்ட பங்கைக் காட்டுகிறது; இது சேவை நிலை இலக்கு அல்ல. பெறப்பட்ட நேரத்திலிருந்து அண்மைய முடிவு வரையிலான காலம் பயன்படுத்தப்படுகிறது; மீண்டும் திறக்கப்பட்ட அறிக்கைகள் மீண்டும் மூடப்படும் வரை சேர்க்கப்படாது.",
    chartSubtitle5:
      "தற்போதைய பணிப்பாய்வு நிலை · வரிசையைக் காண கலத்தைக் கிளிக் செய்யவும்",
    chartDefinition5:
      "இந்தக் காலத்தில் பெறப்பட்ட அறிக்கைகளின் தற்போதைய நிலைகளை எண்ணுகிறது. நிலை பணிப்பாய்வைக் குறிக்கிறது; தீவிரத்தையோ பாதுகாப்பு முடிவையோ அல்ல.",
    chartSubtitle6: "ஒவ்வொரு காட்டப்பட்ட காலப்பகுதியின் முடிவிலும் இருந்த நிலை",
    chartDefinition6:
      "அறிக்கைக் காலத்திற்கு முன் பெறப்பட்டவை உட்பட, ஒவ்வொரு நேரப் பதிவிற்குள் பெறப்பட்ட பொருந்தும் அறிக்கைகள் அனைத்தும் அடங்கும். மூடப்பட்டது நிர்வாக நிலை; மீண்டும் திறப்பது அறிக்கையைத் திறந்த நிலைக்கு மாற்றும்.",
    policyCitations: "கொள்கை மேற்கோள்கள்:",
    severity: "AI ஒதுக்கிய தீவிரம்:",
    notAvailable: "இந்த நிலையில் கிடைக்காது",
    adminActions: "நிர்வாகி செயல்கள் · மாதிரி நிர்வாகி",
    newStatus: "புதிய நிலை",
    saveStatus: "நிலையைச் சேமி",
    responsibleTeam: "பொறுப்புக் குழு",
    reviewer: "மதிப்பாய்வாளர்",
    saveAssignment: "ஒதுக்கீட்டைச் சேமி",
    adminNote: "நிர்வாகி குறிப்பு",
    addNote: "குறிப்பைச் சேர்",
    escalationDecision: "மேலாய்வு முடிவு",
    escalateForReview: "மதிப்பாய்வுக்கு அனுப்பு",
    doNotEscalate: "மேலாய்வுக்கு அனுப்ப வேண்டாம்",
    decisionReason: "முடிவுக்கான காரணம்",
    reviewEscalation: "மேலாய்வு முடிவைச் சரிபார்",
    decisionAudited: "இந்த முடிவு சேமிக்கப்பட்டுத் தணிக்கையில் பதிவுசெய்யப்படும்.",
    viewValues: "மதிப்புகள் மற்றும் விளக்கங்களைக் காண்க",
    ticketJourney: "புகாரின் பயணம்",
    noAudit: "தணிக்கை நிகழ்வுகள் இல்லை.",
    reportDetail: "அறிக்கை விவரம்",
    refreshDetail: "விவரத்தைப் புதுப்பி",
    employeeStatements: "பணியாளர் தகவல்கள்",
    reportLanguage: "அறிக்கை மொழி",
    appName: "செயலியின் பெயர்",
    evidenceNotes: "ஆதாரக் குறிப்புகள்",
    notSupplied: "வழங்கப்படவில்லை",
    deviceObservations: "சாதனக் கண்காணிப்புகள்",
    noChecks: "தானியக்கச் சோதனைகள் வழங்கப்படவில்லை.",
    cancel: "ரத்துசெய்",
    confirmDecision: "முடிவை உறுதிசெய்",
    confirmEscalation: "மேலாய்வு முடிவை உறுதிசெய்",
    dashboard: "முகப்புப் பலகை",
    allReports: "அனைத்து அறிக்கைகள்",
    inReview: "மதிப்பாய்வில்",
    escalations: "மேலாய்வுகள்",
    closed: "மூடப்பட்டவை",
    language: "மொழி",
    appearance: "தோற்றம்",
    light: "வெளிச்சம்",
    dark: "இருள்",
    analytics: "சம்பவ பகுப்பாய்வு",
    reportingWindow: "அறிக்கைக் காலம்",
    last30: "கடந்த 30 நாட்கள்",
    last90: "கடந்த 90 நாட்கள்",
    last180: "கடந்த 180 நாட்கள்",
    incidentCategory: "சம்பவ வகை",
    allIncidentTypes: "அனைத்து சம்பவ வகைகள்",
    reportsReceived: "பெறப்பட்ட அறிக்கைகள்",
    stillOpen: "இன்னும் திறந்துள்ளவை",
    currentlyClosed: "தற்போது மூடப்பட்டவை",
    meanClose: "மூடுவதற்கான சராசரி நேரம்",
    incomingReports: "வரும் அறிக்கைகள்",
    incidentMix: "சம்பவ வகைகள்",
    receivedClosed: "பெறப்பட்டவை மற்றும் மூடப்பட்டவை",
    closureTurnaround: "முடிவு மற்றும் செயலாக்க நேரம்",
    statusByType: "சம்பவ வகை வாரியான நிலை",
    openClosedWorkload: "திறந்த மற்றும் மூடிய பணிச்சுமை",
    system: "சாதனம்",
    reportQueue: "அறிக்கை வரிசை",
    status: "நிலை",
    incidentType: "சம்பவ வகை",
    allStatuses: "அனைத்து நிலைகள்",
    allOpen: "திறந்தவை அனைத்தும்",
    allTypes: "அனைத்து வகைகள்",
    refreshQueue: "வரிசையைப் புதுப்பி",
    viewReports: "அறிக்கைகளைக் காண்க",
    reportsReview: "மதிப்பாய்வு தேவைப்படும் அறிக்கைகள்",
    loadingReports: "அறிக்கைகள் ஏற்றப்படுகின்றன…",
    emptyReports: "பொருந்தும் அறிக்கைகள் இல்லை.",
    clearFilters: "வடிகட்டிகளை நீக்கு",
    submitted: "சமர்ப்பிக்கப்பட்டது",
    awaitingEmployee: "பணியாளருக்காகக் காத்திருக்கிறது",
    ticketReceived: "புகார் / பெறப்பட்டது",
    type: "வகை",
    assignment: "ஒதுக்கீடு",
    elapsed: "கடந்த நேரம்",
    unassigned: "ஒதுக்கப்படவில்லை",
    noReviewer: "மதிப்பாய்வாளர் இல்லை",
    supportCall: "ஆதரவு அழைப்பு",
    suspiciousMessage: "சந்தேகத்திற்குரிய செய்தி",
    mistakenReport: "தவறான அறிக்கை",
    other: "மற்றவை",
    security: "பாதுகாப்பு",
    dataProtection: "தரவு பாதுகாப்பு",
    escalated: "மேலாய்வுக்கு அனுப்பப்பட்டது",
  },
  te,
  bn,
  kn,
  ml,
  ur,
  pa,
};
type Overrides = Partial<
  Record<Language, Partial<Record<TranslationKey, string>>>
>;
type ContextValue = {
  locale: Language;
  setLocale: (locale: Language) => void;
  t: (key: TranslationKey) => string;
};
const defaultContext: ContextValue = {
  locale: "en",
  setLocale: () => {},
  t: (key) => en[key],
};
const Context = createContext(defaultContext);
const storageGet = (key: string) => {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
};
const storageSet = (key: string, value: string) => {
  try {
    localStorage.setItem(key, value);
  } catch {
    /* in-memory fallback */
  }
};
function parseOverrides(
  input: string,
): Partial<Record<TranslationKey, string>> | null {
  try {
    const parsed: unknown = JSON.parse(input);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
      return null;
    const result: Partial<Record<TranslationKey, string>> = {};
    for (const [name, value] of Object.entries(parsed)) {
      if (name.startsWith("@")) continue;
      // Admin keys share the mobile Remote Config parameters without collision.
      if (!name.startsWith("admin_")) continue;
      const key = name.slice(6) as TranslationKey;
      if (!Object.hasOwn(en, key)) continue;
      if (typeof value !== "string") return null;
      result[key] = value;
    }
    return result;
  } catch {
    return null;
  }
}
const cacheKey = (locale: Language) => `anuvach-admin-arb-${locale}`;
export function LocalizationProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Language>(() => {
    const saved = storageGet("anuvach-admin-language");
    return saved && Object.hasOwn(languages, saved)
      ? (saved as Language)
      : "en";
  });
  const [overrides, setOverrides] = useState<Overrides>(() =>
    Object.fromEntries(
      (Object.keys(languages) as Language[]).map((lang) => [
        lang,
        parseOverrides(storageGet(cacheKey(lang)) || "{}") ?? {},
      ]),
    ),
  );
  useLayoutEffect(() => {
    document.documentElement.lang = locale;
    document.documentElement.dir = locale === "ur" ? "rtl" : "ltr";
    storageSet("anuvach-admin-language", locale);
  }, [locale]);
  useEffect(() => {
    let disposed = false;
    async function fetchOverrides() {
      try {
        const [
          { initializeApp, getApps, getApp },
          { getRemoteConfig, isSupported, fetchAndActivate, getString },
        ] = await Promise.all([
          import("firebase/app"),
          import("firebase/remote-config"),
        ]);
        if (!(await isSupported()) || disposed) return;
        const app = getApps().length
          ? getApp()
          : initializeApp({
              apiKey: "AIzaSyBSc3X4cQvO332JizmcVj_wjbsLABLadZQ",
              authDomain: "anuvachai.firebaseapp.com",
              projectId: "anuvachai",
              appId: "1:425459156696:web:b7f8faf7e72995dc7579ad",
              messagingSenderId: "425459156696",
            });
        const config = getRemoteConfig(app);
        config.settings.minimumFetchIntervalMillis = 12 * 60 * 60 * 1000;
        await fetchAndActivate(config);
        if (disposed) return;
        const updates: Overrides = {};
        for (const lang of Object.keys(languages) as Language[]) {
          const raw = getString(config, `arb_overrides_${lang}`);
          if (!raw) continue;
          const parsed = parseOverrides(raw);
          if (parsed === null) continue;
          updates[lang] = parsed;
          storageSet(cacheKey(lang), raw);
        }
        setOverrides((current) => ({ ...current, ...updates }));
      } catch {
        /* Keep cached or compiled translations while offline. */
      }
    }
    void fetchOverrides();
    return () => {
      disposed = true;
    };
  }, []);
  const value = useMemo<ContextValue>(
    () => ({
      locale,
      setLocale: setLocaleState,
      t: (key) =>
        overrides[locale]?.[key] ?? dictionaries[locale][key] ?? en[key],
    }),
    [locale, overrides],
  );
  return <Context.Provider value={value}>{children}</Context.Provider>;
}
const enumKeys: Record<string, TranslationKey> = {
  support_call: "supportCall",
  suspicious_message: "suspiciousMessage",
  mistaken_report: "mistakenReport",
  other: "other",
  submitted: "submitted",
  in_review: "inReview",
  awaiting_employee: "awaitingEmployee",
  escalated: "escalated",
  closed: "closed",
  security: "security",
  data_protection: "dataProtection",
  unassigned: "unassigned",
};
export function useLocalization() {
  const context = useContext(Context);
  return {
    ...context,
    enumLabel: (value: string) =>
      Object.hasOwn(enumKeys, value) ? context.t(enumKeys[value]) : value,
  };
}
export function LanguagePicker() {
  const { locale, setLocale, t } = useLocalization();
  return (
    <label className="theme-picker language-picker">
      {t("language")}
      <select
        aria-label={t("language")}
        value={locale}
        onChange={(event) => setLocale(event.target.value as Language)}
      >
        {Object.entries(languages).map(([code, name]) => (
          <option key={code} value={code}>
            {name}
          </option>
        ))}
      </select>
    </label>
  );
}
