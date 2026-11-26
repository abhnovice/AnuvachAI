import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'local_features.dart';
import 'reporting.dart';

class ReportVoice extends StatefulWidget {
  const ReportVoice({
    super.key,
    required this.api,
    required this.language,
    required this.enabled,
    required this.useStatement,
  });
  final Api api;
  final String language;
  final bool enabled;
  final void Function(String) useStatement;

  @override
  State<ReportVoice> createState() => _ReportVoiceState();
}

class _ReportVoiceState extends State<ReportVoice>
    with AutomaticKeepAliveClientMixin<ReportVoice> {
  @override
  bool get wantKeepAlive => true;
  static const channel = LocalFeatures.channel;
  static const path = '/reporting/voice';
  final frames = <String>[];
  final playback = <Uint8List>[];
  final statements = <String>[];
  String? session;
  String status = '';
  String output = '';
  String partial = '';
  bool starting = false;
  bool finishing = false;
  bool closed = false;
  int rate = 24000;

  Future<void> start() async {
    final language = widget.language;
    setState(() {
      starting = true;
      finishing = false;
      output = '';
      partial = '';
      status = 'Connecting to voice…';
    });
    var opened = false;
    try {
      channel.setMethodCallHandler((call) async {
        if (call.method == 'voicePcm' && frames.length < 8 && !finishing) {
          frames.add(base64Encode(call.arguments as Uint8List));
        }
        if (call.method == 'voiceMicStopped' && !finishing && session != null) {
          unawaited(
            stop('Microphone stopped. Start again or continue with text.'),
          );
        }
      });
      final started =
          await widget.api.call(path, body: {'language': language}) as Json;
      final id = started['id'] as String;
      if (closed || widget.language != language || !widget.enabled) {
        await widget.api.call('$path/$id', method: 'DELETE');
        return;
      }
      session = id;
      if (await channel.invokeMethod<bool>('startVoice', {
            'language': language,
          }) !=
          true) {
        await stop('Microphone permission unavailable. Continue with text.');
        return;
      }
      if (closed || session != id) {
        await channel.invokeMethod<void>('stopMic');
        return;
      }
      opened = true;
      unawaited(exchange(id));
    } catch (_) {
      await stop('Voice unavailable. Start again or continue with text.');
    } finally {
      if (mounted) {
        setState(() {
          starting = false;
          if (opened && session != null) status = 'Listening';
        });
      }
    }
  }

  Future<void> exchange(String id) async {
    bool sentEnd = false;
    DateTime? endAt;
    try {
      while (session == id) {
        final chunk = List<String>.of(frames);
        frames.clear();
        final end = finishing && !sentEnd;
        final response =
            await widget.api.call(
                  '$path/$id',
                  body: {'frames': chunk, 'end': end},
                )
                as Json;
        if (session != id || !mounted) return;
        if (end) {
          sentEnd = true;
          endAt = DateTime.now().add(const Duration(seconds: 8));
        }
        final events = (response['events'] as List).cast<Json>();
        for (final event in events) {
          switch (event['type']) {
            case 'error':
              await stop(
                'Voice disconnected. Start again or continue with text.',
              );
              return;
            case 'state':
              if (event['state'] == 'interrupted') {
                playback.clear();
                await channel.invokeMethod<void>('clearVoice');
                if (mounted) setState(() => status = 'Interrupted. Listening…');
              }
            case 'transcript':
              if (!mounted) return;
              final text = event['text'] as String;
              setState(() {
                if (event['role'] == 'agent') {
                  output = event['partial'] == true ? output + text : text;
                } else if (event['partial'] == true) {
                  partial += text;
                } else {
                  partial = '';
                  if (text.trim().isNotEmpty && !statements.contains(text)) {
                    statements.add(text);
                  }
                }
              });
            case 'audio':
              if (playback.length >= 24) {
                await stop(
                  'Audio playback fell behind. Continue with text or start again.',
                );
                return;
              }
              final mime = event['mime_type'] as String;
              rate =
                  int.tryParse(
                    RegExp(r'rate=(\d+)').firstMatch(mime)?.group(1) ?? '',
                  ) ??
                  24000;
              playback.add(base64Decode(event['data'] as String));
          }
        }
        for (var i = 0; i < 8 && playback.isNotEmpty && session == id; i++) {
          final pcm = playback.first;
          final written =
              await channel.invokeMethod<int>('playVoice', {
                'pcm': pcm,
                'rate': rate,
              }) ??
              -1;
          if (session != id) return;
          if (written < 0 || written > pcm.length) {
            throw StateError('Invalid playback write');
          }
          if (written == pcm.length) {
            playback.removeAt(0);
          } else {
            if (written > 0) playback[0] = Uint8List.sublistView(pcm, written);
            break;
          }
        }
        if (endAt != null && DateTime.now().isAfter(endAt)) {
          await stop(
            'Voice stopped. Review captured statements or continue with text.',
          );
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 65));
      }
    } catch (_) {
      if (session == id) {
        await stop('Voice disconnected. Start again or continue with text.');
      }
    }
  }

  Future<void> finish() async {
    setState(() {
      finishing = true;
      status = 'Finishing the voice turn…';
    });
    try {
      await channel.invokeMethod<void>('stopMic');
    } catch (_) {
      await stop('Microphone stopped. Continue with text.');
    }
  }

  Future<void> stop(String message) async {
    final id = session;
    session = null;
    frames.clear();
    playback.clear();
    if (mounted && !closed) {
      setState(() {
        finishing = false;
        partial = '';
        status = message;
      });
    }
    try {
      await channel.invokeMethod<void>('stopMic');
      await channel.invokeMethod<void>('clearVoice');
      if (id != null) await widget.api.call('$path/$id', method: 'DELETE');
    } catch (_) {
      // The API expires disconnected sessions.
    }
  }

  @override
  void didUpdateWidget(ReportVoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      statements.clear();
      output = '';
      partial = '';
      unawaited(
        stop(
          'Language changed. Start a new voice session or continue with text.',
        ),
      );
    } else if (!widget.enabled && session != null) {
      unawaited(stop('Voice stopped. Continue with text or start again.'));
    }
  }

  @override
  void dispose() {
    closed = true;
    channel.setMethodCallHandler(null);
    if (session != null || starting) unawaited(stop(''));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final limited = widget.language != 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          limited
              ? 'Voice is limited for this language. Text reporting is available.'
              : 'Voice reporting. Review the transcript before using it.',
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          OutlinedButton(
            onPressed: !widget.enabled || starting || finishing
                ? null
                : session == null
                ? start
                : finish,
            child: Text(session == null ? 'Start voice' : 'Stop microphone'),
          ),
        if (status.isNotEmpty) Text(status),
        if (partial.isNotEmpty) Text('Live preview: $partial'),
        if (output.isNotEmpty) Text('Assistant: $output'),
        for (final statement in statements)
          ListTile(
            title: Text(
              statement,
              textDirection: widget.language == 'ur' ? TextDirection.rtl : null,
            ),
            trailing: TextButton(
              onPressed: widget.enabled
                  ? () {
                      widget.useStatement(statement);
                      setState(() => statements.remove(statement));
                    }
                  : null,
              child: const Text('Use in draft'),
            ),
          ),
      ],
    );
  }
}
