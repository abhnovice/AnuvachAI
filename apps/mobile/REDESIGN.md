# Employee app redesign

Starting commit: `7c24f6eaf7401a6742d09e50ebc58eedcdcd3f56`

| Screen | Presentation | Existing behavior |
| --- | --- | --- |
| Disclosure | Short, readable sections and a clear consent action | Consent is recorded only when Continue is pressed. |
| Check | Welcoming empty state, distinct turns, compact voice and text composer | Text and supported voice share the conversation. Captured speech stays editable and “Use in report” opens the draft. |
| Draft | Employee statement first, visible category/language, expandable app and evidence fields | Existing draft recovery, validation and pending submission protection. Voice, agent assistance and separately consented device review remain reachable. |
| Review | Exact facts in their own section, separate confirmation area | Edit returns to the draft. Confirmation plus Submit is required. Failures keep the draft and retry key. |
| Reports and detail | Scannable rows, localized status and timestamps | Only the API acknowledges a new ticket. Existing refresh and history behavior remain in place. |
| Apps and settings | Existing controls on shared Material surfaces | Device actions, theme and language preferences retain their existing behavior. |

The theme, shared surfaces, composer layout, form layout and report presentation can change independently of API calls, consent, voice sessions and draft state.
