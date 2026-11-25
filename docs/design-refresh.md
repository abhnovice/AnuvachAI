# Dhalam-inspired interface refresh

The visual reference is [Dhalam-Hack2Skill](https://github.com/abhnovice/Dhalam-Hack2Skill/tree/main), especially its phone screenshots in docs/interact-with-app and Flutter app_theme.dart. The shared direction is pale mint backgrounds, dark teal actions, Noto Sans, generously rounded outlined surfaces, pill buttons and a clear distinction between primary actions and supporting information.

Anuvach keeps its own copy, workflows and placeholder speech-bubble mark. Dhalam's logo, application code and AI/security claims were not imported.

## Shared visual language

- Canvas: #F4F9F7; foreground: #14211D; supporting text: #475952.
- Primary action: #006B60; highlighted surface: #B6F1E5; outline: #D4E0DB.
- Cards use approximately 26–28 pixel corner radii, thin outlines and minimal shadows.
- Noto Sans is bundled locally in both clients, with its SIL Open Font License included alongside the font. Runtime font downloads are unnecessary. Source: [Google Fonts Noto Sans](https://github.com/google/fonts/tree/main/ofl/notosans).

## Mobile

A calmer welcome groups disclosure into three readable rows. Home prioritises reporting with a mint feature card; Reports and Help have real bottom-navigation destinations. The form/review flow has a three-step indicator. Employee statements and device observations use separate cards; status labels use readable words rather than wire-format underscores.

Draft persistence, explicit confirmation, safe retries, consented native checks and the Stage 3 voice label remain intact. Home/history scroll positions are separate from the welcome page.

## Administrator desk

A sidebar provides working All reports, In review and Escalations views. The queue summary is computed from the currently filtered API data, without invented trends or risk scores. The report queue, selected detail, notes and actions share the mobile palette and typography.

The sidebar becomes horizontal navigation on narrow screens; queue tables scroll within their own container. Shortened ticket IDs visibly contain an ellipsis, with the full identifier in their accessible name, tooltip and report detail.

## Verification

Flutter analysis, confirmation/retry tests and the debug APK build passed. API/dashboard tests, TypeScript checking and the Vite production build passed. The real-HTTP/SQLite Flutter → React → Flutter test passed after its refresh waiter was corrected to await request completion even when the initial detail already contained the new status.

Chromium was used to inspect 1440px desktop and 390px narrow layouts, open report detail and verify sidebar filtering without horizontal page overflow or JavaScript errors. Android welcome and Home were inspected on the API-37 emulator. The emulator's graphics backend produced a black capture with Impeller; software rendering enabled visual inspection without changing application rendering defaults.

iOS native validation remains pending on macOS with Xcode.
