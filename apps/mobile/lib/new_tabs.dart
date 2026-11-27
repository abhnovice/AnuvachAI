import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'report_voice.dart';
import 'design.dart';
import 'reporting.dart';
import 'language.dart';
import 'local_features.dart';
import 'l10n/app_localizations.dart';
import 'device_review.dart';

class CheckTab extends StatefulWidget {
  const CheckTab({
    super.key,
    required this.language,
    required this.messages,
    required this.api,
    required this.sessionId,
    required this.reviewStatement,
    required this.reviewVoiceTicket,
  });

  final String language;
  final List<Json> messages;
  final Api api;
  final String sessionId;
  final Future<void> Function(String) reviewStatement;
  final Future<void> Function(Json, String) reviewVoiceTicket;

  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  bool reviewing = false;
  String? error;
  bool revealed = false;
  String lastPreview = '';

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  void scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> send(String value) async {
    final text = value.trim();
    if (text.isEmpty || busy) return;
    setState(() {
      widget.messages.add({'speaker': 'employee', 'text': text});
      busy = true;
      error = null;
      controller.clear();
    });
    scrollToLatest();
    try {
      final response =
          await widget.api.call(
                '/reporting/turns',
                body: {
                  'sessionId': widget.sessionId,
                  'language': widget.language,
                  'text': text,
                },
              )
              as Json;
      if (mounted) {
        setState(
          () => widget.messages.add({
            'speaker': 'agent',
            'text': response['reply'],
          }),
        );
        scrollToLatest();
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.voiceUnavailable);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> review(String statement) async {
    if (reviewing) return;
    setState(() => reviewing = true);
    try {
      await widget.reviewStatement(statement);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => reviewing = false);
    }
  }

  void addVoiceTurn(String role, String text) {
    if (role != 'employee' && role != 'agent') return;
    setState(
      () => widget.messages.add({
        'speaker': role,
        'text': text,
        'captured': role == 'employee',
      }),
    );
    scrollToLatest();
  }

  Future<void> correct(Json turn) async {
    final strings = AppLocalizations.of(context)!;
    var text = turn['text'] as String;
    final revised = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(strings.voiceCorrect),
        content: TextFormField(
          initialValue: text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 5000,
          onChanged: (value) => text = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.trim()),
            child: Text(strings.voiceApply),
          ),
        ],
      ),
    );
    if (mounted && revised != null && revised.isNotEmpty) {
      setState(() => turn['text'] = revised);
    }
  }

  @override
  Widget build(BuildContext context) => ReportVoice(
    api: widget.api,
    language: widget.language,
    enabled: !reviewing,
    reviewTicket: widget.reviewVoiceTicket,
    onTurn: addVoiceTurn,
    conversation: buildConversation,
  );

  Widget buildConversation(VoiceView voice) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strings = AppLocalizations.of(context)!;
    final preview = voice.employeePreview + voice.assistantPreview;
    if (preview != lastPreview) {
      lastPreview = preview;
      if (preview.isNotEmpty &&
          (!scroll.hasClients || scroll.position.extentAfter < 120)) {
        scrollToLatest();
      }
    }
    final empty = widget.messages.isEmpty && preview.isEmpty && !voice.hasDraft;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final motion = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final phase = busy && !voice.active ? VoicePhase.thinking : voice.phase;
    final stateLabel = switch (phase) {
      VoicePhase.idle => strings.voiceReady,
      VoicePhase.connecting => strings.voiceConnecting,
      VoicePhase.listening => strings.voiceListening,
      VoicePhase.thinking => strings.voiceThinking,
      VoicePhase.speaking => strings.voiceSpeaking,
      VoicePhase.ending => strings.voiceEnding,
      VoicePhase.error =>
        voice.permissionDenied ? strings.micDenied : strings.voiceUnavailable,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewport) => ListView(
                  controller: scroll,
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
                  children: [
                    if (empty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0, viewport.maxHeight - 24),
                        ),
                        child: Center(
                          child: welcome(strings, theme, reduceMotion),
                        ),
                      ),
                    for (final turn in widget.messages)
                      _ConversationReveal(
                        key: ObjectKey(turn),
                        duration: motion,
                        child: _ConversationBubble(
                          speaker: turn['speaker'] == 'agent'
                              ? strings.voiceAssistant
                              : strings.voiceYou,
                          text: turn['text'] as String,
                          employee: turn['speaker'] == 'employee',
                          actions: turn['speaker'] == 'employee'
                              ? [
                                  if (turn['captured'] == true)
                                    TextButton(
                                      onPressed: reviewing
                                          ? null
                                          : () => correct(turn),
                                      child: Text(strings.voiceCorrect),
                                    ),
                                  TextButton(
                                    onPressed: reviewing
                                        ? null
                                        : () => review(turn['text'] as String),
                                    child: Text(strings.voiceUse),
                                  ),
                                ]
                              : const [],
                        ),
                      ),
                    if (voice.employeePreview.isNotEmpty)
                      _ConversationBubble(
                        speaker: strings.voicePartial,
                        text: voice.employeePreview,
                        employee: true,
                      ),
                    if (voice.assistantPreview.isNotEmpty &&
                        voice.assistantPreview !=
                            widget.messages.lastOrNull?['text'])
                      _ConversationBubble(
                        speaker: strings.voiceAssistant,
                        text: voice.assistantPreview,
                        employee: false,
                      ),
                    if (voice.hasDraft)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          onPressed: voice.reviewDraft,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(strings.voiceDraft),
                        ),
                      ),
                    if (error != null)
                      Text(error!, style: TextStyle(color: colors.error)),
                  ],
                ),
              ),
            ),
            Material(
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: AnimatedSwitcher(
                        duration: motion,
                        child: Text(
                          stateLabel,
                          key: ValueKey(stateLabel),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: phase == VoicePhase.error
                                ? colors.error
                                : colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _VoiceControl(
                          phase: voice.phase,
                          duration: motion,
                          label: voice.active
                              ? strings.voiceEnd
                              : strings.voiceStart,
                          onPressed: voice.microphone,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLength: 5000,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: strings.voiceType,
                              counterText: '',
                              isDense: true,
                              contentPadding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                    16,
                                    13,
                                    16,
                                    13,
                                  ),
                            ),
                            onSubmitted: send,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) => IconButton.filled(
                            onPressed: busy || controller.text.trim().isEmpty
                                ? null
                                : () => send(controller.text),
                            tooltip: strings.send,
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(48),
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget welcome(AppLocalizations strings, ThemeData theme, bool reduceMotion) {
    final animate = !revealed && !reduceMotion;
    revealed = true;
    return _ConversationReveal(
      duration: animate ? const Duration(milliseconds: 540) : Duration.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BrandMark(size: 68),
          const SizedBox(height: 22),
          Semantics(
            header: true,
            child: Text(
              strings.voiceWelcome,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.voiceWelcomeHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationReveal extends StatelessWidget {
  const _ConversationReveal({
    super.key,
    required this.duration,
    required this.child,
  });

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.speaker,
    required this.text,
    required this.employee,
    this.actions = const [],
  });

  final String speaker;
  final String text;
  final bool employee;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: employee
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: employee ? .89 : .95,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: employee
                ? colors.primaryContainer
                : colors.surfaceContainerLow,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(23),
              topEnd: const Radius.circular(23),
              bottomStart: Radius.circular(employee ? 23 : 7),
              bottomEnd: Radius.circular(employee ? 7 : 23),
            ),
            border: employee ? null : Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                speaker,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: employee ? colors.onPrimaryContainer : colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: employee
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
              if (actions.isNotEmpty) Wrap(children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceControl extends StatelessWidget {
  const _VoiceControl({
    required this.phase,
    required this.duration,
    required this.label,
    this.onPressed,
  });

  final VoicePhase phase;
  final Duration duration;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = phase == VoicePhase.error ? colors.error : colors.primary;
    final icon = switch (phase) {
      VoicePhase.idle => Icons.mic_rounded,
      VoicePhase.connecting => Icons.link_rounded,
      VoicePhase.listening => Icons.stop_rounded,
      VoicePhase.thinking => Icons.more_horiz_rounded,
      VoicePhase.speaking => Icons.graphic_eq_rounded,
      VoicePhase.ending => Icons.call_end_rounded,
      VoicePhase.error => Icons.refresh_rounded,
    };
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: label,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        backgroundColor: phase == VoicePhase.error
            ? colors.errorContainer
            : colors.primaryContainer,
        foregroundColor: tint,
      ),
      icon: AnimatedSwitcher(
        duration: duration,
        child: Icon(icon, key: ValueKey(icon)),
      ),
    );
  }
}

class AccessTab extends StatefulWidget {
  const AccessTab({super.key, required this.language});
  final String language;
  @override
  State<AccessTab> createState() => _AccessTabState();
}

class _AccessTabState extends State<AccessTab> {
  final features = LocalFeatures();
  List<Map<String, dynamic>>? apps;
  String search = '';
  String? error;
  bool loading = false;
  Future<void> scan() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await features.apps();
      if (mounted) setState(() => apps = data);
    } catch (e) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.accessUnavailable);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!Platform.isAndroid) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.unavailable,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.iosGuide,
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await PlatformDeviceReview().openSettings();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.settingsUnavailable,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(AppLocalizations.of(context)!.openSettings),
              ),
            ],
          ),
        ),
      );
    }
    final results = (apps ?? [])
        .where(
          (a) => ('${a['name']} ${a['package']}').toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: scan,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FilledButton.icon(
            onPressed: loading ? null : scan,
            icon: const Icon(Icons.manage_search),
            label: Text(AppLocalizations.of(context)!.scan),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.visibilityNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: TextStyle(color: scheme.error)),
          if (apps != null) ...[
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: AppLocalizations.of(context)!.search,
              ),
              onChanged: (value) => setState(() => search = value),
            ),
            const SizedBox(height: 12),
            for (final app in results)
              Card(
                child: ExpansionTile(
                  title: Text('${app['name']}'),
                  subtitle: Text('${app['package']} · ${app['version']}'),
                  children: [
                    for (final raw in app['permissions'] as List)
                      Builder(
                        builder: (context) {
                          final permission = Map<String, dynamic>.from(
                            raw as Map,
                          );
                          return ListTile(
                            title: Text(
                              '${permission['name']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              permission['granted'] == null
                                  ? AppLocalizations.of(context)!.unknown
                                  : permission['granted'] == true
                                  ? AppLocalizations.of(context)!.granted
                                  : AppLocalizations.of(context)!.notGranted,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await features.openApp(app['package'] as String);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.settingsUnavailable,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.openSettings),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class PreferencesSheet extends StatefulWidget {
  const PreferencesSheet({
    super.key,
    required this.language,
    required this.theme,
    required this.onLanguage,
    required this.onTheme,
  });
  final String language;
  final ThemeMode theme;
  final ValueChanged<String> onLanguage;
  final ValueChanged<ThemeMode> onTheme;
  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
  late String language = widget.language;
  late ThemeMode theme = widget.theme;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.settings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            itemHeight: null,
            initialValue: language,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.language,
            ),
            items: languages.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => language = v);
                widget.onLanguage(v);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ThemeMode>(
            isExpanded: true,
            itemHeight: null,
            initialValue: theme,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.theme,
            ),
            items: [
              for (final mode in ThemeMode.values)
                DropdownMenuItem(
                  value: mode,
                  child: Text(switch (mode) {
                    ThemeMode.system => AppLocalizations.of(context)!.system,
                    ThemeMode.light => AppLocalizations.of(context)!.light,
                    ThemeMode.dark => AppLocalizations.of(context)!.dark,
                  }),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => theme = v);
                widget.onTheme(v);
              }
            },
          ),
        ],
      ),
    ),
  );
}
