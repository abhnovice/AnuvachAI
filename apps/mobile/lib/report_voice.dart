import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    required this.reviewTicket,
  });
  final Api api;
  final String language;
  final bool enabled;
  final Future<void> Function(Json, String) reviewTicket;

  @override
  State<ReportVoice> createState() => _ReportVoiceState();
}

class _ReportVoiceState extends State<ReportVoice>
    with AutomaticKeepAliveClientMixin<ReportVoice>, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;
  static const channel = LocalFeatures.channel;
  static const trace = bool.fromEnvironment('VOICE_TRACE');
  Json? ticketDraft;
  String? ticketLanguage;
  bool openingDraft = false;
  bool suppressReplyAudio = false;
  bool serverTurnComplete = true;
  final clock = Stopwatch();
  WebSocket? socket;
  StreamSubscription<dynamic>? subscription;
  Timer? finishDelay;
  Timer? deadline;
  Object? attempt;
  bool playing = false;
  bool starting = false;
  bool finishing = false;
  bool stopping = false;
  bool closed = false;
  bool startedMic = false;
  bool preparingMic = false;
  bool finishAfterDrain = false;
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
      suppressReplyAudio = false;
      serverTurnComplete = true;
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
      } else if (call.method == 'voicePlayback') {
        final active = call.arguments == true;
        setState(() {
          playing = active;
          if (!finishing) status = active ? 'Speaking' : 'Listening';
        });
        if (!active && finishAfterDrain) scheduleFinish();
      } else if (call.method == 'voicePlaybackError') {
        playbackFailed();
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
            suppressReplyAudio = false;
            serverTurnComplete = true;
            interruptions++;
            lastAudioMs = null;
            finishDelay?.cancel();
            unawaited(channel.invokeMethod<void>('clearVoice'));
            setState(() {
              output = agentPartial = '';
              playing = false;
              if (!finishing) status = 'Listening';
            });
          case 'listening':
            suppressReplyAudio = false;
            serverTurnComplete = true;
            lastAudioMs = null;
            if (finishing) {
              finishAfterDrain = true;
              if (!playing) scheduleFinish();
            }
        }
      case 'ticket_draft':
        setState(() {
          ticketDraft = event['draft'] as Json;
          ticketLanguage = widget.language;
        });
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
          }
        });
      case 'audio':
        if (suppressReplyAudio) return;
        serverTurnComplete = false;
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
        finishDelay?.cancel();
        playing = true;
        unawaited(playAudio(pcm, current));
    }
  }

  Future<void> playAudio(Uint8List pcm, Object current) async {
    try {
      await channel.invokeMethod<void>('playVoice', {'pcm': pcm});
    } catch (_) {
      if (attempt == current) {
        playbackFailed();
      }
    }
  }

  void playbackFailed() {
    suppressReplyAudio = !serverTurnComplete;
    setState(() {
      playing = false;
      if (!finishing) status = 'Reply audio stopped. Still listening…';
    });
    if (finishAfterDrain) scheduleFinish();
  }

  Future<void> openDraft() async {
    final proposal = ticketDraft;
    final language = ticketLanguage;
    if (proposal == null || language == null) return;
    setState(() => openingDraft = true);
    try {
      await stop('Voice stopped. Review your ticket draft.');
      await widget.reviewTicket(proposal, language);
      if (mounted && ticketDraft == proposal)
        setState(() => ticketDraft = null);
    } catch (error) {
      if (mounted) setState(() => status = error.toString());
    } finally {
      if (mounted) setState(() => openingDraft = false);
    }
  }

  void scheduleFinish() {
    finishDelay?.cancel();
    finishDelay = Timer(const Duration(milliseconds: 250), () {
      unawaited(stop('Voice stopped. Review captured statements.'));
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
      deadline = Timer(const Duration(seconds: 15), () {
        unawaited(stop('Voice stopped. Review captured statements.'));
      });
    } catch (_) {
      await stop('Microphone stopped. Continue with text.');
    }
  }

  Future<void> stop(String message) async {
    if (attempt == null) return;
    attempt = null;
    stopping = true;
    deadline?.cancel();
    finishDelay?.cancel();
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
        starting = finishing = startedMic = finishAfterDrain = playing = false;
        partial = agentPartial = '';
        status = message;
      });
    }
    try {
      await channel.invokeMethod<void>('stopMic');
      await channel.invokeMethod<void>('clearVoice');
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
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          FilledButton.icon(
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
            icon: Icon(attempt == null ? Icons.mic : Icons.call_end),
            label: Text(attempt == null ? 'Start voice' : 'End voice'),
          ),
        if (status.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Text(status, textAlign: TextAlign.center),
          ),
        if (partial.isNotEmpty) Text('Live preview: $partial'),
        if (output.isNotEmpty) Text('Assistant: $output'),
        if (ticketDraft != null)
          OutlinedButton(
            onPressed: widget.enabled && !openingDraft ? openDraft : null,
            child: const Text('Review ticket draft'),
          ),
      ],
    );
  }
}
