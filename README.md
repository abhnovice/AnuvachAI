# Anuvach.AI

A social engineering incident tracker that helps employees report suspicious human interactions and gives security teams a clear, auditable place to follow up.

An employee receives a call from someone claiming to be IT support. The caller asks them to install remote-access software or share a verification code. The employee is unsure whether the request was legitimate, but can record what happened without needing to diagnose the incident.

In Anuvach.AI, they describe the call, review the exact facts they intend to share, and explicitly confirm before a ticket is created. The security team sees the same ticket in its dashboard, reviews the employee's account alongside any optional device observation, and records an assignment, status update or escalation decision. The employee can return to the app to see the current status.

**This is an unauthenticated local demonstration for synthetic data only. Do not enter real employee information, passwords or verification codes.**

## The incident journey

1. **Notice and describe.** The employee chooses a category, writes what happened in English, Hindi or a mix, and optionally adds an app name or evidence notes. Suspicious calls, messages and mistaken reports can all be recorded.
2. **Review and confirm.** The app shows exactly what will be submitted. A ticket is created only after explicit confirmation; an unfinished draft is retained if the API is unavailable.
3. **Review the facts.** An administrator opens the queue and sees employee statements separately from any device observation. On Android, an optional, consented public API check reports whether a secure screen lock is configured; it does not establish that a permission was used or that a device was compromised. iOS provides manual guidance.
4. **Decide and follow up.** The administrator can assign a security or data-protection team, add notes, change status and explicitly confirm an escalation decision. Creation and administrator changes are recorded in an append-only local audit trail. The employee can refresh their report to see the updated status.

The dashboard uses synthetic scenarios and visualizes report volume, categories and workflow. A weekly brush highlights corresponding weeks and overlapping whole months; category hover links the mix and status matrix. The brush highlights data without changing totals.

## What is built

- **Employee app:** Flutter for Android and iOS, with reporting, confirmation, draft recovery, ticket history and an optional Android device review.
- **Administrator dashboard:** React, TypeScript and Vite, with an interactive overview, report queue, ticket journey and audited review actions.
- **Local API:** TypeScript and SQLite, with input validation, persistent reports and audit events. The seed provides two initial cases and 48 synthetic historical scenarios.

## Local Stage 3 agents

The Flutter report flow supports nine text languages and opt-in Android voice preview. Review and edit the report before confirming it. Fastify creates the ticket in SQLite and queues triage through the existing private A2A connection. In React, administrators can review and amend the evidence-linked AI proposal. The local integration uses synthetic incident data and keeps the Gemini credential in the agent service.

English passed the synthesized speech fixture and the live Fastify relay. Eight languages are voice-limited with text fallback. Android emulator audio I/O and the complete text-to-admin flow passed. Physical-device speech and listening have not been assessed. Policy answers remain unavailable pending Stage 4 RAG.

