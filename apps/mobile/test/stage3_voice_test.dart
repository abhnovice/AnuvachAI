import 'dart:convert';
import 'dart:typed_data';

import 'package:anuvach_mobile/local_features.dart';
import 'package:anuvach_mobile/report_voice.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'voice_socket_fixture.dart';

void main() {
  testWidgets('voice preview, interruption, disconnect and restart', (
    tester,
  ) async {
    final calls = <String>[];
    final used = <Json>[];
    final played = <int>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(LocalFeatures.channel, (
      MethodCall call,
    ) async {
      calls.add(call.method);
      if (call.method == 'startVoice') return true;
      if (call.method == 'playVoice') {
        played.add((call.arguments['pcm'] as Uint8List).length);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(LocalFeatures.channel, null),
    );
    final sockets = <VoiceSocketFixture>[];
    final languages = <String?>[];
    final api = Api(
      token: () async => 'fixture-token',
      voiceConnector: (uri, headers) async {
        expect(uri.path, '/api/v1/reporting/voice/stream');
        expect(headers['Authorization'], 'Bearer fixture-token');
        expect(uri.queryParameters['ticketDraft'], '1');
        languages.add(uri.queryParameters['language']);
        final connection = VoiceSocketFixture();
        sockets.add(connection);
        return connection;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportVoice(
            api: api,
            language: 'ta',
            enabled: true,
            reviewTicket: (draft, language) async {
              expect(language, 'ta');
              used.add(draft);
            },
          ),
        ),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    final socket = sockets.single;
    Future<void> native(String method, Object? arguments) async {
      await messenger.handlePlatformMessage(
        LocalFeatures.channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) {},
      );
    }

    final chunk = base64Encode(Uint8List(24000));
    for (var i = 0; i < 4; i++) {
      socket.emit({
        'type': 'audio',
        'data': chunk,
        'mime_type': 'audio/pcm;rate=24000',
      });
    }
    await tester.pump();
    expect(played, [24000, 24000, 24000, 24000]);
    await native('voicePlayback', true);
    await tester.pump();
    expect(find.text('Speaking'), findsOneWidget);
    await native('voicePcm', Uint8List(640));
    expect(socket.sent.single, hasLength(640));
    socket.emit({
      'type': 'transcript',
      'role': 'employee',
      'text': 'partial',
      'partial': true,
    });
    await tester.pump();
    expect(calls, containsAllInOrder(['startVoice', 'playVoice']));
    expect(find.textContaining('Live preview:'), findsOneWidget);
    expect(find.text('Use in draft'), findsNothing);
    socket.emit({'type': 'state', 'state': 'interrupted'});
    for (var i = 0; i < 2; i++) {
      socket.emit({
        'type': 'transcript',
        'role': 'employee',
        'text': 'ஒருவர் ExampleApp குறியீட்டைக் கேட்டார்.',
        'partial': false,
      });
    }
    await tester.pump();
    expect(calls, containsAllInOrder(['playVoice', 'clearVoice']));
    expect(find.text('Listening'), findsOneWidget);
    expect(find.text('Use in draft'), findsNothing);
    expect(find.text('Review ticket draft'), findsNothing);
    await native('voicePlaybackError', null);
    await tester.pump();
    expect(find.textContaining('Still listening'), findsOneWidget);
    await native('voicePcm', Uint8List(640));
    expect(socket.sent, hasLength(2));
    final proposal = {
      'description': 'ஒருவர் ExampleApp குறியீட்டைக் கேட்டார்.',
      'app_name': 'ExampleApp',
      'evidence_notes': '',
      'incident_type': 'support_call',
      'unknowns': <String>[],
    };
    socket.emit({'type': 'ticket_draft', 'draft': proposal});
    socket.emit({'type': 'ticket_draft', 'draft': proposal});
    await tester.pump();
    expect(find.text('Review ticket draft'), findsOneWidget);
    expect(used, isEmpty);
    await socket.close();
    await tester.pump();
    expect(find.textContaining('Voice disconnected'), findsOneWidget);
    expect(calls, contains('stopMic'));
    await tester.tap(find.text('Review ticket draft'));
    await tester.pump();
    expect(used, [proposal]);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    expect(languages, ['ta', 'ta']);
    final restarted = sockets.last;
    restarted.emit({
      'type': 'audio',
      'data': chunk,
      'mime_type': 'audio/pcm;rate=24000',
    });
    await tester.pump();
    await tester.tap(find.text('End voice'));
    await tester.pump();
    expect(restarted.sent.single, 'end');
    restarted.emit({'type': 'state', 'state': 'listening'});
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Finishing the voice turn…'), findsOneWidget);
    await native('voicePlayback', false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Start voice'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
