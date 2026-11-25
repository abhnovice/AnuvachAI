import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reporting.dart';
import 'device_review.dart';
import 'design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(AnuvachApp(prefs: prefs, api: Api()));
}

class AnuvachApp extends StatelessWidget {
  const AnuvachApp({super.key, required this.prefs, required this.api});
  final SharedPreferences prefs;
  final Api api;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Anuvach.AI',
    debugShowCheckedModeBanner: false,
    theme: anuvachTheme(),
    home: Home(prefs: prefs, api: api),
  );
}

class Home extends StatefulWidget {
  const Home({super.key, required this.prefs, required this.api});
  final SharedPreferences prefs;
  final Api api;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final Draft draft = Draft(widget.prefs, widget.api);
  List<Json> reports = [];
  String? error;
  bool loading = false;
  int tab = 0;
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
      return page(context, 'Anuvach.AI', [
        const Center(child: BrandMark(size: 64)),
        Center(child: eyebrow('EMPLOYEE INCIDENT REPORTING')),
        const Text(
          'A clear account.\nA safer next step.',
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
        const Text(
          'Something felt wrong? Start here.\nDescribe it in your words, then review before sharing.',
          textAlign: TextAlign.center,
        ),
        const SurfaceCard(
          child: Column(
            children: [
              InfoRow(
                icon: Icons.edit_note_outlined,
                title: 'Your words, your report',
                text:
                    'Description, language, incident type, and optional app and evidence notes.',
              ),
              Divider(height: 12),
              InfoRow(
                icon: Icons.fact_check_outlined,
                title: 'You choose what to share',
                text:
                    'Device checks are optional. Nothing is submitted until you review and confirm.',
              ),
              Divider(height: 12),
              InfoRow(
                icon: Icons.storage_outlined,
                title: 'Stored locally for this demo',
                text:
                    'Drafts stay on this device. Submitted reports go to the local API for administrator review.',
              ),
            ],
          ),
        ),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: brandTeal),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Synthetic demonstration only. Do not enter real employee information. No sign-in or production access controls. No audio is recorded or analysed.',
                style: TextStyle(fontSize: 12, height: 1.5, color: brandMuted),
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
          child: const Text('I understand · Continue'),
        ),
      ]);
    }
    final navigation = NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (value) {
        setState(() => tab = value);
        if (value != 2) load();
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article_rounded),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.help_outline),
          selectedIcon: Icon(Icons.help_rounded),
          label: 'Help',
        ),
      ],
    );
    if (tab == 2) return Help(api: widget.api, navigation: navigation);
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: brandInk,
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

