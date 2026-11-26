import 'package:anuvach_mobile/l10n/app_localizations_en.dart';
import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:anuvach_mobile/remote_app_localizations.dart';
import 'package:anuvach_mobile/remote_localization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cached overrides load synchronously and metadata is ignored', () async {
    SharedPreferences.setMockInitialValues({
      'arb_overrides_hi': '{"check":"जांचें","@check":{}}',
      'arb_overrides_ta': '{"check":"சோதனை"}',
    });
    final service = RemoteLocalizationService(
      await SharedPreferences.getInstance(),
    );
    expect(service.overrides['hi'], {'check': 'जांचें'});
    expect(service.overrides['ta'], {'check': 'சோதனை'});
    service.dispose();
  });
  testWidgets('delegate reload updates the existing localized widget', (
    tester,
  ) async {
    Widget app(String value, int revision) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        RemoteAppLocalizationsDelegate({
          'en': {'check': value},
        }, revision),
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Text(
          AppLocalizations.of(context)!.check,
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    await tester.pumpWidget(app('First', 1));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    await tester.pumpWidget(app('Updated', 2));
    await tester.pumpAndSettle();
    expect(find.text('Updated'), findsOneWidget);
  });
  test('overrides, placeholder, plural and invalid fallback', () {
    final base = AppLocalizationsEn();
    final strings = RemoteAppLocalizations(base, {
      'check': 'Inspect',
      'welcomeName': 'Welcome {name}',
      'reportCount': '{count, plural, =0{None} one{# item} other{# items}}',
    });
    expect(strings.check, 'Inspect');
    expect(strings.apps, base.apps);
    expect(strings.welcomeName('A'), 'Welcome A');
    expect(strings.reportCount(0), 'None');
    expect(strings.reportCount(1), '1 item');
    expect(strings.reportCount(3), '3 items');
    final invalid = RemoteAppLocalizations(base, {'reportCount': '{bad}'});
    expect(invalid.reportCount(3), base.reportCount(3));
  });
}
