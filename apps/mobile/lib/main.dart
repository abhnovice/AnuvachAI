import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'remote_localization_service.dart';
import 'remote_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reporting.dart';
import 'report_voice.dart';
import 'device_review.dart';
import 'design.dart';
import 'language.dart';
import 'new_tabs.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(AnuvachApp(prefs: prefs, api: Api()));
}

class AnuvachApp extends StatefulWidget {
  const AnuvachApp({super.key, required this.prefs, required this.api});
  final SharedPreferences prefs;
  final Api api;
  @override
  State<AnuvachApp> createState() => _AnuvachAppState();
}

class _AnuvachAppState extends State<AnuvachApp> {
  late final LocaleController localeController = LocaleController(widget.prefs);
  late final RemoteLocalizationService remoteTranslations =
      RemoteLocalizationService(widget.prefs);

  @override
  void initState() {
    super.initState();
    _initializeRemote();
  }

  Future<void> _initializeRemote() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (mounted) await remoteTranslations.initialize();
    } catch (error) {
      debugPrint('Firebase unavailable: $error');
    }
  }

  String get language => localeController.locale.languageCode;
  late ThemeMode mode = ThemeMode.values.firstWhere(
    (m) => m.name == widget.prefs.getString('theme_mode'),
    orElse: () => ThemeMode.system,
  );
  void setLanguage(String value) {
    localeController.setLanguage(value);
  }

  @override
  void dispose() {
    localeController.dispose();
    remoteTranslations.dispose();
    super.dispose();
  }

  void setMode(ThemeMode value) {
    setState(() => mode = value);
    widget.prefs.setString('theme_mode', value.name);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([localeController, remoteTranslations]),
    builder: (context, _) => MaterialApp(
      title: 'Anuvach.AI',
      debugShowCheckedModeBanner: false,
      theme: anuvachTheme(),
      darkTheme: anuvachDarkTheme(),
      themeMode: mode,
      locale: localeController.locale,
      localizationsDelegates: [
        RemoteAppLocalizationsDelegate(
          remoteTranslations.overrides,
          remoteTranslations.revision,
        ),
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Home(
        prefs: widget.prefs,
        api: widget.api,
        language: language,
        mode: mode,
        onLanguage: setLanguage,
        onTheme: setMode,
        onRefreshTranslations: () => remoteTranslations.refresh(force: true),
      ),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.prefs,
    required this.api,
    required this.language,
    required this.mode,
    required this.onLanguage,
    required this.onTheme,
    this.onRefreshTranslations,
  });
  final SharedPreferences prefs;
  final Api api;
  final String language;
  final ThemeMode mode;
  final ValueChanged<String> onLanguage;
  final ValueChanged<ThemeMode> onTheme;
  final Future<bool> Function()? onRefreshTranslations;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final Draft draft = Draft(widget.prefs, widget.api);
  List<Json> reports = [];
  String? error;
  bool loading = false;
  int tab = 0;
  final chatMessages = <String>[];
  late bool consent = widget.prefs.getBool('consent') ?? false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (consent) load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    draft.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && consent) load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.api.history();
      if (mounted) setState(() => reports = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> startReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ReportForm(draft: draft)),
    );
    if (mounted) {
      setState(() {});
      load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!consent) {
      final strings = AppLocalizations.of(context)!;
      return page(context, 'Anuvach.AI', [
        const Center(child: BrandMark(size: 64)),
        Center(child: eyebrow(strings.consentEyebrow)),
        Text(
          strings.consentHeadline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 28,
            height: 1.18,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.2,
            color: brandInk,
          ),
        ),
        Text(strings.consentIntro, textAlign: TextAlign.center),
        SurfaceCard(
          child: Column(
            children: [
              InfoRow(
                icon: Icons.edit_note_outlined,
                title: strings.consentWordsTitle,
                text: strings.consentWordsText,
              ),
              const Divider(height: 12),
              InfoRow(
                icon: Icons.fact_check_outlined,
                title: strings.consentChoiceTitle,
                text: strings.consentChoiceText,
              ),
              const Divider(height: 12),
              InfoRow(
                icon: Icons.storage_outlined,
                title: strings.consentStorageTitle,
                text: strings.consentStorageText,
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: brandTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.consentNotice,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: brandMuted,
                ),
              ),
            ),
          ],
        ),
        FilledButton(
          onPressed: () async {
            if (!await widget.prefs.setBool('consent', true)) return;
            if (!mounted) return;
            setState(() => consent = true);
            load();
          },
          child: Text(strings.consentContinue),
        ),
      ]);
    }
    final navigation = NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (value) {
        setState(() => tab = value);
        if (value == 1) load();
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.search),
          selectedIcon: const Icon(Icons.search_rounded),
          label: AppLocalizations.of(context)!.check,
        ),
        NavigationDestination(
          icon: const Icon(Icons.article_outlined),
          selectedIcon: const Icon(Icons.article_rounded),
          label: AppLocalizations.of(context)!.reports,
        ),
        NavigationDestination(
          icon: const Icon(Icons.apps_outlined),
          selectedIcon: const Icon(Icons.apps_rounded),
          label: AppLocalizations.of(context)!.apps,
        ),
      ],
    );
    if (tab != 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            tab == 0
                ? AppLocalizations.of(context)!.check
                : AppLocalizations.of(context)!.apps,
          ),
          actions: [
            if (kDebugMode && widget.onRefreshTranslations != null)
              IconButton(
                tooltip: 'Refresh translations (debug)',
                icon: const Icon(Icons.translate),
                onPressed: () => widget.onRefreshTranslations!(),
              ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.settings,
              icon: const Icon(Icons.tune),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => StatefulBuilder(
                  builder: (context, setSheetState) => PreferencesSheet(
                    language: widget.language,
                    theme: widget.mode,
                    onLanguage: (v) {
                      widget.onLanguage(v);
                      setSheetState(() {});
                    },
                    onTheme: (v) {
                      widget.onTheme(v);
                      setSheetState(() {});
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: navigation,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: tab == 0
                ? CheckTab(
                    key: const ValueKey('check'),
                    language: widget.language,
                    messages: chatMessages,
                  )
                : AccessTab(
                    key: const ValueKey('access'),
                    language: widget.language,
                  ),
          ),
        ),
      );
    }
    return page(
      context,
      'Anuvach.AI',
      [
        eyebrow('SYNTHETIC DEMO · EMPLOYEE'),
        if (tab == 0) ...[
          const SizedBox(height: 2),
          heading('Let’s take the\nnext step together.'),
          const Text(
            'Unexpected call or suspicious request?\nTell your security team what happened.',
          ),
          SurfaceCard(
            tint: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    eyebrow('START A REPORT'),
                    const Spacer(),
                    const Icon(
                      Icons.edit_note_rounded,
                      color: brandTeal,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'You don’t need to\nhave all the answers.',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.6,
                    color: brandInk,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Describe what you noticed. Review every fact before creating a ticket.',
                  style: TextStyle(
                    color: Color(0xff16483f),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: startReport,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: Text(
                    draft.locked
                        ? 'Retry reviewed report'
                        : 'Report an incident',
                  ),
                ),
              ],
            ),
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: brandTeal),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Voice conversation',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: brandInk,
                        ),
                      ),
                    ),
                    statusPill('Coming in Stage 3'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'A place to talk it through, in a later stage.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No microphone access or audio analysis in this stage.',
                  style: TextStyle(fontSize: 11, color: brandMuted),
                ),
              ],
            ),
          ),
        ] else ...[
          heading('Your reports'),
          const Text('Follow each ticket from submission to review.'),
          OutlinedButton.icon(
            onPressed: startReport,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Report an incident'),
          ),
        ],
        if (draft.storageWarning != null) Text(draft.storageWarning!),
        Row(
          children: [
            Expanded(
              child: Text(
                tab == 0 ? 'Recent reports' : 'Report history',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (tab == 0)
              TextButton(
                onPressed: () => setState(() => tab = 1),
                child: const Text('View all'),
              ),
          ],
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off_outlined, color: brandMuted),
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(fontSize: 12)),
                TextButton(onPressed: load, child: const Text('Try again')),
              ],
            ),
          ),
        if (!loading && error == null && reports.isEmpty)
          const SurfaceCard(
            child: InfoRow(
              icon: Icons.inbox_outlined,
              title: 'No reports yet.',
              text:
                  'Once submitted, your tickets and their latest status will appear here.',
            ),
          ),
        for (final r in (tab == 0 ? reports.take(3) : reports))
          Card(
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ReportDetail(api: widget.api, id: r['id']),
                  ),
                );
                load();
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          size: 20,
                          color: brandTeal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (r['facts']['incidentType'] as String).replaceAll(
                              '_',
                              ' ',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: brandInk,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: brandMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      r['id'],
                      style: const TextStyle(fontSize: 10, color: brandMuted),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        statusPill(r['status']),
                        const Spacer(),
                        Text(
                          (r['createdAt'] as String).substring(0, 10),
                          style: const TextStyle(
                            fontSize: 11,
                            color: brandMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (tab == 0)
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  icon: Icons.shield_outlined,
                  title: 'Safety guidance',
                  text: 'Pause. Verify through a known contact.',
                ),
                Text(
                  'If an unexpected caller asks you to install an app or share a code, pause and contact your organisation’s known helpdesk. Avoid putting passwords or session codes in a report.',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  'General guidance · not an incident conclusion',
                  style: TextStyle(fontSize: 11, color: brandMuted),
                ),
              ],
            ),
          ),
      ],
      navigation: navigation,
      storageId: 'employee:$tab',
      actions: [
        IconButton(
          tooltip: 'Refresh reports',
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

List<Widget> reportingTranscript(Json? reporting) {
  if (reporting == null) return [];
  return [
    heading('Reporting transcript'),
    for (final turn in reporting['transcript'] as List)
      Text(
        "${turn['speaker'] == 'agent' ? 'Reporting assistant' : 'Employee'}: ${turn['text']}",
      ),
    if ((reporting['unknowns'] as List).isNotEmpty)
      Text(
        "Remaining questions: ${(reporting['unknowns'] as List).join(' · ')}",
      ),
  ];
}

class ReportForm extends StatefulWidget {
  const ReportForm({super.key, required this.draft});
  final Draft draft;
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final form = GlobalKey<FormState>();
  bool reviewing = false;
  late final description = TextEditingController(
    text: draft.fields['description'] as String,
  );

  String get reportLanguage {
    final selected = draft.fields['language'] as String;
    final locale = Localizations.localeOf(context).languageCode;
    return switch (selected) {
      'english' => 'en',
      'hindi' => 'hi',
      'mixed' => languages.containsKey(locale) ? locale : 'en',
      _ => selected,
    };
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  void useVoiceStatement(String text) {
    final previous = description.text.trim();
    final combined = previous.isEmpty ? text : '$previous\n$text';
    if (combined.length > 5000) {
      setState(
        () => error = 'Shorten the draft before adding another statement.',
      );
      return;
    }
    description.text = combined;
    draft.update('description', combined);
    final earlier = draft.fields['reporting'] as Json?;
    final transcript = [
      ...?earlier?['transcript'] as List?,
      {'speaker': 'employee', 'text': text},
    ];
    draft.update('reporting', {
      'language': reportLanguage,
      'transcript': transcript
          .skip(transcript.length > 12 ? transcript.length - 12 : 0)
          .toList(),
      'unknowns': earlier?['unknowns'] ?? <String>[],
    });
    save();
  }

  String? error;
  bool checking = false;
  final DeviceReview device = PlatformDeviceReview();
  Draft get draft => widget.draft;
  Future<void> save() async {
    try {
      await draft.save();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => page(context, AppLocalizations.of(context)!.describeIncident, [
    const FlowSteps(current: 0),
    const SizedBox(height: 4),
    heading(AppLocalizations.of(context)!.whatHappened),
    Text(AppLocalizations.of(context)!.syntheticExample),
    if (error != null)
      Text(
        error!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    if (draft.locked) Text(AppLocalizations.of(context)!.pendingSubmission),
    Form(
      key: form,
      child: Column(
        children: [
          for (final spec in [
            ('description', AppLocalizations.of(context)!.whatHappened, 5000),
            ('appName', AppLocalizations.of(context)!.appNameOptional, 200),
            (
              'evidenceNotes',
              AppLocalizations.of(context)!.evidenceNotesOptional,
              5000,
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                key: ValueKey(spec.$1),
                controller: spec.$1 == 'description' ? description : null,
                initialValue: spec.$1 == 'description'
                    ? null
                    : draft.fields[spec.$1],
                enabled: !draft.locked && !reviewing,
                maxLines: spec.$1 == 'appName' ? 1 : 4,
                maxLength: spec.$3,
                decoration: InputDecoration(labelText: spec.$2),
                textDirection: spec.$1 != 'appName' && reportLanguage == 'ur'
                    ? TextDirection.rtl
                    : null,
                validator: (v) =>
                    spec.$1 == 'description' && (v ?? '').trim().length < 10
                    ? AppLocalizations.of(context)!.descriptionTooShort
                    : null,
                onChanged: (v) {
                  draft.update(spec.$1, v);
                  save();
                },
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: draft.fields['language'],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.reportLanguageLabel,
            ),
            items: [
              DropdownMenuItem(
                value: 'english',
                child: Text(AppLocalizations.of(context)!.englishLanguage),
              ),
              DropdownMenuItem(
                value: 'hindi',
                child: Text(AppLocalizations.of(context)!.hindiLanguage),
              ),
              DropdownMenuItem(
                value: 'mixed',
                child: Text(AppLocalizations.of(context)!.mixedLanguage),
              ),
              for (final language in languages.entries)
                if (language.key != 'en' && language.key != 'hi')
                  DropdownMenuItem(
                    value: language.key,
                    child: Text(language.value),
                  ),
            ],
            onChanged: draft.locked
                ? null
                : (v) {
                    draft.update('language', v);
                    setState(() {});
                    save();
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: draft.fields['incidentType'],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.incidentTypeLabel,
            ),
            items: [
              for (final t in [
                'support_call',
                'suspicious_message',
                'mistaken_report',
                'other',
              ])
                DropdownMenuItem(
                  value: t,
                  child: Text(switch (t) {
                    'support_call' => AppLocalizations.of(context)!.supportCall,
                    'suspicious_message' => AppLocalizations.of(
                      context,
                    )!.suspiciousMessage,
                    'mistaken_report' => AppLocalizations.of(
                      context,
                    )!.mistakenReport,
                    'other' => AppLocalizations.of(context)!.otherIncident,
                    _ => t,
                  }),
                ),
            ],
            onChanged: draft.locked
                ? null
                : (v) {
                    draft.update('incidentType', v);
                    save();
                  },
          ),
        ],
      ),
    ),
    ReportVoice(
      key: const ValueKey('report-voice'),
      api: draft.api,
      language: reportLanguage,
      enabled: !draft.locked && !reviewing,
      useStatement: useVoiceStatement,
    ),
    ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed:
                draft.locked ||
                    draft.assisting ||
                    (draft.fields['description'] as String).trim().isEmpty
                ? null
                : () async {
                    setState(() => error = null);
                    try {
                      await draft.askAgent(reportLanguage);
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => error =
                              'Reporting assistant unavailable. You can continue with text.',
                        );
                      }
                    }
                  },
            child: Text(
              draft.assisting
                  ? 'Asking reporting assistant…'
                  : 'Ask reporting assistant',
            ),
          ),
          ...reportingTranscript(draft.fields['reporting'] as Json?),
        ],
      ),
    ),
    SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(AppLocalizations.of(context)!.optionalDeviceReview),
          const SizedBox(height: 12),
          Text(
            device.available
                ? AppLocalizations.of(context)!.androidDeviceReview
                : AppLocalizations.of(context)!.iosDeviceReview,
          ),
          if (device.available)
            OutlinedButton(
              onPressed: draft.locked || checking
                  ? null
                  : () async {
                      final agreed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            AppLocalizations.of(context)!.allowOneCheck,
                          ),
                          content: Text(
                            AppLocalizations.of(context)!.checkExplanation,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                AppLocalizations.of(context)!.cancelAction,
                              ),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                AppLocalizations.of(context)!.checkAndInclude,
                              ),
                            ),
                          ],
                        ),
                      );
                      if (agreed != true || !mounted) return;
                      setState(() => checking = true);
                      try {
                        final observation = await device.checkSecureLock();
                        draft.update('observations', [observation]);
                        await save();
                      } catch (e) {
                        if (mounted) {
                          setState(() => error = 'Check unavailable: $e');
                        }
                      } finally {
                        if (mounted) setState(() => checking = false);
                      }
                    },
              child: Text(
                checking
                    ? AppLocalizations.of(context)!.checking
                    : AppLocalizations.of(context)!.reviewDeviceCheck,
              ),
            ),
          if ((draft.fields['observations'] as List).isNotEmpty) ...[
            Text(
              'Included check: secure screen lock · ${draft.fields['observations'][0]['checkedAt']}',
            ),
            TextButton(
              onPressed: draft.locked
                  ? null
                  : () {
                      draft.update('observations', <dynamic>[]);
                      save();
                      setState(() {});
                    },
              child: Text(AppLocalizations.of(context)!.removeObservation),
            ),
          ],
        ],
      ),
    ),
    FilledButton(
      onPressed: checking
          ? null
          : () async {
              if (!form.currentState!.validate()) return;
              try {
                await draft.save();
              } catch (e) {
                setState(() => error = e.toString());
                return;
              }
              draft.review();
              if (!context.mounted) return;
              setState(() => reviewing = true);
              final submitted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => Review(draft: draft)),
              );
              if (!context.mounted) return;
              setState(() => reviewing = false);
              if (submitted == true) Navigator.pop(context);
            },
      child: Text(AppLocalizations.of(context)!.reviewReport),
    ),
  ]);
}

