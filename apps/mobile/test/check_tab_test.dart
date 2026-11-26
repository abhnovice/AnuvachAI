import 'voice_socket_fixture.dart';
import 'dart:convert';

import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:anuvach_mobile/new_tabs.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'Check sends a reporting turn and stages only an employee statement',
    (tester) async {
      final messages = <Json>[];
      final used = <String>[];
      final requests = <String>[];
      final api = Api(
        client: MockClient((request) async {
          requests.add(request.url.path);
          expect(jsonDecode(request.body)['language'], 'en');
          return http.Response(
            '{"reply":"When did the call happen?","unknowns":[]}',
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CheckTab(
              language: 'en',
              messages: messages,
              api: api,
              sessionId: 'c5a6866b-69ed-4d14-baf3-32d43093dfa0',
              reviewStatement: (statement) async {
                used.add(statement);
              },
            ),
          ),
        ),
      );
      expect(requests, isEmpty);
      await tester.enterText(find.byType(TextField), 'Suspicious call');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('When did the call happen?'), findsOneWidget);
      expect(messages.map((turn) => turn['speaker']), ['employee', 'agent']);
      expect(used, isEmpty);
      await tester.tap(find.text('Use in report'));
      await tester.pumpAndSettle();
      expect(used, ['Suspicious call']);
      expect(requests, ['/api/v1/reporting/turns']);
    },
  );

  testWidgets('Check microphone starts on demand and stops when leaving', (
    tester,
  ) async {
    const channel = MethodChannel('ai.anuvach/local_features');
    final calls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'startVoice' ? true : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final api = Api(voiceConnector: (_, _) async => VoiceSocketFixture());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CheckTab(
            language: 'en',
            messages: [],
            api: api,
            sessionId: 'c5a6866b-69ed-4d14-baf3-32d43093dfa0',
            reviewStatement: (_) async {},
          ),
        ),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    expect(calls, contains('startVoice'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, containsAllInOrder(['startVoice', 'stopMic', 'clearVoice']));
  });
}
