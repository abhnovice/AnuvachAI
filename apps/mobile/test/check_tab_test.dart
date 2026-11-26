import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anuvach_mobile/new_tabs.dart';
import 'package:anuvach_mobile/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ai.anuvach/local_features');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'startMic' ? true : null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  testWidgets('microphone starts only after tap and stops when leaving', (
    tester,
  ) async {
    final messages = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CheckTab(language: 'en', messages: messages),
        ),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(calls.where((e) => e == 'startMic').length, 1);
    expect(find.text('Microphone on · no audio saved or sent'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pump();
    expect(calls.last, 'stopMic');
  });
  testWidgets('chat messages stay in local shared session', (tester) async {
    final messages = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CheckTab(language: 'en', messages: messages),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Suspicious call');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(messages, ['Suspicious call']);
    expect(find.text('Suspicious call'), findsOneWidget);
  });
}