class Review extends StatefulWidget {
  const Review({super.key, required this.draft});
  final Draft draft;
  @override
  State<Review> createState() => _ReviewState();
}

class _ReviewState extends State<Review> {
  late final Json snapshot = widget.draft.reviewed!;
  String? error;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.draft,
    builder: (context, _) {
      final d = widget.draft;
      final strings = AppLocalizations.of(context)!;
      return PopScope(
        canPop: !d.busy,
        child: page(context, strings.reviewBeforeSending, [
          const FlowSteps(current: 1),
          Text(strings.reviewFactsDescription),
          facts(snapshot),
          ...reportingTranscript(snapshot['reporting'] as Json?),
          Text(strings.reviewConfirmationIncluded),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.reviewConfirmFacts),
            value: d.confirmed,
            onChanged: d.busy ? null : (v) => d.confirm(v ?? false),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: !d.confirmed || d.busy
                ? null
                : () async {
                    try {
                      final report = await d.submit();
                      if (!context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ReportDetail(api: d.api, id: report['id']),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) setState(() => error = e.toString());
                    }
                  },
            child: Text(d.busy ? strings.submitting : strings.confirmAndSubmit),
          ),
          TextButton(
            onPressed: d.busy
                ? null
                : () {
                    d.confirm(false);
                    Navigator.pop(context, false);
                  },
            child: Text(
              d.locked ? strings.backDraftPreserved : strings.backToEdit,
            ),
          ),
        ]),
      );
    },
  );
}

