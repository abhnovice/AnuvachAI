# Remote translations

Flutter's generated ARB localizations remain the offline source of truth.
The custom delegate is placed first in MaterialApp.localizationsDelegates;
Flutter resolves the first delegate of each type. Existing
`AppLocalizations.of(context)!.check` calls remain unchanged.

The app loads cached override maps for all nine supported languages from shared_preferences
before the first frame, then initializes Firebase and fetches in the background.
Compiled ARB translations provide the offline fallback. Each valid parameter is cached
independently. Invalid JSON or network failures leave the last valid cache in
place. Publish `{}` to deliberately clear a locale's overrides.

In Firebase Remote Config create string parameters named `arb_overrides_<locale>`,
for example `arb_overrides_en`, `arb_overrides_hi`, and `arb_overrides_ta`. For example, publish this value for the Hindi parameter:

```json
{
  "check": "जाँचें",
  "welcomeName": "नमस्ते, {name}",
  "reportCount": "{count, plural, =0{कोई रिपोर्ट नहीं} one{# रिपोर्ट} other{# रिपोर्ट}}"
}
```

Full ARB JSON may also be used; metadata keys beginning with `@` are ignored.
Only generated keys have an effect. When adding an ARB key, run
`flutter gen-l10n` and add its forwarding getter or method to
`RemoteAppLocalizations`; Dart compilation will flag any missing overrides.
Parameterized messages currently support `welcomeName` and `reportCount`.
The plural formatter supports cardinal forms, integer exact selectors, {count},
and #; nested ICU messages, offsets, and apostrophe escaping are not supported
and fall back to the compiled value. Do not publish secrets in Remote Config.

The debug-only translate button triggers a fetch with a zero minimum interval.
Normal fetches use a 12-hour minimum interval and Firebase may throttle requests.
Publishing a template is required before a device can fetch it. No live listener
is registered; updates appear after a startup or debug-button fetch.

To set up another Firebase project, run `flutterfire configure` in
`apps/mobile`, then `flutter pub get` and rebuild the app. iOS builds require
macOS and Xcode. Firebase client configuration identifies the app and is not a
secret, but all remotely fetched values are visible to clients.
