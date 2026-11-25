import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;

class Api {
  Api({http.Client? client, String? base})
    : client = client ?? http.Client(),
      base =
          base ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000',
          );
  final http.Client client;
  final String base;
  Future<dynamic> call(String path, {Json? body, String? key}) async {
    try {
      final uri = Uri.parse('$base/api/v1$path');
      final response =
          await (body == null
                  ? client.get(uri)
                  : client.post(
                      uri,
                      headers: {
                        'Content-Type': 'application/json',
                        'idempotency-key': key!,
                      },
                      body: jsonEncode(body),
                    ))
              .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 400) {
        throw Exception(
          jsonDecode(response.body)['error'] ?? 'Request rejected',
        );
      }
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception(
        'Could not reach or complete the API request. Your draft is preserved. Check the local API address and retry. ($e)',
      );
    }
  }

  Future<List<Json>> history() async =>
      (await call('/reports?employeeId=demo-employee') as List).cast<Json>();
  Future<Json> detail(String id) async => (await call('/reports/$id')) as Json;
}

class Draft extends ChangeNotifier {
  Draft(this.prefs, this.api) {
    final saved = prefs.getString('draft');
    if (saved != null) {
      try {
        final data = jsonDecode(saved) as Json;
        fields = Map<String, dynamic>.from(data['fields']);
        key = data['key'];
        pending = data['pending'] == null
            ? null
            : Map<String, dynamic>.from(data['pending']);
      } catch (_) {
        storageWarning =
            'Saved draft could not be read. Please re-enter synthetic details.';
      }
    }
  }
  final SharedPreferences prefs;
  final Api api;
  Json fields = {
    'employeeId': 'demo-employee',
    'description': '',
    'language': 'english',
    'incidentType': 'support_call',
    'appName': '',
    'evidenceNotes': '',
    'observations': <dynamic>[],
  };
  String key = const Uuid().v4();
  Json? pending;
  Json? reviewed;
  bool confirmed = false, busy = false;
  String? storageWarning;
  Future<void> _writes = Future.value();
  bool get locked => pending != null;
  Future<void> save() {
    final snapshot = jsonEncode({
      'fields': fields,
      'key': key,
      'pending': pending,
    });
    _writes = _writes.catchError((_) {}).then((_) async {
      if (!await prefs.setString('draft', snapshot)) {
        throw Exception('Draft could not be saved locally.');
      }
    });
    return _writes;
  }

  void update(String name, dynamic value) {
    if (locked || busy) return;
    fields[name] = value;
    reviewed = null;
    confirmed = false;
    notifyListeners();
  }

  Json review() {
    reviewed =
        jsonDecode(jsonEncode(pending ?? {...fields, 'confirmed': true}))
            as Json;
    confirmed = false;
    return reviewed!;
  }

  void confirm(bool value) {
    confirmed = value;
    notifyListeners();
  }

  Future<Json> submit() async {
    if (!confirmed || reviewed == null || busy) {
      throw StateError('Review and confirm this report first.');
    }
    busy = true;
    notifyListeners();
    try {
      pending = jsonDecode(jsonEncode(reviewed)) as Json;
      await save();
      final result =
          await api.call('/reports', body: pending, key: key) as Json;
      // Retain acknowledged ticket until draft removal is durable.
      if (!await prefs.remove('draft')) {
        throw Exception(
          'Ticket saved, but local draft cleanup failed. Retry safely.',
        );
      }
      fields = {
        'employeeId': 'demo-employee',
        'description': '',
        'language': 'english',
        'incidentType': 'support_call',
        'appName': '',
        'evidenceNotes': '',
        'observations': <dynamic>[],
      };
      pending = null;
      reviewed = null;
      confirmed = false;
      key = const Uuid().v4();
      return result;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
