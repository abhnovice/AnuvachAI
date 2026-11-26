import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:anuvach_mobile/main.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:anuvach_mobile/remote_app_localizations.dart';
import 'package:anuvach_mobile/remote_localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('cached Tamil overrides reach consent and report form', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'arb_overrides_ta':
          '{"consentContinue":"தொடர்க","describeIncident":"புதிய விவரம்"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final remote = RemoteLocalizationService(prefs);
    Widget app(Widget child) => MaterialApp(
      locale: const Locale('ta'),
      localizationsDelegates: [
        RemoteAppLocalizationsDelegate(remote.overrides, remote.revision),
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
    final api = Api(client: MockClient((_) async => http.Response('[]', 200)));
    await tester.pumpWidget(
      app(
        Home(
          prefs: prefs,
          api: api,
          language: 'ta',
          mode: ThemeMode.system,
          onLanguage: (_) {},
          onTheme: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('தொடர்க'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('தொடர்க'), findsOneWidget);
    final draft = Draft(prefs, api);
    await tester.pumpWidget(app(ReportForm(draft: draft)));
    await tester.pumpAndSettle();
    expect(find.text('புதிய விவரம்'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    draft.dispose();
    remote.dispose();
  });
}
