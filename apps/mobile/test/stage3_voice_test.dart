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
    final sockets = <VoiceSocketFixture>[];
    final languages = <String?>[];
    final api = Api(
      token: () async => 'fixture-token',
      voiceConnector: (uri, headers) async {
        expect(uri.path, '/api/v1/reporting/voice/stream');
        expect(headers['Authorization'], 'Bearer fixture-token');
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
            useStatement: used.add,
          ),
        ),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    final socket = sockets.single;
    await messenger.handlePlatformMessage(
      LocalFeatures.channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('voicePcm', Uint8List(640)),
      ),
      (_) {},
    );
    expect(socket.sent.single, hasLength(640));
    socket.emit({
      'type': 'audio',
      'data': 'AAAAAA==',
      'mime_type': 'audio/pcm;rate=24000',
    });
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
    expect(find.text('Use in draft'), findsOneWidget);
    expect(used, isEmpty);
    await socket.close();
    await tester.pump();
    expect(find.textContaining('Voice disconnected'), findsOneWidget);
    expect(calls, contains('stopMic'));
    await tester.tap(find.text('Use in draft'));
    expect(used, ['ஒருவர் ExampleApp குறியீட்டைக் கேட்டார்.']);
    await tester.tap(find.text('Start voice'));
    await tester.pump();
    expect(languages, ['ta', 'ta']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
