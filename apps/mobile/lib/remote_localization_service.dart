import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _supportedLocales = [
  'en',
  'hi',
  'ta',
  'te',
  'bn',
  'kn',
  'ml',
  'ur',
  'pa',
];

class RemoteLocalizationService extends ChangeNotifier {
  RemoteLocalizationService(this._prefs) {
    for (final locale in _supportedLocales) {
      final decoded = _decode(
        _prefs.getString('arb_overrides_$locale') ?? '{}',
      );
      if (decoded != null) _values[locale] = decoded;
    }
  }
  final SharedPreferences _prefs;
  final Map<String, Map<String, String>> _values = {};
  Map<String, Map<String, String>> get overrides => Map.unmodifiable(
    _values.map(
      (key, value) => MapEntry(key, Map<String, String>.unmodifiable(value)),
    ),
  );
  int revision = 0;
  FirebaseRemoteConfig? _config;
  bool _busy = false;
  bool _disposed = false;

  Map<String, String>? _decode(String value) {
    try {
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic>) return null;
      final result = <String, String>{};
      for (final entry in json.entries) {
        if (entry.key.startsWith('@')) continue;
        if (entry.value is! String) return null;
        result[entry.key] = entry.value as String;
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    try {
      _config = FirebaseRemoteConfig.instance;
      await _config!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
      await _config!.setDefaults({
        for (final locale in _supportedLocales) 'arb_overrides_$locale': '{}',
      });
      await refresh();
    } catch (error) {
      debugPrint('Remote translations unavailable: $error');
    }
  }

  Future<bool> refresh({bool force = false}) async {
    final config = _config;
    if (config == null || _busy) return false;
    _busy = true;
    try {
      if (force && kDebugMode) {
        await config.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 15),
            minimumFetchInterval: Duration.zero,
          ),
        );
      }
      await config.fetchAndActivate();
      var changed = false;
      for (final locale in _supportedLocales) {
        final key = 'arb_overrides_$locale';
        final decoded = _decode(config.getString(key));
        if (decoded == null) continue;
        if (mapEquals(_values[locale] ?? const <String, String>{}, decoded)) {
          continue;
        }
        if (!await _prefs.setString(key, jsonEncode(decoded))) continue;
        _values[locale] = decoded;
        changed = true;
      }
      if (changed && !_disposed) {
        revision++;
        notifyListeners();
      }
      return changed;
    } catch (error) {
      debugPrint('Remote translations fetch failed: $error');
      return false;
    } finally {
      if (force && kDebugMode) {
        try {
          await config.setConfigSettings(
            RemoteConfigSettings(
              fetchTimeout: const Duration(seconds: 15),
              minimumFetchInterval: const Duration(hours: 12),
            ),
          );
        } catch (_) {}
      }
      _busy = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
