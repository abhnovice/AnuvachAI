import 'dart:convert';

import 'package:anuvach_mobile/l10n/app_localizations.dart';
import 'package:anuvach_mobile/main.dart';
import 'package:anuvach_mobile/reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const statements = {
    'english': 'A suspicious support call arrived.',
    'hindi': 'मुझे एक संदिग्ध सहायता कॉल आया।',
    'ta': 'எனக்கு சந்தேகமான ஆதரவு அழைப்பு வந்தது.',
    'te': 'నాకు అనుమానాస్పద మద్దతు కాల్ వచ్చింది.',
    'bn': 'আমি একটি সন্দেহজনক সহায়তা ফোন পেয়েছি।',
    'kn': 'ನನಗೆ ಅನುಮಾನಾಸ್ಪದ ಬೆಂಬಲ ಕರೆ ಬಂದಿದೆ.',
    'ml': 'എനിക്ക് സംശയാസ്പദമായ സഹായ കോൾ ലഭിച്ചു.',
    'ur': 'مجھے ایک مشکوک معاونتی کال موصول ہوئی۔',
    'pa': 'ਮੈਨੂੰ ਇੱਕ ਸ਼ੱਕੀ ਸਹਾਇਤਾ ਕਾਲ ਆਈ।',
  };

  for (final item in statements.entries) {
    testWidgets('${item.key} text edit, confirmation and ticket ID', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      Json? saved;
      const ticketId = 'ANV-language-fixture';
      final api = Api(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            saved = jsonDecode(request.body) as Json;
          }
          return http.Response(
            jsonEncode({
              'id': ticketId,
              'status': 'submitted',
              'facts': saved,
              'version': 1,
            }),
            200,
          );
        }),
      );
      final draft = Draft(await SharedPreferences.getInstance(), api);
      draft.update('language', item.key);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReportForm(draft: draft),
        ),
      );
      final field = find.byKey(const ValueKey('description'));
      if (item.key == 'ur') {
        final editor = find.descendant(
          of: field,
          matching: find.byType(EditableText),
        );
        expect(
          tester.widget<EditableText>(editor).textDirection,
          TextDirection.rtl,
        );
      }
      await tester.enterText(field, item.value);
      await tester.pump();
      expect(draft.fields['description'], item.value);
      final edited = '${item.value} ${item.value}';
      await tester.enterText(field, edited);
      await tester.pump();
      expect(draft.fields['description'], edited);
      await tester.ensureVisible(find.text('Review report'));
      await tester.tap(find.text('Review report'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      final checkbox = find.byType(CheckboxListTile);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      final submit = find.text('Confirm and submit');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(saved?['description'], edited);
      expect(saved?['language'], 'english');
      expect(saved?['confirmed'], true);
      expect(find.textContaining(ticketId), findsWidgets);
    });
  }
}