class ReportDetail extends StatefulWidget {
  const ReportDetail({super.key, required this.api, required this.id});
  final Api api;
  final String id;
  @override
  State<ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<ReportDetail>
    with WidgetsBindingObserver {
  Json? report;
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await widget.api.detail(widget.id);
      if (mounted) setState(() => report = r);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => page(context, AppLocalizations.of(context)!.detailTitle, [
    eyebrow(AppLocalizations.of(context)!.ticketDetails),
    SelectableText(
      widget.id,
      style: const TextStyle(fontSize: 11, color: brandMuted),
    ),
    if (loading) const LinearProgressIndicator(),
    if (error != null) Text(error!),
    OutlinedButton(
      onPressed: loading ? null : load,
      child: Text(AppLocalizations.of(context)!.refreshStatus),
    ),
    if (report != null) ...[
      SurfaceCard(
        tint: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow(AppLocalizations.of(context)!.latestUpdate),
            const SizedBox(height: 12),
            heading(
              'Status: ${(report!['status'] as String).replaceAll('_', ' ')}',
            ),
            Text(
              'Submitted: ${report!['createdAt']}\nUpdated: ${report!['updatedAt']}\nTimes shown in UTC.',
            ),
          ],
        ),
      ),
      facts(report!['facts'] as Json),
    ],
  ]);
}

