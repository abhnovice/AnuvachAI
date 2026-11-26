import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;

class Api {
  Api({http.Client? client, String? base, this.token, this.voiceConnector})
    : client = client ?? http.Client(),
      base =
          base ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue:
                'https://anuvachai-git-425459156696.asia-south1.run.app',
          );
  final http.Client client;
  final String base;
  final Future<String?> Function()? token;
  final Future<WebSocket> Function(Uri, Map<String, String>)? voiceConnector;

  Future<WebSocket> openVoice(String language) async {
    final credential = await token?.call();
    if (token != null && credential == null) {
      throw StateError('Sign in to continue.');
    }
    final endpoint = Uri.parse('$base/api/v1/reporting/voice/stream');
    final uri = endpoint.replace(
      scheme: endpoint.scheme == 'https' ? 'wss' : 'ws',
      queryParameters: {'language': language, 'ticketDraft': '1'},
    );
    final headers = {
      if (credential != null) 'Authorization': 'Bearer $credential',
    };
    return await (voiceConnector?.call(uri, headers) ??
        WebSocket.connect(
          uri.toString(),
          headers: headers,
          compression: CompressionOptions.compressionOff,
        ));
  }

  Future<dynamic> call(
    String path, {
    Json? body,
    String? key,
    String? method,
  }) async {
    try {
      final credential = await token?.call();
      if (token != null && credential == null) {
        throw StateError('Sign in to continue.');
      }
      final headers = <String, String>{
        if (credential != null) 'Authorization': 'Bearer $credential',
        if (body != null) 'Content-Type': 'application/json',
        'idempotency-key': ?key,
      };
      final uri = Uri.parse('$base/api/v1$path');
      final response =
          await (method == 'DELETE'
                  ? client.delete(uri, headers: headers)
                  : body == null
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(Duration(seconds: path == '/reporting/turns' ? 38 : 12));
      if (response.statusCode >= 400) {
        throw Exception(
          jsonDecode(response.body)['error'] ?? 'Request rejected',
        );
      }
      return response.statusCode == 204 ? null : jsonDecode(response.body);
    } catch (e) {
      throw Exception(
        'Could not reach or complete the API request. Your draft is preserved. Check your connection and retry. ($e)',
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
  bool assisting = false;
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

  Future<void> applyVoiceDraft(Json proposal, String language) async {
    if (locked || busy) {
      throw StateError(
        'Finish the pending submission before adding a voice draft.',
      );
    }
    final previous = (fields['description'] as String).trim();
    final description = proposal['description'] as String;
    final combined = previous.isEmpty || previous == description
        ? description
        : '$previous\n$description';
    if (combined.length > 5000) {
      throw StateError(
        'Shorten the existing draft before adding the voice draft.',
      );
    }
    final previousReporting = fields['reporting'] as Json?;
    final unknowns = {
      ...?previousReporting?['unknowns'] as List?,
      ...proposal['unknowns'] as List,
    }.take(12).toList();
    fields = {
      ...fields,
      'description': combined,
      if (previous.isEmpty) 'incidentType': proposal['incident_type'],
      if ((fields['appName'] as String).trim().isEmpty)
        'appName': proposal['app_name'],
      if ((fields['evidenceNotes'] as String).trim().isEmpty)
        'evidenceNotes': proposal['evidence_notes'],
      'language': switch (language) {
        'en' => 'english',
        'hi' => 'hindi',
        _ => language,
      },
      'reporting': {
        'language': language,
        'transcript': previousReporting?['transcript'] ?? <Json>[],
        'unknowns': unknowns,
      },
    };
    reviewed = null;
    confirmed = false;
    notifyListeners();
    await save();
  }

  Future<void> askAgent(String language) async {
    final text = (fields['description'] as String).trim();
    if (text.isEmpty || locked || busy || assisting) return;
    final sessionId = key;
    assisting = true;
    notifyListeners();
    try {
      final previous = fields['reporting'] as Json?;
      final transcript = [
        ...?previous?['transcript'] as List?,
        {'speaker': 'employee', 'text': text},
      ];
      // Reserve a slot for the reply and bound the submitted transcript.
      if (transcript.length > 11) {
        transcript.removeRange(0, transcript.length - 11);
      }
      update('reporting', {
        'language': language,
        'transcript': transcript,
        'unknowns': previous?['unknowns'] ?? <String>[],
      });
      await save();
      final reply =
          await api.call(
                '/reporting/turns',
                body: {
                  'sessionId': sessionId,
                  'language': language,
                  'text': text,
                },
              )
              as Json;
      if (key != sessionId || reviewed != null || locked || busy) return;
      update('reporting', {
        'language': language,
        'transcript': [
          ...transcript,
          {'speaker': 'agent', 'text': reply['reply']},
        ],
        'unknowns': reply['unknowns'],
      });
      await save();
    } finally {
      assisting = false;
      notifyListeners();
    }
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
