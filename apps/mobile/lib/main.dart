import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'employee_sign_in.dart';
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
import 'saved_chats.dart';
import 'reports_dashboard.dart';
import 'l10n/app_localizations.dart';

Future<FirebaseApp> initializeFirebase() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return Firebase.initializeApp();
  }
  return Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  const authenticated = bool.fromEnvironment(
    'FIREBASE_AUTH_REQUIRED',
    defaultValue: true,
  );
  FirebaseAuth? auth;
  if (authenticated) {
    try {
      await initializeFirebase();
      auth = FirebaseAuth.instance;
    } catch (_) {
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Firebase sign-in is unavailable.')),
          ),
        ),
      );
      return;
    }
  }
  final clientAuth = auth;
  runApp(
    AnuvachApp(
      prefs: prefs,
      api: Api(
        token: clientAuth == null
            ? null
            : () async {
                return await clientAuth.currentUser?.getIdToken();
              },
      ),
      auth: clientAuth,
    ),
  );
}

class AnuvachApp extends StatefulWidget {
  const AnuvachApp({
    super.key,
    required this.prefs,
    required this.api,
    this.auth,
  });
  final SharedPreferences prefs;
  final Api api;
  final FirebaseAuth? auth;
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
      if (Firebase.apps.isEmpty) {
        await initializeFirebase();
      }
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
      home: _home(),
    ),
  );

  Widget _home() {
    final auth = widget.auth;
    Home home([String? account]) => Home(
      key: ValueKey(account),
      account: account ?? 'local-demo',
      prefs: widget.prefs,
      api: widget.api,
      language: language,
      mode: mode,
      onLanguage: setLanguage,
      onTheme: setMode,
      autoStartVoice: true,
      onRefreshTranslations: () => remoteTranslations.refresh(force: true),
    );
    if (auth == null) return home();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return EmployeeSignIn(auth: auth);
        return home(snapshot.data!.uid);
      },
    );
  }
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
    this.autoStartVoice = false,
    this.account = 'local-demo',
  });
  final SharedPreferences prefs;
  final Api api;
  final String language;
  final ThemeMode mode;
  final ValueChanged<String> onLanguage;
  final ValueChanged<ThemeMode> onTheme;
  final Future<bool> Function()? onRefreshTranslations;
  final bool autoStartVoice;
  final String account;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final Draft draft = Draft(widget.prefs, widget.api);
  List<Json> reports = [];
  String? error;
  bool loading = false;
  int tab = 0;
  final pages = PageController();
  bool showReports = false;
  late final savedChats = SavedChats(widget.prefs, widget.account);
  String? startupChat;
  final scaffold = GlobalKey<ScaffoldState>();
  late bool consent = widget.prefs.getBool('consent') ?? false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startupChat = savedChats.active.id;
    if (consent) load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pages.dispose();
    draft.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && consent) load();
  }

  String get noticeKey => 'report_updates:${widget.account}';
  late final seenReports = widget.prefs.getStringList(noticeKey)?.toSet() ?? <String>{};
  String noticeId(Json report) => '${report['id']}:${report['updatedAt']}';
  List<Json> get unreadReports => reports.where((report) =>
      report['status'] != 'submitted' && !seenReports.contains(noticeId(report))).toList();

  Future<void> showReportUpdates() async {
    final unread = unreadReports;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(child: ListView(
        shrinkWrap: true,
        children: [
          for (final report in unread)
            ListTile(
              title: Text(report['id'] as String),
              subtitle: statusPill(report['status'] as String),
              onTap: () async {
                Navigator.pop(sheet);
                setState(() => seenReports.add(noticeId(report)));
                await widget.prefs.setStringList(noticeKey, seenReports.toList());
                if (!mounted) return;
                await Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => ReportDetail(api: widget.api, id: report['id'] as String),
                ));
              },
            ),
        ],
      )),
    );
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

  Future<void> reviewCheckStatement(String statement) async {
    if (draft.locked) {
      throw StateError(
        'Finish the pending submission before adding to this report.',
      );
    }
    final current = (draft.fields['description'] as String).trim();
    final combined = current.isEmpty || current == statement
        ? statement
        : '$current\n$statement';
    if (combined.length > 5000) {
      throw StateError(
        'Shorten the current report draft before adding this statement.',
      );
    }
    draft.update('description', combined);
    draft.update('language', 'english');
    await draft.save();
    if (mounted) await startReport();
  }

  Future<void> reviewVoiceTicket(Json proposal, String language) async {
    await draft.applyVoiceDraft(proposal, language);
    if (mounted) await startReport();
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

  Future<void> saveChat(SavedChat chat) {
    final write = savedChats.save(chat);
    if (mounted) setState(() {});
    return write;
  }

  Future<void> selectChat(SavedChat chat) async {
    setState(() {
      savedChats.active = chat;
      startupChat = null;
    });
    Navigator.pop(context);
    try {
      await savedChats.save();
    } catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (!consent) {
      return page(context, 'Anuvach.AI', [
        const Center(child: BrandMark(size: 64)),
        Center(child: eyebrow(strings.consentEyebrow)),
        Semantics(
          header: true,
          child: Text(
            strings.consentHeadline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
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
            Icon(Icons.info_outline, size: 18, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.voiceStartupNotice,
                style: theme.textTheme.bodySmall,
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final navigation = NavigationBar(
      height: MediaQuery.textScalerOf(
        context,
      ).scale(62).clamp(64, 94).toDouble(),
      animationDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      selectedIndex: tab,
      onDestinationSelected: (value) {
        FocusManager.instance.primaryFocus?.unfocus();
        // Skip intermediate tabs when selecting a non-adjacent destination.
        if (reduceMotion || (value - tab).abs() > 1) {
          pages.jumpToPage(value);
        } else {
          pages.animateToPage(
            value,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.graphic_eq_outlined),
          selectedIcon: const Icon(Icons.graphic_eq_rounded),
          label: strings.check,
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
    final activeChat = savedChats.active;
    return Scaffold(
      key: scaffold,
      drawer: tab == 0 ? chatDrawer(strings) : null,
      appBar: AppBar(
        title: const BrandMark(size: 36),
        actions: [
          if (tab == 1)
            IconButton(
              tooltip: strings.refreshReports,
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          if (unreadReports.isNotEmpty)
            IconButton(
              tooltip: 'Report updates',
              icon: Badge(label: Text('${unreadReports.length}'), child: const Icon(Icons.notifications_outlined)),
              onPressed: showReportUpdates,
            ),
          IconButton(
            tooltip: strings.theme,
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => widget.onTheme(
              theme.brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
          IconButton(
            tooltip: strings.language,
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => PreferencesSheet(
                language: widget.language,
                onLanguage: widget.onLanguage,
                onRefresh: kDebugMode ? widget.onRefreshTranslations : null,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : navigation,
      body: SafeArea(
        child: PageView(
          controller: pages,
          onPageChanged: (value) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => tab = value);
            if (value == 1) load();
          },
          children: [
            CheckTab(
              key: ValueKey(activeChat.id),
              language: widget.language,
              messages: activeChat.messages,
              api: widget.api,
              sessionId: activeChat.id,
              restoreContext: true,
              onMessagesChanged: () => saveChat(activeChat),
              reviewStatement: reviewCheckStatement,
              reviewVoiceTicket: reviewVoiceTicket,
              active: tab == 0,
              autoStartVoice:
                  widget.autoStartVoice && activeChat.id == startupChat,
            ),
            reportHistory(strings),
            AccessTab(language: widget.language, api: widget.api),
          ],
        ),
      ),
    );
  }

  Widget chatDrawer(AppLocalizations strings) => Drawer(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.edit_square),
            title: Text(strings.newChat),
            onTap: () => selectChat(SavedChat()),
          ),
          const Divider(),
          heading(strings.chats),
          for (final chat in savedChats.chats)
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: Text(
                chat.title ?? strings.chats,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              selected: chat == savedChats.active,
              onTap: () => selectChat(chat),
            ),
        ],
      ),
    ),
  );

  Widget reportHistory(AppLocalizations strings) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: const PageStorageKey('employee-reports'),
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.showReports),
              value: showReports,
              onChanged: (value) {
                setState(() => showReports = value);
                if (value) load();
              },
            ),
            OutlinedButton.icon(
              onPressed: startReport,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: Text(
                draft.locked
                    ? strings.pendingSubmission
                    : strings.describeIncident,
              ),
            ),
            if (draft.storageWarning != null) Text(draft.storageWarning!),
            if (!showReports)
              ReportsDashboard(
                reports: reports,
                loading: loading,
                hasError: error != null,
              ),
            if (showReports) ...[
              if (loading) const LinearProgressIndicator(minHeight: 2),
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cloud_off_outlined, color: colors.error),
                        const SizedBox(height: 8),
                        Text(error!, style: theme.textTheme.bodySmall),
                        TextButton(
                          onPressed: load,
                          child: Text(strings.tryAgain),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!loading && error == null && reports.isEmpty)
                InfoRow(
                  icon: Icons.inbox_outlined,
                  title: strings.noReports,
                  text: strings.reportHistoryHint,
                ),
              for (final r in reports)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    title: Text(
                      incidentLabel(
                        strings,
                        r['facts']['incidentType'] as String,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          r['facts']['description'] as String? ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(r['id'], style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            statusPill(r['status'] as String),
                            Text(
                              r['createdAt'] as String,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ReportDetail(api: widget.api, id: r['id']),
                        ),
                      );
                      if (mounted) load();
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String incidentLabel(AppLocalizations strings, String type) => switch (type) {
  'support_call' => strings.supportCall,
  'suspicious_message' => strings.suspiciousMessage,
  'mistaken_report' => strings.mistakenReport,
  'other' => strings.otherIncident,
  _ => type.replaceAll('_', ' '),
};

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
    final draftLanguage = draft.fields['language'];
    if (draftLanguage == 'hindi') return 'hi';
    if (languages.containsKey(draftLanguage)) return draftLanguage as String;
    return Localizations.localeOf(context).languageCode;
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  int voiceDraftRevision = 0;

  Future<void> useVoiceDraft(Json proposal, String language) async {
    await draft.applyVoiceDraft(proposal, language);
    if (!mounted) return;
    description.text = draft.fields['description'] as String;
    setState(() => voiceDraftRevision++);
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

  Widget reportField(String key, String label, int limit) {
    final isDescription = key == 'description';
    return TextFormField(
      key: isDescription
          ? const ValueKey('description')
          : ValueKey((key, voiceDraftRevision)),
      controller: isDescription ? description : null,
      initialValue: isDescription ? null : draft.fields[key],
      enabled: !draft.locked && !reviewing,
      minLines: key == 'appName' ? 1 : 3,
      maxLines: key == 'appName' ? 1 : 6,
      maxLength: limit,
      decoration: InputDecoration(labelText: label),
      textDirection: key != 'appName' && reportLanguage == 'ur'
          ? TextDirection.rtl
          : null,
      validator: isDescription
          ? (value) => (value ?? '').trim().length < 10
                ? AppLocalizations.of(context)!.descriptionTooShort
                : null
          : null,
      onChanged: (value) {
        draft.update(key, value);
        save();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return page(context, strings.describeIncident, [
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
            reportField('description', strings.descriptionLabel, 5000),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${strings.reportLanguageLabel}: ${strings.englishLanguage}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(('incidentType', voiceDraftRevision)),
              isExpanded: true,
              itemHeight: null,
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
                    child: Text(incidentLabel(strings, t)),
                  ),
              ],
              onChanged: draft.locked
                  ? null
                  : (v) {
                      draft.update('incidentType', v);
                      save();
                    },
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                '${strings.appNameLabel} · ${strings.evidenceNotesLabel}',
              ),
              leading: const Icon(Icons.notes_rounded),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              maintainState: true,
              initiallyExpanded: [
                draft.fields['appName'],
                draft.fields['evidenceNotes'],
              ].any((value) => value is String && value.isNotEmpty),
              children: [
                reportField('appName', strings.appNameOptional, 200),
                const SizedBox(height: 12),
                reportField(
                  'evidenceNotes',
                  strings.evidenceNotesOptional,
                  5000,
                ),
              ],
            ),
          ],
        ),
      ),
      ReportVoice(
        key: const ValueKey('report-voice'),
        api: draft.api,
        language: reportLanguage,
        enabled: !draft.locked && !reviewing,
        reviewTicket: useVoiceDraft,
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
          facts(snapshot, submitted: false),
          ...reportingTranscript(snapshot['reporting'] as Json?),
          SurfaceCard(
            tint: true,
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.reviewConfirmationIncluded),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(strings.reviewConfirmFacts),
                  value: d.confirmed,
                  onChanged: d.busy ? null : (v) => d.confirm(v ?? false),
                ),
              ],
            ),
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
  String translationLanguage = 'en';
  String? translated;
  bool translating = false;
  bool translationFailed = false;

  Future<void> translate() async {
    final requested = translationLanguage;
    setState(() {
      translating = true;
      translated = null;
      translationFailed = false;
    });
    try {
      final text = await widget.api.translateDescription(widget.id, requested);
      if (mounted) setState(() => translated = text);
    } catch (_) {
      if (mounted) setState(() => translationFailed = true);
    } finally {
      if (mounted) setState(() => translating = false);
    }
  }

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
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final current = report;
    return page(context, strings.detailTitle, [
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow(strings.ticketDetails),
            const SizedBox(height: 6),
            SelectableText(widget.id, style: theme.textTheme.titleMedium),
            if (current != null) ...[
              const Divider(),
              Semantics(
                liveRegion: true,
                child: statusPill(current['status'] as String),
              ),
              const SizedBox(height: 12),
              Text('${strings.submittedAt}: ${current['createdAt']}'),
              Text('${strings.updatedAt}: ${current['updatedAt']}'),
              Text(strings.timesInUtc, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
      if (loading) const LinearProgressIndicator(minHeight: 2),
      if (error != null)
        Semantics(
          liveRegion: true,
          child: Text(error!, style: TextStyle(color: theme.colorScheme.error)),
        ),
      OutlinedButton.icon(
        onPressed: loading ? null : load,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(strings.refreshStatus),
      ),
      if (current != null) ...[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading(strings.descriptionTranslation),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: translationLanguage,
                isExpanded: true,
                itemHeight: null,
                decoration: InputDecoration(labelText: strings.language),
                items: [
                  for (final language in languages.entries)
                    DropdownMenuItem(
                      value: language.key,
                      child: Text(language.value),
                    ),
                ],
                onChanged: translating
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          translationLanguage = value;
                          translated = null;
                          translationFailed = false;
                        });
                      },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: translating ? null : translate,
                icon: const Icon(Icons.translate_rounded),
                label: Text(strings.descriptionTranslation),
              ),
              if (translating) const LinearProgressIndicator(minHeight: 2),
              if (translationFailed)
                Text(strings.descriptionTranslationUnavailable),
              if (translated case final text?)
                SelectableText(
                  text,
                  textDirection: translationLanguage == 'ur'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
            ],
          ),
        ),
        facts(current['facts'] as Json),
      ],
    ]);
  }
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
