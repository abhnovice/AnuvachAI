import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
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
    this.onMessagesChanged,
    this.restoreContext = false,
  });

  final String language;
  final List<Json> messages;
  final Api api;
  final bool active;
  final bool autoStartVoice;
  final bool restoreContext;
  final Future<void> Function()? onMessagesChanged;
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
  void initState() {
    super.initState();
    if (widget.messages.isNotEmpty) scrollToLatest();
  }

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
    final messages = widget.messages;
    final onChanged = widget.onMessagesChanged;
    final history = reportingContext(messages);
    final api = widget.api;
    final body = {
      'sessionId': widget.sessionId,
      'language': widget.language,
      'text': text,
      if (widget.restoreContext) 'context': history,
    };
    setState(() {
      messages.add({'speaker': 'employee', 'text': text});
      busy = true;
      error = null;
      controller.clear();
    });
    scrollToLatest();
    try {
      await persist(onChanged);
      final response = await api.reportingTurn(body);
      messages.add({'speaker': 'agent', 'text': response['reply']});
      await persist(onChanged);
      if (mounted) {
        setState(() {});
        scrollToLatest();
        final ticketDraft = response['ticketDraft'];
        if (ticketDraft is Map<String, dynamic>) {
          await widget.reviewVoiceTicket(ticketDraft, widget.language);
        }
      }
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is ApiRequestException
              ? failure.message
              : failure.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> persist(Future<void> Function()? changed) async {
    try {
      await changed?.call();
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
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
    unawaited(persist(widget.onMessagesChanged));
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
      await persist(widget.onMessagesChanged);
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
      contextForVoice: widget.restoreContext
          ? () => reportingContext(widget.messages)
          : null,
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
                    if (widget.messages.any((turn) => turn['speaker'] == 'employee' && turn['captured'] != true))
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          onPressed: reviewing ? null : () => review(widget.messages
                            .where((turn) => turn['speaker'] == 'employee' && turn['captured'] != true)
                            .map((turn) => turn['text'] as String).toSet().join('\n')),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(strings.voiceDraft),
                        ),
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
  const AccessTab({super.key, required this.language, required this.api});
  final Api api;
  final String language;
  @override
  State<AccessTab> createState() => _AccessTabState();
}

class _AccessTabState extends State<AccessTab>
    with AutomaticKeepAliveClientMixin<AccessTab> {
  @override
  bool get wantKeepAlive => true;

  String? permissionFilter;
  String? briefing;
  bool briefingBusy = false;

  static const sensitive = {
    'CAMERA': ('Camera', Icons.camera_alt_outlined),
    'RECORD_AUDIO': ('Microphone', Icons.mic_none_rounded),
    'ACCESS_FINE_LOCATION': ('Location', Icons.location_on_outlined),
    'READ_CONTACTS': ('Contacts', Icons.contacts_outlined),
    'READ_SMS': ('Messages', Icons.message_outlined),
  };

  bool granted(Json app, String permission) =>
      (app['permissions'] as List).any((entry) =>
        entry['name'] == 'android.permission.$permission' && entry['granted'] == true);

  Future<void> loadBriefing() async {
    final inventory = apps;
    if (inventory == null || briefingBusy) return;
    setState(() => briefingBusy = true);
    try {
      final result = await widget.api.call('/reporting/access-briefing', body: {
        'language': widget.language,
        'visibleApps': inventory.length,
        'grants': {
          for (final permission in sensitive.keys)
            permission: inventory.where((app) => granted(app, permission)).length,
        },
      }) as Json;
      if (mounted && identical(apps, inventory)) setState(() => briefing = result['reply'] as String);
    } catch (_) {
      if (mounted) setState(() => briefing = AppLocalizations.of(context)!.accessBriefingUnavailable);
    } finally {
      if (mounted) setState(() => briefingBusy = false);
    }
  }
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
      if (mounted) setState(() { apps = data; briefing = null; });
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
        .where((app) => permissionFilter == null || granted(app, permissionFilter!))
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
          Text(strings.appInventoryCoverage, style: theme.textTheme.bodyMedium),
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
                    briefing ?? "Explain the permission counts Gemini will receive.",
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                  TextButton(
                    onPressed: briefingBusy || apps == null || loading ? null : loadBriefing,
                    child: Text(briefingBusy ? strings.checking : 'Get briefing'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SurfaceCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading('Sensitive permissions'),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in sensitive.entries)
                    FilterChip(
                      avatar: Icon(entry.value.$2, size: 18),
                      label: Text('${entry.value.$1} · ${apps == null ? "—" : apps!.where((app) => granted(app, entry.key)).length}'),
                      selected: permissionFilter == entry.key,
                      onSelected: apps == null ? null : (selected) => setState(() {
                        permissionFilter = selected ? entry.key : null;
                      }),
                    ),
                ],
              ),
            ],
          )),
          const SizedBox(height: 14),
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
            appGroup(
              strings.launcherApps,
              results.where((app) => app['launcherVisible'] == true),
              strings,
            ),
            appGroup(
              strings.nonLauncherApps,
              results.where((app) => app['launcherVisible'] == false),
              strings,
            ),
          ],
        ],
      ),
    );
  }

  Widget appGroup(String title, Iterable<Json> apps, AppLocalizations strings) {
    final categories = <String, List<Json>>{};
    for (final app in apps) {
      final category =
          app['category'] as String? ??
          (app['systemApp'] == true
              ? strings.systemApps
              : strings.uncategorizedApps);
      categories.putIfAbsent(category, () => []).add(app);
    }
    final ordered = categories.keys.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(title),
          if (categories.isEmpty) Text(strings.noMatchingApps),
          for (final category in ordered)
            Card(
              child: ExpansionTile(
                key: PageStorageKey((title, category)),
                title: Text(category),
                subtitle: Wrap(spacing: 5, children: [
                  for (final app in categories[category]!.take(6))
                    _AppPreview(key: ValueKey(app['package']), features: features, package: app['package'] as String),
                ]),

                children: [
                  for (final app in categories[category]!)
                    _InstalledAppTile(
                      key: ValueKey(app['package']),
                      app: app,
                      features: features,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AppPreview extends StatefulWidget {
  const _AppPreview({super.key, required this.features, required this.package});
  final LocalFeatures features;
  final String package;
  @override
  State<_AppPreview> createState() => _AppPreviewState();
}

class _AppPreviewState extends State<_AppPreview> {
  late final icon = widget.features.appIcon(widget.package);
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: icon,
    builder: (_, snapshot) => snapshot.data == null
      ? const Icon(Icons.android_rounded, size: 22)
      : Image.memory(snapshot.data!, width: 22, height: 22, excludeFromSemantics: true),
  );
}

class _InstalledAppTile extends StatefulWidget {
  const _InstalledAppTile({
    super.key,
    required this.app,
    required this.features,
  });
  final Json app;
  final LocalFeatures features;

  @override
  State<_InstalledAppTile> createState() => _InstalledAppTileState();
}

class _InstalledAppTileState extends State<_InstalledAppTile> {
  late final icon = widget.features.appIcon(widget.app['package'] as String);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final groups = <String, List<Json>>{};
    for (final raw in widget.app['permissions'] as List) {
      final permission = Map<String, dynamic>.from(raw as Map);
      final group = permission['group'] as String? ?? strings.otherPermissions;
      groups.putIfAbsent(group, () => []).add(permission);
    }
    return ExpansionTile(
      leading: FutureBuilder<Uint8List?>(
        future: icon,
        builder: (context, snapshot) => snapshot.data == null
            ? const Icon(Icons.android_rounded)
            : Image.memory(
                snapshot.data!,
                height: 34,
                width: 34,
                excludeFromSemantics: true,
              ),
      ),
      title: Text('${widget.app['name']}'),
      subtitle: Text('${widget.app['package']} · ${widget.app['version']}'),
      children: [
        for (final group in groups.entries)
          ExpansionTile(
            title: Text(group.key),
            children: [
              for (final permission in group.value)
                ListTile(
                  title: Text(
                    '${permission['name']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(switch (permission['granted']) {
                    true => strings.granted,
                    false => strings.notGranted,
                    _ => strings.unknown,
                  }),
                ),
            ],
          ),
        TextButton(
          onPressed: () async {
            try {
              await widget.features.openApp(widget.app['package'] as String);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.settingsUnavailable)),
                );
              }
            }
          },
          child: Text(strings.openAppSettings),
        ),
      ],
    );
  }
}

class PreferencesSheet extends StatefulWidget {
  const PreferencesSheet({
    super.key,
    required this.language,
    required this.onLanguage,
    this.onRefresh,
  });
  final String language;
  final ValueChanged<String> onLanguage;
  final Future<bool> Function()? onRefresh;
  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
  late String language = widget.language;
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
