import 'dart:io';

import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:anuvach_mobile/main.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const id = String.fromEnvironment('STAGE3_REVIEWED_TICKET');

  testWidgets('Employee sees the administrator status on Android', (
    tester,
  ) async {
    HttpOverrides.global = null;
    final api = Api();
    addTearDown(api.client.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportDetail(api: api, id: id),
      ),
    );
    final status = find.text('In review');
    for (var i = 0; i < 60 && status.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(status, findsOneWidget);
    expect(find.textContaining(id), findsWidgets);
  }, skip: id.isEmpty);
}