class Help extends StatelessWidget {
  const Help({super.key, required this.api, this.navigation});
  final Api api;
  final Widget? navigation;
  @override
  Widget build(
    BuildContext context,
  ) => page(context, AppLocalizations.of(context)!.helpTitle, [
    SurfaceCard(
      tint: true,
      child: InfoRow(
        icon: Icons.shield_outlined,
        title: AppLocalizations.of(context)!.stayInControl,
        text: AppLocalizations.of(context)!.helpIntro,
      ),
    ),
    heading(AppLocalizations.of(context)!.reportExplained),
    Text(AppLocalizations.of(context)!.helpStorage),
    Text(AppLocalizations.of(context)!.helpSettings),
    OutlinedButton(
      onPressed: () async {
        try {
          await PlatformDeviceReview().openSettings();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.settingsOpenError),
              ),
            );
          }
        }
      },
      child: Text(AppLocalizations.of(context)!.openAppSettings),
    ),
    ExpansionTile(
      title: Text(AppLocalizations.of(context)!.demoConnection),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${AppLocalizations.of(context)!.apiAddressLabel}: ${api.base}\n${AppLocalizations.of(context)!.apiBuildHint}',
          ),
        ),
      ],
    ),
    Text(AppLocalizations.of(context)!.helpRoles),
  ], navigation: navigation);
}
