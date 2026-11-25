# Anuvach.AI

Employee incident reporting for Flutter Android/iOS and a React administrator desk, backed by a local SQLite API. **Synthetic demonstration data only. No authentication.**

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

Open http://localhost:5173. Vite proxies `/api` to http://127.0.0.1:3000. API defaults to loopback. SQLite defaults to `services/api/anuvach.sqlite` when started through the npm workspace scripts. Seed is repeatable and creates two synthetic cases, never duplicate seed tickets.

In a third terminal:

```bash
export PATH="$PWD/.tooling/flutter/bin:$PATH"
cd apps/mobile
flutter pub get
flutter devices
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
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
flutter build ios --simulator --debug
flutter run -d IOS_SIMULATOR_ID --dart-define=API_BASE_URL=http://localhost:3000
```

iOS native validation is pending on macOS with Xcode. Debug iOS builds use a separate plist for local HTTP; release/profile do not. Local network access on physical iOS may trigger the working feature's system prompt.

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
flutter build apk --debug
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
- [Your confirmation exercise](docs/confirmation-exercise.md)

No voice, transcript, policy retrieval, AI severity, triage, authentication provider, cloud deployment, Gemini, or AlloyDB is implemented. The logo is a replaceable placeholder. UI copy is English; report language supports English, Hindi and mixed.
