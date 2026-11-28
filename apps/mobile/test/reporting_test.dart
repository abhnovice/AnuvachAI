import 'dart:async';
import 'dart:convert';
import 'package:anuvach_mobile/design.dart';
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
  test('voice fills an editable draft without submitting a ticket', () async {
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
    await draft.applyVoiceDraft({
      'description': 'Someone asked for a code over chat.',
      'app_name': 'ExampleApp',
      'evidence_notes': 'The employee has a screenshot.',
      'incident_type': 'suspicious_message',
      'unknowns': ['Sender identity'],
    }, 'ta');
    expect(draft.fields['incidentType'], 'suspicious_message');
    expect(draft.fields['language'], 'ta');
    expect(draft.fields['appName'], 'ExampleApp');
    expect(draft.fields['evidenceNotes'], 'The employee has a screenshot.');
    expect((draft.fields['reporting'] as Json)['unknowns'], [
      'Sender identity',
    ]);
    draft.review();
    await expectLater(draft.submit(), throwsStateError);
    expect(calls, 0);
  });
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
  testWidgets(
    'Check, Reports and Apps keep the conversation and draft reachable',
    (tester) async {
      SharedPreferences.setMockInitialValues({'consent': true});
      final prefs = await SharedPreferences.getInstance();
      final api = Api(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/turns')) {
            return http.Response('{"reply":"When did this happen?"}', 200);
          }
          expect(request.method, 'GET');
          return http.Response('[]', 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: anuvachTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Home(
            prefs: prefs,
            api: api,
            language: 'en',
            mode: ThemeMode.light,
            onLanguage: (_) {},
            onTheme: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      const statement = 'A synthetic caller asked for a code.';
      await tester.enterText(find.byType(TextField), statement);
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      final navigation = find.byType(NavigationBar);
      Future<void> select(String label) async {
        await tester.tap(
          find.descendant(of: navigation, matching: find.text(label)),
        );
        await tester.pumpAndSettle();
      }

      final pager = find.byType(PageView);
      await tester.drag(pager, const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(navigation).selectedIndex, 1);
      expect(find.text('No reports yet'), findsOneWidget);
      await tester.tap(find.text('Show reports'));
      await tester.pumpAndSettle();
      expect(find.text('No reports yet'), findsNothing);
      await tester.tap(find.text('Show reports'));
      await tester.pumpAndSettle();
      expect(find.text('No reports yet'), findsOneWidget);
      await tester.drag(pager, const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(navigation).selectedIndex, 2);
      await tester.drag(pager, const Offset(650, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(navigation).selectedIndex, 1);
      await select('Check');
      expect(find.text(statement), findsOneWidget);
      await tester.tap(find.text('Use in report'));
      await tester.pumpAndSettle();
      expect(find.text(statement), findsOneWidget);
      expect(Draft(prefs, api).fields['description'], statement);
    },
  );

  testWidgets(
    'Review saves the failed submission and shows an ID after acknowledgement',
    (tester) async {
      const statement = 'A synthetic support caller asked for a code.';
      final response = Completer<http.Response>();
      final requests = <http.Request>[];
      final prefs = await SharedPreferences.getInstance();
      final api = Api(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            requests.add(request);
            if (requests.length == 1) {
              return http.Response('{"error":"offline"}', 503);
            }
            return response.future;
          }
          return http.Response(
            jsonEncode({
              'id': 'ANV-ACK',
              'facts': {...jsonDecode(requests.last.body) as Json},
              'status': 'submitted',
              'createdAt': '2026-11-27T10:00:00Z',
              'updatedAt': '2026-11-27T10:00:00Z',
            }),
            200,
          );
        }),
      );
      final original = Draft(prefs, api)..update('description', statement);
      await original.save();
      final draft = Draft(prefs, api);
      await tester.pumpWidget(
        MaterialApp(
          theme: anuvachTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReportForm(draft: draft),
        ),
      );
      expect(find.text(statement), findsOneWidget);

      Future<void> reveal(Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          225,
          scrollable: find.byType(Scrollable).first,
        );
      }

      final review = find.text('Review report');
      await reveal(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(find.text(statement), findsOneWidget);
      final confirmation = find.byType(CheckboxListTile);
      final submit = find.widgetWithText(FilledButton, 'Confirm and submit');
      await reveal(submit);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(requests, isEmpty);
      await tester.ensureVisible(confirmation);
      await tester.tap(confirmation);
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.textContaining('Your draft is preserved'), findsOneWidget);
      expect(find.text('ANV-ACK'), findsNothing);
      expect(draft.locked, true);
      expect(Draft(prefs, api).fields['description'], statement);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(requests, hasLength(2));
      expect(
        requests.first.headers['idempotency-key'],
        requests.last.headers['idempotency-key'],
      );
      expect(requests.first.body, requests.last.body);
      expect(jsonDecode(requests.last.body)['confirmed'], true);
      expect(find.text('ANV-ACK'), findsNothing);

      response.complete(http.Response('{"id":"ANV-ACK"}', 201));
      await tester.pumpAndSettle();
      expect(find.text('ANV-ACK'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(prefs.getString('draft'), isNull);
    },
  );
  testWidgets(
    'Urdu review preserves the direction of each employee statement',
    (tester) async {
      const description = 'A synthetic caller asked for a code.';
      const evidence = 'کال کا ریکارڈ موجود ہے۔';
      final draft = Draft(await SharedPreferences.getInstance(), Api())
        ..update('description', description)
        ..update('evidenceNotes', evidence)
        ..review();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ur'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Review(draft: draft),
        ),
      );
      SelectableText value(String text) =>
          tester.widget(find.widgetWithText(SelectableText, text));
      expect(value(description).textDirection, TextDirection.ltr);
      expect(value(evidence).textDirection, TextDirection.rtl);
    },
  );
}
