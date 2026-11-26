import 'package:anuvach_mobile/language.dart';
import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('locale switches live, persists, and mirrors Urdu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = LocaleController(prefs);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          locale: controller.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final strings = AppLocalizations.of(context)!;
              return Column(
                children: [
                  Text(strings.check),
                  Text(strings.welcomeName('Sam')),
                  Text(strings.reportCount(2)),
                  Text(Directionality.of(context).name),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('ltr'), findsOneWidget);
    expect(await controller.setLanguage('hi'), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('जाँच'), findsOneWidget);
    expect(await controller.setLanguage('ur'), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('rtl'), findsOneWidget);
    expect(LocaleController(prefs).locale.languageCode, 'ur');
    expect(await controller.setLanguage('invalid'), isFalse);
    expect(controller.locale.languageCode, 'ur');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
