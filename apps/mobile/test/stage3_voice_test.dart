import 'dart:convert';

import 'package:anuvach_mobile/local_features.dart';
import 'package:anuvach_mobile/report_voice.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('voice preview, interruption, disconnect and restart', (
    tester,
  ) async {
    final calls = <String>[];
    final used = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(LocalFeatures.channel, (
      MethodCall call,
    ) async {
      calls.add(call.method);
      if (call.method == 'startVoice') return true;
      if (call.method == 'playVoice') {
        return (call.arguments['pcm'] as List).length;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(LocalFeatures.channel, null),
    );
    var starts = 0;
    var poll = 0;
    final api = Api(
      client: MockClient((request) async {
        if (request.method == 'DELETE') return http.Response('', 204);
        if (request.url.path.endsWith('/voice')) {
          starts++;
          return http.Response(jsonEncode({'id': 'session-$starts'}), 200);
        }
        final events = starts != 1
            ? []
            : switch (poll++) {
                0 => [
                  {
                    'type': 'audio',
                    'data': 'AAAAAA==',
                    'mime_type': 'audio/pcm;rate=24000',
                  },
                  {
                    'type': 'transcript',
                    'role': 'employee',
                    'text': 'discard partial',
                    'partial': true,
                  },
                ],
                1 => [
                  {'type': 'state', 'state': 'interrupted'},
                  {
                    'type': 'transcript',
                    'role': 'employee',
                    'text': 'A caller asked for a code.',
                    'partial': false,
                  },
                  {
                    'type': 'transcript',
                    'role': 'employee',
                    'text': 'A caller asked for a code.',
                    'partial': false,
                  },
                ],
                _ => [
                  {'type': 'error', 'message': 'closed'},
                ],
              };
        return http.Response(jsonEncode({'events': events}), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportVoice(
            api: api,
            language: 'en',
            enabled: true,
            useStatement: used.add,
          ),
        ),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    expect(calls, containsAllInOrder(['startVoice', 'playVoice']));
    expect(find.textContaining('Live preview:'), findsOneWidget);
    expect(find.text('Use in draft'), findsNothing);
    await tester.pump(const Duration(milliseconds: 70));
    expect(calls, containsAllInOrder(['playVoice', 'clearVoice']));
    expect(find.text('Use in draft'), findsOneWidget);
    expect(used, isEmpty);
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.textContaining('Voice disconnected'), findsOneWidget);
    expect(calls, contains('stopMic'));
    await tester.tap(find.text('Use in draft'));
    expect(used, ['A caller asked for a code.']);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    expect(starts, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
