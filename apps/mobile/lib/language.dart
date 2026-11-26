import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Native-script names remain readable before a locale has been selected.
const languages = <String, String>{
  'en': 'English',
  'hi': 'हिन्दी',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'bn': 'বাংলা',
  'kn': 'ಕನ್ನಡ',
  'ml': 'മലയാളം',
  'ur': 'اردو',
  'pa': 'ਪੰਜਾਬੀ',
};

class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString('ui_language');
    _locale = Locale(languages.containsKey(saved) ? saved! : 'en');
  }
  final SharedPreferences _prefs;
  late Locale _locale;
  Locale get locale => _locale;
  Future<bool> setLanguage(String code) async {
    if (!languages.containsKey(code)) return false;
    if (!await _prefs.setString('ui_language', code)) return false;
    if (_locale.languageCode != code) {
      _locale = Locale(code);
      notifyListeners();
    }
    return true;
  }
}
