import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anuvach_mobile/main.dart';
import 'package:anuvach_mobile/reporting.dart';

void main() {
  testWidgets(
    'live Flutter draft -> confirmation -> API -> React -> mobile status',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});
      final api = Api(
        base: Platform.environment['LIVE_API_URL'] ?? 'http://127.0.0.1:3101',
      );
      final draft = Draft(await SharedPreferences.getInstance(), api);
      await tester.pumpWidget(MaterialApp(home: ReportForm(draft: draft)));
      await tester.enterText(
        find.byKey(const ValueKey('description')),
        'LIVE-E2E synthetic IT support call asked me to share a remote-access code.',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Review report'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirm and submit'));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm and submit'),
            )
            .onPressed,
        null,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Confirm and submit'));
      // Do not settle an animated loading indicator while real HTTP is pending:
      // settling would advance fake time to the repository's timeout.
      for (var i = 0; i < 60; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Report detail').evaluate().isNotEmpty &&
            find.text('Status: submitted').evaluate().isNotEmpty) {
          break;
        }
        if (find.text('Report detail').evaluate().isNotEmpty &&
            find.text('Status: in review').evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.text('Report detail'), findsOneWidget);
      await tester.runAsync(() async {
        for (var i = 0; i < 60; i++) {
          final rows = await api.history();
          if (rows.any(
            (r) =>
                r['facts']['description'].startsWith('LIVE-E2E') &&
                r['status'] == 'in_review',
          )) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        fail('React did not update the Flutter ticket.');
      });
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Refresh status'));
      for (
        var i = 0;
        i < 40 &&
            (find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
                find.text('Status: in review').evaluate().isEmpty);
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.text('Status: in review'),
        findsOneWidget,
        reason: tester.allWidgets
            .whereType<Text>()
            .map((w) => w.data)
            .join(' | '),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      api.client.close();
      await tester.pump();
      expect(tester.takeException(), null);
    },
    skip: !const bool.fromEnvironment('LIVE_E2E'),
  );
}
