# Platform limitations

The report form's optional device review reads KeyguardManager.isDeviceSecure (API 23+), recording what was checked and when. It does not establish remote access, compromise or historical permission use. Separately, the Access tab queries launcher apps visible under Android package-visibility rules and shows package name, version and requested-permission grant states. It is not a complete device inventory, and a grant does not prove use. The scan is initiated by the user and stays on the device.

Reference: [Android KeyguardManager](<https://developer.android.com/reference/android/app/KeyguardManager#isDeviceSecure()>).

Android settings opens ACTION_APPLICATION_DETAILS_SETTINGS for this app. It does not change permissions or settings. The debug manifest permits local cleartext HTTP. Ordinary release builds disable it; `npm run build:mobile` explicitly enables it when building for an HTTP demo API. Optimized demo APKs retain debug-key signing; production release signing is not configured.

iOS uses manual guidance for device review and does not expose an inventory of other apps or their permissions. No automatic observation is manufactured. A Swift channel opens the app's Settings page with UIApplication.openSettingsURLString; opening may fail and is reported. A separate debug Info.plist permits local HTTP and includes a local-network explanation. Release/profile retain the normal transport policy.

The Check microphone button requests access on demand and starts a local microphone session without saving, uploading, transcribing or analysing audio. It stops when the tab is disposed or the app loses focus. Chat entries remain in memory and do not generate reports. There is no Gemini connection.

This Linux machine cannot validate Xcode compilation, simulator behavior, signing or physical iOS settings/network prompts. These remain pending on macOS with Xcode.

Draft preferences and SQLite are unencrypted. No real identifiers, passwords, codes, recordings or evidence attachments should be entered. Evidence is text notes only. The new navigation, Check and Access controls have translations for nine languages, but the existing consent, report and some platform guidance remain in English. The separate report-language field is metadata and does not translate text.

All identities, roles and reviewer names are synthetic. CORS is a development browser boundary, not an access control. No claims of policy compliance, automated triage or AI security conclusions are made.

Accessibility uses semantic Material controls, standard touch targets, explicit labels and scrollable layouts. React supports labelled inputs and visible keyboard focus. Screen-reader, extreme text scaling and physical-device audits still need human validation.
