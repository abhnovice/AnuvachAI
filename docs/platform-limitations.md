# Platform limitations

Android device review uses a Dart interface and Kotlin MethodChannel. Only an explicitly consented check reads KeyguardManager.isDeviceSecure (API 23+), recording what was checked and the UTC time. It checks secure lock configuration, not whether the screen is currently locked, installed remote apps, accessibility use, compromise or historical permission use. No runtime permission is required. Failure/unavailability is shown without fabricating an observation.

Reference: [Android KeyguardManager](<https://developer.android.com/reference/android/app/KeyguardManager#isDeviceSecure()>).

Android settings opens ACTION_APPLICATION_DETAILS_SETTINGS for this app. It does not change permissions or settings. The debug manifest permits local cleartext HTTP. Ordinary release builds disable it; `npm run build:mobile` explicitly enables it when building for an HTTP demo API. Optimized demo APKs retain debug-key signing; production release signing is not configured.

iOS uses manual guidance for device review. No automatic observation is manufactured. A Swift channel opens the app's Settings page with UIApplication.openSettingsURLString; opening may fail and is reported. A separate debug Info.plist permits local HTTP and includes a local-network explanation. Release/profile retain the normal transport policy.

This Linux machine cannot validate Xcode compilation, simulator behavior, signing or physical iOS settings/network prompts. These remain pending on macOS with Xcode.

Draft preferences and SQLite are unencrypted. No real identifiers, passwords, codes, recordings or evidence attachments should be entered. Evidence is text notes only. UI language is English; the chosen reporting language is metadata and does not invoke translation.

All identities, roles and reviewer names are synthetic. CORS is a development browser boundary, not an access control. No claims of policy compliance, automated triage or AI security conclusions are made.

Accessibility uses semantic Material controls, standard touch targets, explicit labels and scrollable layouts. React supports labelled inputs and visible keyboard focus. Screen-reader, extreme text scaling and physical-device audits still need human validation.
