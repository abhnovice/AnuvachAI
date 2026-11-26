import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

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
    with AutomaticKeepAliveClientMixin<ReportVoice>, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;
  static const channel = LocalFeatures.channel;
  static const trace = bool.fromEnvironment('VOICE_TRACE');
  final playback = Queue<Uint8List>();
  final statements = <String>[];
  final clock = Stopwatch();
  WebSocket? socket;
  StreamSubscription<dynamic>? subscription;
  Timer? retryWrite;
  Timer? deadline;
  Object? attempt;
  bool writing = false;
  bool starting = false;
  bool finishing = false;
  bool stopping = false;
  bool closed = false;
  bool startedMic = false;
  bool preparingMic = false;
  bool finishAfterDrain = false;
  int playbackEpoch = 0;
  int queuedBytes = 0;
  int? lastAudioMs;
  int maxArrivalGapMs = 0;
  int interruptions = 0;
  int? firstCaptureMs;
  int? firstUploadMs;
  String status = '';
  String output = '';
  String partial = '';
  String agentPartial = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && attempt != null) {
      unawaited(stop('Voice paused. Start again or continue with text.'));
    }
  }

  Future<void> start() async {
    final current = Object();
    attempt = current;
    final language = widget.language;
    clock
      ..reset()
      ..start();
    firstCaptureMs = firstUploadMs = lastAudioMs = null;
    maxArrivalGapMs = interruptions = 0;
    setState(() {
      starting = true;
      finishing = false;
      output = agentPartial = partial = '';
      status = 'Connecting to voice…';
    });
    deadline = Timer(const Duration(seconds: 12), () {
      unawaited(stop('Voice connection timed out. Continue with text.'));
    });
    try {
      final connected = await widget.api.openVoice(language);
      if (attempt != current) {
        unawaited(connected.close());
        return;
      }
      socket = connected;
      subscription = connected.listen(
        (message) {
          if (attempt != current) return;
          try {
            handleEvent(jsonDecode(message as String) as Json, current);
          } catch (_) {
            unawaited(
              stop('Voice disconnected. Start again or continue with text.'),
            );
          }
        },
        onDone: () {
          if (attempt == current) {
            unawaited(
              stop(
                connected.closeCode == 4001
                    ? 'Voice session expired. Start again or continue with text.'
                    : 'Voice disconnected. Start again or continue with text.',
              ),
            );
          }
        },
        onError: (Object _) {
          if (attempt == current) {
            unawaited(
              stop('Voice disconnected. Start again or continue with text.'),
            );
          }
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (attempt == current) {
        await stop('Voice unavailable. Start again or continue with text.');
      }
    }
  }

  Future<void> startMic(Object current) async {
    deadline?.cancel();
    channel.setMethodCallHandler((call) async {
      if (attempt != current) return;
      if (call.method == 'voicePcm' && !finishing) {
        firstCaptureMs ??= clock.elapsedMilliseconds;
        socket?.add(call.arguments as Uint8List);
        firstUploadMs ??= clock.elapsedMilliseconds;
      } else if (call.method == 'voiceFocusLost' ||
          (call.method == 'voiceMicStopped' && !finishing)) {
        unawaited(
          stop('Microphone stopped. Start again or continue with text.'),
        );
      }
    });
    try {
      preparingMic = true;
      final ready = await channel.invokeMethod<bool>('startVoice', {
        'language': widget.language,
        'trace': trace,
      });
      if (attempt != current) {
        if (ready == true) await channel.invokeMethod<void>('stopMic');
        return;
      }
      if (ready != true) throw StateError('Microphone unavailable');
      startedMic = true;
      setState(() {
        starting = false;
        status = 'Listening';
      });
    } catch (_) {
      if (attempt == current) {
        await stop('Microphone unavailable. Continue with text.');
      }
    } finally {
      preparingMic = false;
      if (mounted && !closed) setState(() {});
    }
  }

  void handleEvent(Json event, Object current) {
    switch (event['type']) {
      case 'timing':
        if (trace) {
          debugPrint(
            'VOICE_TRACE proxy_upload_ms=${event['proxy_first_upload_ms']} '
            'proxy_audio_ms=${event['proxy_first_audio_ms']} '
            'gemini_input_to_audio_ms=${event['input_to_audio_ms']}',
          );
        }
      case 'error':
        unawaited(
          stop('Voice disconnected. Start again or continue with text.'),
        );
      case 'state':
        switch (event['state']) {
          case 'ready':
            if (!preparingMic && !startedMic) unawaited(startMic(current));
          case 'interrupted':
            interruptions++;
            lastAudioMs = null;
            clearPlayback();
            setState(() {
              output = agentPartial = '';
              status = 'Interrupted. Listening…';
            });
          case 'listening':
            lastAudioMs = null;
            if (finishing) {
              finishAfterDrain = true;
              if (playback.isEmpty && !writing) scheduleFinish();
            }
        }
      case 'transcript':
        final text = event['text'] as String;
        setState(() {
          if (event['role'] == 'agent') {
            if (event['partial'] == true) {
              agentPartial += text;
              output = agentPartial;
            } else {
              if (text.isNotEmpty) output = text;
              agentPartial = '';
            }
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
        final mime = event['mime_type'] as String;
        if (!RegExp(
          r'^audio/pcm(?:;\s*rate=24000)?$',
          caseSensitive: false,
        ).hasMatch(mime)) {
          throw StateError('Unexpected output format');
        }
        final pcm = base64Decode(event['data'] as String);
        if (pcm.isEmpty || pcm.length.isOdd) throw StateError('Invalid PCM');
        final now = clock.elapsedMilliseconds;
        if (lastAudioMs case final last?) {
          if (now - last > maxArrivalGapMs) maxArrivalGapMs = now - last;
        } else if (trace) {
          debugPrint('VOICE_TRACE response_audio_received_ms=$now');
        }
        lastAudioMs = now;
        if (queuedBytes + pcm.length > 48 * 1024) {
          unawaited(
            stop(
              'Audio playback fell behind. Continue with text or start again.',
            ),
          );
          return;
        }
        queuedBytes += pcm.length;
        playback.add(pcm);
        if (retryWrite == null) unawaited(drainPlayback());
    }
  }

  Future<void> drainPlayback() async {
    if (writing) return;
    writing = true;
    try {
      while (playback.isNotEmpty && attempt != null) {
        final epoch = playbackEpoch;
        final pcm = playback.first;
        final written =
            await channel.invokeMethod<int>('playVoice', {
              'pcm': pcm,
              'rate': 24000,
            }) ??
            -1;
        if (epoch != playbackEpoch) continue;
        if (written < 0 || written > pcm.length || written.isOdd) {
          throw StateError('Invalid playback write');
        }
        queuedBytes -= written;
        if (written == pcm.length) {
          playback.removeFirst();
        } else {
          if (written > 0) {
            playback.removeFirst();
            playback.addFirst(Uint8List.sublistView(pcm, written));
          }
          retryWrite = Timer(const Duration(milliseconds: 12), () {
            retryWrite = null;
            unawaited(drainPlayback());
          });
          break;
        }
      }
    } catch (_) {
      if (attempt != null) {
        unawaited(stop('Audio playback unavailable. Continue with text.'));
      }
    } finally {
      writing = false;
      if (finishAfterDrain && playback.isEmpty && attempt != null) {
        scheduleFinish();
      }
    }
  }

  void scheduleFinish() {
    deadline?.cancel();
    // Let the native buffer finish playing before releasing the track.
    deadline = Timer(const Duration(milliseconds: 350), () {
      unawaited(
        stop(
          'Voice stopped. Review captured statements or continue with text.',
        ),
      );
    });
  }

  Future<void> finish() async {
    setState(() {
      finishing = true;
      status = 'Finishing the voice turn…';
    });
    final current = attempt;
    try {
      await channel.invokeMethod<void>('stopMic');
      if (attempt != current) return;
      socket?.add('end');
      deadline = Timer(const Duration(seconds: 12), () {
        finishAfterDrain = true;
        if (playback.isEmpty) scheduleFinish();
      });
    } catch (_) {
      await stop('Microphone stopped. Continue with text.');
    }
  }

  Future<void> clearPlayback() async {
    playbackEpoch++;
    retryWrite?.cancel();
    retryWrite = null;
    playback.clear();
    queuedBytes = 0;
    try {
      await channel.invokeMethod<void>('clearVoice');
    } catch (_) {}
  }

  Future<void> stop(String message) async {
    if (attempt == null) return;
    attempt = null;
    stopping = true;
    deadline?.cancel();
    final connected = socket;
    socket = null;
    unawaited(subscription?.cancel());
    subscription = null;
    unawaited(connected?.close());
    channel.setMethodCallHandler(null);
    if (trace) {
      debugPrint(
        'VOICE_TRACE capture_ms=$firstCaptureMs upload_ms=$firstUploadMs '
        'max_arrival_gap_ms=$maxArrivalGapMs interruptions=$interruptions',
      );
    }
    if (mounted && !closed) {
      setState(() {
        starting = finishing = startedMic = finishAfterDrain = false;
        partial = agentPartial = '';
        status = message;
      });
    }
    try {
      await channel.invokeMethod<void>('stopMic');
      await clearPlayback();
      await channel.invokeMethod<void>('releaseVoice');
    } catch (_) {
      // Android also releases audio on activity pause.
    } finally {
      stopping = false;
      if (mounted && !closed) setState(() {});
    }
  }

  @override
  void didUpdateWidget(ReportVoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      output = '';
      unawaited(
        stop(
          'Language changed. Start a new voice session or continue with text.',
        ),
      );
    } else if (!widget.enabled && attempt != null) {
      unawaited(stop('Voice stopped. Continue with text or start again.'));
    }
  }

  @override
  void dispose() {
    closed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(stop(''));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Voice reporting. Review the transcript before using it.'),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          OutlinedButton(
            onPressed:
                !widget.enabled ||
                    starting ||
                    finishing ||
                    stopping ||
                    preparingMic
                ? null
                : attempt == null
                ? start
                : finish,
            child: Text(attempt == null ? 'Start voice' : 'Stop microphone'),
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
