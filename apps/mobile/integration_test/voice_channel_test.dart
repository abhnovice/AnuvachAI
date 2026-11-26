import 'dart:async';

import 'package:anuvach_mobile/local_features.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android microphone frames and playback channel', (tester) async {
    final channel = LocalFeatures.channel;
    final captured = Completer<Uint8List>();
    channel.setMethodCallHandler((call) async {
      if (call.method == 'voicePcm' && !captured.isCompleted) {
        captured.complete(call.arguments as Uint8List);
      }
    });
    try {
      expect(
        await channel.invokeMethod<bool>('startVoice', {'language': 'en'}),
        true,
      );
      final pcm = await captured.future.timeout(const Duration(seconds: 5));
      expect(pcm.length, inInclusiveRange(2, 3200));
      expect(pcm.length.isEven, true);
      final written = await channel.invokeMethod<int>('playVoice', {
        'pcm': Uint8List(2400),
        'rate': 24000,
      });
      expect(written, greaterThan(0));
      await channel.invokeMethod<void>('clearVoice');
    } finally {
      await channel.invokeMethod<void>('stopMic');
      channel.setMethodCallHandler(null);
    }
  });
}
