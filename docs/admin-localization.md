# Admin dashboard localization

The language picker persists the selected language in browser localStorage.
The dashboard has nine selectable languages and sets Urdu text direction to RTL.
The navigation and appearance controls have translations for all nine; queue
controls, category labels, metric headings and chart titles additionally have Tamil translations.
Other dashboard, chart, report detail and help text remains English and requires migration.

A Firebase web app named “Anuvach Admin” is registered in project `anuvachai`.
The modular Firebase SDK fetches `arb_overrides_<locale>` for all nine supported locales
after the first render. Browser localStorage holds the last valid payload, so
cached translations are available immediately. It falls back to compiled values
if the browser disallows storage, Remote Config is unavailable, or JSON is
invalid. Fetches use
Firebase's 12-hour minimum interval.

The same Remote Config parameters are shared with mobile. Admin keys start with
`admin_` so they do not interfere with mobile values. Keep existing mobile
keys when editing a parameter. For example:

```json
{
  "check": "जाँचें",
  "admin_dashboard": "सुरक्षा डैशबोर्ड",
  "admin_allReports": "सभी रिपोर्ट",
  "admin_closed": "बंद"
}
```

Metadata keys starting with `@` and unknown keys are ignored. A published
empty object clears the overrides for that locale. The current website keys are
plain strings; ICU plural and placeholder interpolation have not been added.
Remote Config values are visible to clients and must never contain secrets.
Use Firebase console conditions if targeting only specific app installations.
