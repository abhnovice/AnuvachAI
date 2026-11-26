import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:anuvach_mobile/main.dart';
import 'package:anuvach_mobile/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'confirmation binds to review; offline retries retain payload and key across restart',
    () async {
      var calls = 0;
      String? key;
      final api = Api(
        client: MockClient((request) async {
          calls++;
          key ??= request.headers['idempotency-key'];
          expect(request.headers['idempotency-key'], key);
          if (calls == 1) throw Exception('offline');
          return http.Response(jsonEncode({'id': 'ANV-test'}), 201);
        }),
      );
      var draft = Draft(await SharedPreferences.getInstance(), api);
      draft.update('description', 'Synthetic IT caller asked for a code');
      draft.review();
      expect(calls, 0);
      await expectLater(draft.submit(), throwsStateError);
      draft.confirm(true);
      draft.update('description', 'Synthetic changed description');
      expect(draft.confirmed, false);
      await expectLater(draft.submit(), throwsStateError);
      draft.review();
      draft.confirm(true);
      await expectLater(draft.submit(), throwsException);
      expect(draft.locked, true);
      draft = Draft(await SharedPreferences.getInstance(), api);
      expect(draft.locked, true);
      expect(draft.confirmed, false);
      final original = draft.fields['description'];
      draft.update('description', 'Cannot change a pending submission');
      expect(draft.fields['description'], original);
      draft.review();
      draft.confirm(true);
      expect((await draft.submit())['id'], 'ANV-test');
      expect(calls, 2);
      expect(draft.prefs.getString('draft'), null);
    },
  );
  testWidgets(
    'review and cancellation do not submit; checkbox enables explicit submission',
    (tester) async {
      var calls = 0;
      final draft = Draft(
        await SharedPreferences.getInstance(),
        Api(
          client: MockClient((request) async {
            calls++;
            return http.Response('{}', 201);
          }),
        ),
      );
      draft.update('description', 'Synthetic suspicious support call');
      draft.review();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => Review(draft: draft)),
                ),
                child: const Text('Open review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Confirm and submit'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm and submit'),
            )
            .onPressed,
        null,
      );
      expect(calls, 0);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm and submit'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.scrollUntilVisible(
        find.text('Back to edit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Back to edit'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(draft.confirmed, false);
    },
  );
}