class ReportForm extends StatefulWidget {
  const ReportForm({super.key, required this.draft});
  final Draft draft;
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final form = GlobalKey<FormState>();
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
  Widget build(BuildContext context) => page(context, 'Describe the incident', [
    const FlowSteps(current: 0),
    const SizedBox(height: 4),
    heading('What happened?'),
    const Text(
      'Use synthetic details only. Example: an unexpected IT-support caller asked you to install a remote-access app or share a code.',
    ),
    if (error != null)
      Text(
        error!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    if (draft.locked)
      const Text(
        'A submission may already have reached the API. Retry the preserved reviewed report to retrieve its ticket safely. Editing is paused until this is resolved.',
      ),
    Form(
      key: form,
      child: Column(
        children: [
          for (final spec in [
            ('description', 'What happened?', 5000),
            ('appName', 'App name (optional)', 200),
            ('evidenceNotes', 'Evidence notes (optional)', 5000),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                key: ValueKey(spec.$1),
                initialValue: draft.fields[spec.$1],
                enabled: !draft.locked,
                maxLines: spec.$1 == 'appName' ? 1 : 4,
                maxLength: spec.$3,
                decoration: InputDecoration(labelText: spec.$2),
                validator: (v) =>
                    spec.$1 == 'description' && (v ?? '').trim().length < 10
                    ? 'Describe the incident in at least 10 characters.'
                    : null,
                onChanged: (v) {
                  draft.update(spec.$1, v);
                  save();
                },
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: draft.fields['language'],
            decoration: const InputDecoration(labelText: 'Report language'),
            items: const [
              DropdownMenuItem(value: 'english', child: Text('English')),
              DropdownMenuItem(value: 'hindi', child: Text('Hindi')),
              DropdownMenuItem(
                value: 'mixed',
                child: Text('Mixed English / Hindi'),
              ),
            ],
            onChanged: draft.locked
                ? null
                : (v) {
                    draft.update('language', v);
                    save();
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: draft.fields['incidentType'],
            decoration: const InputDecoration(labelText: 'Incident type'),
            items: [
              for (final t in [
                'support_call',
                'suspicious_message',
                'mistaken_report',
                'other',
              ])
                DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))),
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
    SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading('Optional device review'),
          const SizedBox(height: 12),
          Text(
            device.available
                ? 'With your consent, check whether Android reports a secure screen lock. This does not check installed remote-access apps or permission use.'
                : 'Automatic device checks are unavailable on iOS in this stage. Review installed apps and permissions manually in Settings, or contact your known helpdesk.',
          ),
          if (device.available)
            OutlinedButton(
              onPressed: draft.locked || checking
                  ? null
                  : () async {
                      final agreed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Allow this one check?'),
                          content: const Text(
                            'Read secure screen-lock configuration now and include its result and timestamp in your report. No runtime permission is needed.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Check and include'),
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
                checking ? 'Checking…' : 'Review and consent to device check',
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
              child: const Text('Remove device observation'),
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
              final submitted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => Review(draft: draft)),
              );
              if (submitted == true && context.mounted) Navigator.pop(context);
            },
      child: const Text('Review report'),
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
      return PopScope(
        canPop: !d.busy,
        child: page(context, 'Review before sending', [
          const FlowSteps(current: 1),
          const Text(
            'These are the exact report facts to be sent. The API adds a ticket ID, timestamps and initial status.',
          ),
          facts(snapshot),
          const Text('Submission includes your explicit confirmation: true.'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I confirm these facts and want to create this ticket.',
            ),
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
            child: Text(d.busy ? 'Submitting…' : 'Confirm and submit'),
          ),
          TextButton(
            onPressed: d.busy
                ? null
                : () {
                    d.confirm(false);
                    Navigator.pop(context, false);
                  },
            child: Text(d.locked ? 'Back · draft preserved' : 'Back to edit'),
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
  Widget build(BuildContext context) => page(context, 'Report detail', [
    eyebrow('TICKET DETAILS'),
    SelectableText(
      widget.id,
      style: const TextStyle(fontSize: 11, color: brandMuted),
    ),
    if (loading) const LinearProgressIndicator(),
    if (error != null) Text(error!),
    OutlinedButton(
      onPressed: loading ? null : load,
      child: const Text('Refresh status'),
    ),
    if (report != null) ...[
      SurfaceCard(
        tint: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow('LATEST UPDATE'),
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
  ) => page(context, 'Help, privacy and settings', [
    const SurfaceCard(
      tint: true,
      child: InfoRow(
        icon: Icons.shield_outlined,
        title: 'You stay in control.',
        text:
            'Know what is shared, what is stored, and what this stage can check.',
      ),
    ),
    heading('Your report, explained'),
    const Text(
      'Use synthetic data only. Drafts are stored locally in app preferences, without encryption. Submitted facts are stored by the local API in SQLite. Administrator notes stay in the administrator view. This demonstration has no authentication.',
    ),
    const Text(
      'Opening settings does not change any setting. On Android you can inspect this app’s settings; on iOS you can open this app’s Settings page. Review other apps and permissions manually through system Settings. A visible permission does not prove it was used.',
    ),
    OutlinedButton(
      onPressed: () async {
        try {
          await PlatformDeviceReview().openSettings();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not open settings. Open system Settings manually. $e',
                ),
              ),
            );
          }
        }
      },
      child: const Text('Open this app’s settings'),
    ),
    ExpansionTile(
      title: const Text('Demo connection'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'API address: ${api.base}\nSet API_BASE_URL at build/run time.',
          ),
        ),
      ],
    ),
    const Text(
      'Security and data protection are separate reviewer roles in the demonstration model. Real employee data requires server-enforced access control and a defined retention policy.',
    ),
  ], navigation: navigation);
}
