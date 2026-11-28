import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'reporting.dart';

class SavedChat {
  SavedChat({String? id, List<Json>? messages})
    : id = id ?? const Uuid().v4(),
      messages = messages ?? [];

  final String id;
  final List<Json> messages;

  String? get title {
    for (final turn in messages) {
      if (turn['speaker'] == 'employee') return turn['text'] as String;
    }
    return null;
  }

  Json toJson() => {'id': id, 'messages': messages};
}

class SavedChats {
  SavedChats(this.prefs, String account) : key = 'check_chats_v1:$account' {
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      final saved = jsonDecode(raw) as Json;
      for (final item in saved['chats'] as List) {
        chats.add(
          SavedChat(
            id: item['id'] as String,
            messages: (item['messages'] as List).cast<Json>(),
          ),
        );
      }
      final selected = chats.indexWhere((chat) => chat.id == saved['active']);
      if (selected != -1) active = chats[selected];
      chats.removeWhere((chat) => chat.messages.isEmpty);
    } catch (_) {
      chats.clear();
      active = SavedChat();
    }
  }

  final SharedPreferences prefs;
  final String key;
  final chats = <SavedChat>[];
  SavedChat active = SavedChat();
  Future<void> _writes = Future.value();

  Future<void> save([SavedChat? changed]) {
    if (changed != null && changed.messages.isNotEmpty) {
      chats.remove(changed);
      chats.insert(0, changed);
    }
    final snapshot = jsonEncode({
      'active': active.id,
      'chats': [
        if (active.messages.isEmpty) active.toJson(),
        ...chats
            .where((chat) => chat.messages.isNotEmpty)
            .map((chat) => chat.toJson()),
      ],
    });
    _writes = _writes.catchError((_) {}).then((_) async {
      if (!await prefs.setString(key, snapshot)) {
        throw StateError('Chat could not be saved on this device.');
      }
    });
    return _writes;
  }
}
