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
    this.active = true,
    this.autoStartVoice = false,
  });

  final String language;
  final List<Json> messages;
  final Api api;
  final bool active;
  final bool autoStartVoice;
  final String sessionId;
  final Future<void> Function(String) reviewStatement;
  final Future<void> Function(Json, String) reviewVoiceTicket;

  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab>
    with AutomaticKeepAliveClientMixin<CheckTab> {
  @override
  bool get wantKeepAlive => true;

  final composerFocus = FocusNode();
  final controller = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  bool reviewing = false;
  String? error;
  String lastPreview = '';

  @override
  void dispose() {
    composerFocus.dispose();
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
  Widget build(BuildContext context) {
    super.build(context);
    return ReportVoice(
      api: widget.api,
      language: widget.language,
      enabled: widget.active && !reviewing,
      autoStart: widget.autoStartVoice,
      reviewTicket: widget.reviewVoiceTicket,
      onTurn: addVoiceTurn,
      conversation: buildConversation,
    );
  }

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
    final showWelcome =
        voice.employeePreview.isEmpty &&
        !voice.hasDraft &&
        !widget.messages.any((turn) => turn['speaker'] == 'employee');
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
                    if (showWelcome)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: empty
                              ? math.max(0, viewport.maxHeight - 24)
                              : 0,
                        ),
                        child: Center(
                          child: welcome(strings, theme, reduceMotion, voice),
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
                        child: Wrap(
                          key: ValueKey(stateLabel),
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            if (phase == VoicePhase.connecting ||
                                phase == VoicePhase.thinking ||
                                phase == VoicePhase.speaking ||
                                phase == VoicePhase.listening)
                              _VoiceActivity(
                                key: ValueKey(phase),
                                animate: !reduceMotion,
                              ),
                            Text(
                              stateLabel,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: phase == VoicePhase.error
                                    ? colors.error
                                    : colors.primary,
                              ),
                            ),
                          ],
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
                            focusNode: composerFocus,
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

  Widget welcome(
    AppLocalizations strings,
    ThemeData theme,
    bool reduceMotion,
    VoiceView voice,
  ) {
    return _ConversationReveal(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VoiceEmphasis(
            animate: !reduceMotion && voice.microphone != null && !voice.active,
            child: IconButton(
              tooltip: strings.voiceLogoStart,
              onPressed: voice.active ? null : voice.microphone,
              icon: const ExcludeSemantics(child: BrandMark(size: 68)),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: _TypingTitle(
              key: ValueKey(strings.voiceWelcome),
              text: strings.voiceWelcome,
              style: theme.textTheme.headlineMedium,
              animate: !reduceMotion,
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
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final (label, prompt) in [
                (strings.supportCall, strings.callPrompt),
                (strings.suspiciousMessage, strings.messagePrompt),
              ])
                ActionChip(
                  label: Text(label),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      controller.text = '$prompt ';
                      controller.selection = TextSelection.collapsed(
                        offset: controller.text.length,
                      );
                    }
                    composerFocus.requestFocus();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingTitle extends StatelessWidget {
  const _TypingTitle({
    super.key,
    required this.text,
    this.style,
    required this.animate,
  });
  final String text;
  final TextStyle? style;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return Text(text, style: style, textAlign: TextAlign.center);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        child: Opacity(
          opacity: 0,
          child: Text(text, style: style, textAlign: TextAlign.center),
        ),
        builder: (context, value, child) => Stack(
          alignment: Alignment.topCenter,
          children: [
            child!,
            Text(
              text.characters
                  .take((text.characters.length * value).ceil())
                  .join(),
              style: style,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceEmphasis extends StatelessWidget {
  const _VoiceEmphasis({required this.animate, required this.child});
  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      key: ValueKey(animate),
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate ? const Duration(milliseconds: 1050) : Duration.zero,
      child: child,
      builder: (context, value, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: math.sin(value * math.pi) * .26),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _VoiceActivity extends StatelessWidget {
  const _VoiceActivity({super.key, required this.animate});
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: animate ? const Duration(milliseconds: 780) : Duration.zero,
        builder: (context, progress, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 3,
                height: progress == 1
                    ? [5.0, 10.0, 7.0][i]
                    : 5 + 7 * math.sin((progress * 2 + i / 3) * math.pi).abs(),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
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
    return _VoiceEmphasis(
      animate:
          duration != Duration.zero &&
          phase == VoicePhase.idle &&
          onPressed != null,
      child: IconButton.filledTonal(
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

class _AccessTabState extends State<AccessTab>
    with AutomaticKeepAliveClientMixin<AccessTab> {
  @override
  bool get wantKeepAlive => true;

  bool showSettings = true;
  bool showApps = true;
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
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = AppLocalizations.of(context)!;
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
          heading(strings.accessOverview),
          const SizedBox(height: 4),
          Text(strings.visibilityNote, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.accessBriefing,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.accessBriefingUnavailable,
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              title: Text(strings.settings),
              secondary: const Icon(Icons.settings_outlined),
              value: showSettings,
              onChanged: (value) => setState(() => showSettings = value),
            ),
          ),
          if (showSettings)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await PlatformDeviceReview().openSettings();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.settingsUnavailable)),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(strings.openAppSettings),
              ),
            ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              title: Text(strings.apps),
              secondary: const Icon(Icons.apps_outlined),
              value: showApps,
              onChanged: (value) => setState(() => showApps = value),
            ),
          ),
          if (showApps) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading ? null : scan,
              icon: const Icon(Icons.manage_search),
              label: Text(strings.scan),
            ),
            const SizedBox(height: 12),
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
    this.onRefresh,
  });
  final String language;
  final ThemeMode theme;
  final ValueChanged<String> onLanguage;
  final ValueChanged<ThemeMode> onTheme;
  final Future<bool> Function()? onRefresh;
  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
  late String language = widget.language;
  bool? darkOverride;
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
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.theme),
            secondary: const Icon(Icons.light_mode_outlined),
            value:
                darkOverride ??
                (widget.theme == ThemeMode.dark ||
                    (widget.theme != ThemeMode.light &&
                        Theme.of(context).brightness == Brightness.dark)),
            onChanged: (dark) {
              setState(() => darkOverride = dark);
              widget.onTheme(dark ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          if (widget.onRefresh case final refresh?)
            TextButton(
              onPressed: refresh,
              child: const Text('Refresh translations (debug)'),
            ),
        ],
      ),
    ),
  );
}