See the [local commands and configuration](services/agents/README.md#local-flutter-and-react-integration), [language matrix](docs/language-test-matrix.md), and [verification log](docs/experiment-log.md#stage-3-closeout-verification). The standalone workbench and deterministic synthetic triage fixture remain available.

## Repository layout

| Path           | Purpose                                            |
| -------------- | -------------------------------------------------- |
| `apps/mobile`  | Flutter employee app and Android/iOS projects      |
| `apps/admin`   | React administrator dashboard                      |
| `services/api` | Local TypeScript API and SQLite storage            |
| `docs`         | Architecture, API, platform limits and experiments |

## Toolchain

Validated versions and results are recorded in [the experiment log](docs/experiment-log.md). This workspace uses Node 26, npm 12, Flutter 3.38.5 / Dart 3.10.4, and Temurin JDK 17. Downloaded tools live in ignored `.tooling/`; they are not repository dependencies.

Reproduce the Linux tool installation from the repository root:

```bash
mkdir -p .tooling/jdk
curl -fL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.5-stable.tar.xz -o .tooling/flutter.tar.xz
sha256sum .tooling/flutter.tar.xz
# Expected: a264940cfc431c1778f34f7413fa6ab71443ad52c71f38c50b0284397a4039b0
tar -xf .tooling/flutter.tar.xz -C .tooling
curl -fL 'https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse' -o .tooling/jdk.tar.gz
tar -xf .tooling/jdk.tar.gz -C .tooling/jdk --strip-components=1
export PATH="$PWD/.tooling/flutter/bin:$PATH"
export JAVA_HOME="$PWD/.tooling/jdk"
flutter config --jdk-dir="$JAVA_HOME"
flutter doctor -v
```

Install Android SDK platforms/build tools requested by Gradle through Android Studio SDK Manager. Install Android command-line tools there if doctor reports them missing. Accept SDK licenses with `flutter doctor --android-licenses`. SDK/Gradle may download NDK and other build dependencies on the first build.

## Firebase configuration

For the admin dashboard, copy `apps/admin/.env.example` to
`apps/admin/.env.local` and populate the listed `VITE_FIREBASE_*` values.
CI must supply these variables before the Vite build. They are embedded in the
client bundle; keep the populated environment file out of Git.

Before running mobile builds, copy `apps/mobile/.env.firebase.example.json` to
`apps/mobile/.env.firebase.json` and fill every value from your existing Firebase
Android and iOS app configuration. Flutter reads these build-time environment
values via `--dart-define-from-file`; it does not load shell environment variables
automatically. The JSON example lists all required variable names.

Android also requires the matching local file at
`apps/mobile/android/app/google-services.json`. Retrieve it with
`npx -y firebase-tools@latest apps:sdkconfig ANDROID <APP_ID> --project <PROJECT_ID>`
and save the returned JSON there. These populated files and FlutterFire's local
`apps/mobile/firebase.json` metadata are ignored. Do not commit generated
configuration or service-account credentials.

In CI, restore these files from the CI secret store before building. The mobile
packaging script defaults to the local JSON; set `FIREBASE_CONFIG_FILE` to an
alternate absolute path or a path relative to the repository root. Direct Flutter
run/build commands must include `--dart-define-from-file=.env.firebase.json` from
`apps/mobile`.

Previously committed values remain in Git history. Review API-key restrictions
and replace exposed keys where necessary in the Firebase/Google Cloud project.
Build-time configuration can be extracted from distributed apps; Firebase client
keys are not a substitute for backend access controls. Never embed service-account
private keys in an app.

## Run locally

From the repository root:

```bash
npm ci
npm run seed
npm run dev:api
```

In a second terminal, from the root:

```bash
npm run dev:admin
```

Open http://localhost:5173. Vite proxies `/api` to http://127.0.0.1:3000. API defaults to loopback. SQLite defaults to `services/api/anuvach.sqlite` when started through the npm workspace scripts. Seed is repeatable: it preserves the original two synthetic cases and adds 48 historical demonstration scenarios. Re-running it does not duplicate fixtures or overwrite administrator edits.

In a third terminal:

```bash
export PATH="$PWD/.tooling/flutter/bin:$PATH"
cd apps/mobile
flutter pub get
flutter devices
flutter run --dart-define-from-file=.env.firebase.json --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Use `-d DEVICE_ID` if multiple devices are available.

| Target                      | API_BASE_URL              |
| --------------------------- | ------------------------- |
| Android emulator            | `http://10.0.2.2:3000`    |
| iOS simulator               | `http://localhost:3000`   |
| Physical Android/iOS device | `http://HOST_LAN_IP:3000` |

For a physical device on the same trusted network, start API with `HOST=0.0.0.0 npm run dev:api`, substitute your computer's LAN IP in the Flutter command, and permit inbound TCP 3000 in your host firewall. There is no access control: keep all data synthetic. An alternative for USB Android is `adb reverse tcp:3000 tcp:3000` and `API_BASE_URL=http://127.0.0.1:3000`.

On macOS install Flutter and Xcode, then run from `apps/mobile`:

```bash
flutter pub get
flutter build ios --simulator --debug --dart-define-from-file=.env.firebase.json
flutter run --dart-define-from-file=.env.firebase.json -d IOS_SIMULATOR_ID --dart-define=API_BASE_URL=http://localhost:3000
```

iOS native validation is pending on macOS with Xcode. Debug iOS builds use a separate plist for local HTTP; release/profile do not. Local network access on physical iOS may trigger the working feature's system prompt.

## Small Android APKs

Use release APKs for installation/sharing. Debug APKs include the development runtime and are much larger.

From the root:

```bash
npm run build:mobile
adb shell getprop ro.product.cpu.abi
adb install -r apps/mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Choose the matching artifact: `arm64-v8a` for most current Android phones, `armeabi-v7a` for older 32-bit ARM devices, or `x86_64` for the emulator used here. Each includes the complete app, theme and features. The command uses release compilation, shrinking and per-architecture packaging, and fails if any output exceeds 50 MB (50,000,000 bytes). Outputs are in `apps/mobile/build/app/outputs/flutter-apk/`.

The default API URL is the Android emulator's `http://10.0.2.2:3000`. For a physical device, build with:

```bash
API_BASE_URL=http://HOST_LAN_IP:3000 npm run build:mobile
```

The script explicitly enables local HTTP for an HTTP API URL; ordinary release builds keep cleartext disabled. These synthetic demo APKs retain the project's existing debug signing key. Production signing, HTTPS and access control must be configured before real deployment. `FLUTTER_BIN` can select a Flutter executable; otherwise the script uses the local SDK when present, then Flutter on PATH.

See [size measurements and verification](docs/size-optimization.md).

## Verify

From root:

```bash
npm run check
npm test
npm run build
npm run format:check
npm run test:live
```

`test:live` starts an isolated real API and temporary SQLite database on port 3101. It runs a Flutter widget flow and React DOM flow concurrently: employee fills/reviews/confirms; React finds that ticket and saves a status change; Flutter refreshes and displays it. It does not mock HTTP or SQLite. It runs on the host test runner, not on an emulator or real browser. Individual live tests skip during ordinary unit test runs.

From `apps/mobile` with Flutter on PATH:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env.firebase.json
```

Manual demonstration: accept welcome disclosure → report synthetic support call → optional consented device check → review → tick confirmation → submit → record ticket ID → refresh dashboard queue → open matching ID → save `in_review` → refresh mobile detail. Stop API while drafting to verify useful errors and draft recovery. A pending submission is locked to its reviewed payload until retry resolves it.

After the Android emulator has fully booted (`adb -s emulator-5554 shell getprop sys.boot_completed` prints `1`), run the native channel test from `apps/mobile`:

```bash
flutter test integration_test/device_review_test.dart -d emulator-5554
```

## Design and limitations

- [Architecture and access control](docs/architecture.md)
- [API and Stage 3 contracts](docs/api-contract.md)
- [Platform limitations](docs/platform-limitations.md)
- [Experiment log](docs/experiment-log.md)
- [Created file inventory](docs/file-inventory.md)
- [Dhalam-inspired UI refresh](docs/design-refresh.md)
- [Dashboard metrics and synthetic history](docs/dashboard-metrics.md)
- [Your confirmation exercise](docs/confirmation-exercise.md)

No voice, transcript, policy retrieval, AI severity, triage, authentication provider, cloud deployment, Gemini, or AlloyDB is implemented. The logo is a replaceable placeholder. UI copy is English; report language supports English, Hindi and mixed.
