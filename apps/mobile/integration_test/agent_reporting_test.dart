import 'dart:io';

import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:anuvach_mobile/main.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Emulator reporting assistant, edit, confirmation and duplicate', (
    tester,
  ) async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    final api = Api();
    addTearDown(api.client.close);
    final draft = Draft(await SharedPreferences.getInstance(), api);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportForm(draft: draft),
      ),
    );

    Future<void> reveal(Finder finder, {double delta = 200}) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          delta,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
    }

    Future<void> tap(Finder finder) async {
      await reveal(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
    }

    final original =
        'STAGE3-ANDROID synthetic call ${DateTime.now().microsecondsSinceEpoch}. '
        'A caller claiming to be support asked for a pairing code.';
    final description = find.byKey(const ValueKey('description'));
    await tester.enterText(description, original);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(draft.fields['description'], original);
    await tap(find.text('Ask reporting assistant'));
    expect(
      draft.fields['reporting'],
      isNotNull,
      reason: 'The reporting button must start a turn',
    );
    for (var i = 0; i < 150 && draft.assisting; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    final transcript = draft.fields['reporting']['transcript'] as List;
    expect(
      transcript.last['speaker'],
      'agent',
      reason: tester.allWidgets
          .whereType<Text>()
          .map((widget) => widget.data)
          .join(' | '),
    );
    final agentReply = find.textContaining('Reporting assistant:');
    await reveal(agentReply);
    expect(agentReply, findsOneWidget);
    final edited =
        '$original I did not provide the code, and the time is unknown.';
    await reveal(description, delta: -200);
    await tester.tap(description);
    await tester.pump();
    // Deliver the same editing update as the IME after scrolling back.
    final editor = find.descendant(
      of: description,
      matching: find.byType(EditableText),
    );
    tester
        .state<EditableTextState>(editor)
        .updateEditingValue(
          TextEditingValue(
            text: edited,
            selection: TextSelection.collapsed(offset: edited.length),
          ),
        );
    await tester.pump();
    expect(draft.fields['description'], edited);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tap(find.text('Review report'));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Confirm and submit');
    await reveal(submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(
      (draft.reviewed!['reporting']['transcript'] as List).first['text'],
      original,
    );
    final key = draft.key;
    final payload = draft.reviewed!;
    expect(payload['description'], edited);
    await tap(find.byType(CheckboxListTile));
    await tap(submit);
    for (
      var i = 0;
      i < 90 && find.text('Report detail').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 300));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(find.text('Report detail'), findsOneWidget);
    final duplicate =
        await api.call('/reports', body: payload, key: key) as Json;
    final rows = await api.history();
    final matches = rows.where((row) => row['facts']['description'] == edited);
    expect(matches.length, 1);
    expect(matches.single['id'], duplicate['id']);
    expect(find.textContaining(duplicate['id'] as String), findsWidgets);
    debugPrint(
      'STAGE3-ANDROID ticket=${duplicate['id']} duplicate=same-ticket',
    );
  });
}
