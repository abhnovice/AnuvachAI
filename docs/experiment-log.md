# Experiment log

## Environment and increments — 2026-11-25

Initial repository: IDE metadata only, no application files or commits. Node 26.13.0 and npm 12.2.2 available; Flutter/Dart/Java absent from PATH; Android SDK installed, no attached device.

Installed ignored workspace Flutter 3.38.5 (Dart 3.10.4) and Temurin JDK 17.0.21.1. Flutter archive SHA-256 matches the official release index: a264940cfc431c1778f34f7413fa6ab71443ad52c71f38c50b0284397a4039b0. Flutter's JDK setting now points at this local JDK.

1. API: implemented schema/version 1, validation, reports, assignment, notes, escalation, idempotency and transactional audit. Seed created two synthetic cases. Initial TypeScript test-helper type error corrected.
2. React: implemented queue/detail/workflow. TypeScript checks, API tests, React interaction test, API compilation and Vite build passed. npm installation reported zero vulnerabilities; npm 12 reported blocked optional esbuild postinstall, but builds/tests succeeded using installed platform packages.
3. Flutter: generated Android/iOS projects, reporting screens, persisted drafts and native device interface. Style issues corrected. Unit/widget tests passed (2 tests; live test skipped by default). Review cancellation sends nothing; edits invalidate confirmation; failed requests retain a frozen payload and key across restart.
4. Shared-API demonstration: `npm run test:live` passed. A real Flutter form/review/confirmation submitted via HTTP to an isolated SQLite-backed API; the real React component found its ticket and saved in_review; Flutter refreshed and rendered in_review. React ran in jsdom and Flutter in its host widget runner. This is not an emulator or browser visual test. Early test attempts failed because of scrolling and fake-clock settlement around real HTTP; corrected test frame handling and viewport configuration. Product timeouts remain enabled.
5. Android debug build: first build downloaded NDK 28.2.13676358, Build Tools 35, Android platform 36 and CMake 3.22.1 using existing accepted SDK licenses. Passed: generated build/app/outputs/flutter-apk/app-debug.apk (first build took approximately 12 minutes).
6. Headless API-37 emulator started successfully and appeared in adb. First native test install failed because the emulator was still booting. After sys.boot_completed returned 1, the same test passed: Kotlin returned an actual boolean secure-lock configuration through the Dart platform interface with source and UTC timestamp.

## Commands

| Command                                                                     | Result                                                                           |
| --------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `npm install`                                                               | Passed; root package-lock generated                                              |
| `npm run check`                                                             | Passed                                                                           |
| `npm test`                                                                  | Passed API and dashboard tests; opt-in live test skipped                         |
| `npm run build`                                                             | Passed API TypeScript compilation and Vite production build                      |
| `npm run seed`                                                              | Passed; two synthetic cases                                                      |
| `flutter pub get`                                                           | Passed; pubspec.lock generated                                                   |
| `flutter test`                                                              | Passed confirmation/retry tests                                                  |
| `npm run test:live`                                                         | Passed complete shared-API flow                                                  |
| `flutter doctor -v`                                                         | Reports missing Android command-line tools and Chrome; Linux cannot validate iOS |
| `flutter build apk --debug --project-dir=apps/mobile`                       | Failed: unsupported CLI option; corrected by running in apps/mobile              |
| `flutter build apk --debug`                                                 | Passed; debug APK generated                                                      |
| `flutter analyze`                                                           | Passed with no issues after final test style cleanup                             |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | Passed                                                                           |
| `flutter test integration_test/device_review_test.dart -d emulator-5554`    | Passed on API 37 after boot; initial attempt failed with device still booting    |
| `npm run format:check`                                                      | Passed                                                                           |
| iOS build                                                                   | Pending macOS with Xcode                                                         |

## Simulation and outstanding validation

Only demo identities, seeded narratives and placeholder branding are simulated. HTTP transport, report persistence, administrator changes and audit events are implemented. Voice, policy retrieval, AI severity and automated triage are inactive, with explicit UI labels.

iOS compilation, signing, device settings and local-network prompts need macOS/Xcode. Human screen-reader/text-scaling tests and production access controls remain outside this synthetic iteration. No real employee information was used.

## Interface refresh — 2026-11-25

Reworked mobile and dashboard around the supplied Dhalam reference: mint/teal tokens, bundled Noto Sans, rounded cards, mobile navigation and a sidebar-based administrator desk. See [design-refresh.md](design-refresh.md) for sources and decisions.

Flutter analysis, unit tests and APK build passed. API/dashboard tests, TypeScript checking and Vite build passed. The real shared-API flow passed after fixing an existing test race: a refresh request must finish even when an administrator update was already visible from the initial load. Browser checks covered desktop/narrow detail layouts, sidebar filters, no page overflow and no JavaScript errors. One early browser check incorrectly assumed the local in-review queue was empty; it was corrected to validate the filter against the actual synthetic data. Android welcome/Home were visually checked using software rendering on the emulator. Application rendering defaults and native check behavior were not changed.

## Distribution size audit — 2026-11-25

Inspected the existing 185,128,524-byte debug APK. Built architecture-specific optimized release APKs at 16.18 / 18.59 / 20.02 MB. A 50.53 MB universal release failed the strict 50 MB budget; the documented distribution script now builds separate architecture APKs and enforces the budget. Kept all architectures, app features, demo connectivity and existing signing identity. Removed the rejected universal build artifact.

Compressed the complete web font to WOFF2 (2,049,096 → 889,484 bytes) and removed obsolete summary styles and an already-hidden placeholder. Desktop/detail/narrow screenshots had zero changed pixels. TypeScript checks, API/dashboard tests, production builds, live shared-API flow and browser chart interactions passed. The release APK installed and loaded API history on the emulator. See [size-optimization.md](size-optimization.md) for measurements, commands and limitations.

## Visual incident analytics — 2026-11-25

Added the requested six-panel overview: incoming trend, incident mix, received/closed activity, closure/turnaround, status matrix and historical open/closed workload. Added UTC reporting windows, category drill-downs, queue pagination and assignment visibility. Preserved the existing theme and externally updated base stylesheet; chart styles live in separate files.

Added a computed dashboard endpoint and 48 historical synthetic cases without resetting the original cases or administrator edits. API tests passed for closure/reopening/no-op semantics, empty denominators, scope reconciliation, input validation and idempotent fixture seeding. Existing dashboard mutation and escalation-confirmation tests passed. Chromium verified six rendered charts, API/KPI agreement, filters, accessible values and a narrow layout without page overflow or JavaScript errors. See dashboard-metrics.md for definitions and fixture limitations.
