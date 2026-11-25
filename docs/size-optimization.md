# Size optimization — 2026-11-25

The UI, reporting behavior, charts, synthetic examples, native checks and full font coverage are retained. No new runtime dependencies were added.

## Android

Sizes are decimal MB, measured on disk after building:

| Artifact                                             |       Bytes |     MB |
| ---------------------------------------------------- | ----------: | -----: |
| Existing development debug APK (three architectures) | 185,128,524 | 185.13 |
| Optimized ARM 32-bit APK                             |  16,182,555 |  16.18 |
| Optimized ARM 64-bit APK                             |  18,587,885 |  18.59 |
| Optimized x86-64 APK                                 |  20,021,036 |  20.02 |

The large debug APK contained a 42.8 MB Dart kernel, a 11 MB isolate snapshot, debug Flutter engines for three architectures and Vulkan validation code. These are development overhead. Release compilation removes the Dart development payload and uses optimized engines; icon tree shaking reduces the Material icon font from 1,645,184 to 4,320 bytes. Explicit R8 code and resource shrinking uses the optimized Android default rules. There were no application-wide custom keep rules to remove. No AGP/R8 upgrade was needed.

A trial universal release APK was 50,528,510 bytes and correctly failed the 50,000,000-byte budget. The distribution command therefore produces one complete APK per architecture. All three supported architectures remain available; the device installs only its matching APK. Native libraries retain Android's normal direct-loading packaging rather than introducing extraction overhead to reduce the archive size.

Run `npm run build:mobile` from the root. The wrapper rejects any output over 50,000,000 bytes and prints actual sizes. It preserves the existing application ID and demo signing key, so `adb install -r` can update the existing demo without clearing its data. Normal debug builds remain available for development and are larger; share the release artifacts.

The demo API remains usable: the build wrapper sets the existing Dart API URL and explicitly opts into Android cleartext only for an HTTP API URL. Direct release builds default to cleartext disabled. This is still synthetic demo software with debug-key signing, not a production deployment.

## Website

| Production asset             | Before bytes | After bytes |
| ---------------------------- | -----------: | ----------: |
| Full variable Noto Sans font |    2,049,096 |     889,484 |
| JavaScript                   |      251,119 |     249,998 |
| CSS                          |       21,867 |      19,723 |

Converted the complete existing font to WOFF2 using `fonttools ttLib.woff2 compress`; no glyphs, scripts or variable weights were subsetted. Removed the redundant web TTF so Vite ships only WOFF2. The mobile font and both font licenses remain intact.

Removed unused legacy summary-card styles and a report-detail placeholder already hidden by the current layout whenever no ticket is selected. Kept the actual detail, loading, empty queue, error and stage-availability states. The production dashboard still has only React/ReactDOM as runtime dependencies, with its existing SVG charts. Tests and build tools remain development dependencies and do not ship as browser code.

## Verification

- `npm run check`, `npm test`, `npm run build`: passed.
- `npm run test:live`: passed the real Flutter review/confirmation → HTTP/SQLite → React status update → Flutter refresh path.
- Chromium before/after screenshots with fixed time and identical API responses: zero changed pixels for desktop queue/analytics, report detail, and 390px detail layout.
- Chromium interactive regression: all six charts, KPI/API reconciliation, reporting-window/category/status filters, data disclosures, narrow layout and no JavaScript errors passed.
- Release x86-64 APK installed over the debug app on the API-37 emulator, launched and loaded real API-backed history. Emulator-only software rendering was used as before; app rendering defaults were not changed.
- Built manifest confirms local-demo HTTP is enabled. Mobile Dart source and Kotlin/Swift behavior were not modified.
- iOS build validation remains pending on macOS with Xcode; this change does not alter iOS packaging.
