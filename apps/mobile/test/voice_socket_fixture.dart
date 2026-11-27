import 'dart:async';
import 'dart:convert';
import 'dart:io';

class VoiceSocketFixture extends StreamView<dynamic> implements WebSocket {
  VoiceSocketFixture._(this.events) : super(events.stream);

  factory VoiceSocketFixture({bool voiceCues = true}) {
    final events = StreamController<dynamic>();
    final socket = VoiceSocketFixture._(events);
    socket.emit({
      'type': 'state',
      'state': 'ready',
      if (voiceCues) 'voice_cues': true,
    });
    return socket;
  }

  final StreamController<dynamic> events;
  final sent = <Object>[];

  void emit(Map<String, Object> event) => events.add(jsonEncode(event));

  @override
  void add(dynamic data) => sent.add(data as Object);

  @override
  int? get closeCode => 1000;

  @override
  Future<void> close([int? code, String? reason]) => events.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
