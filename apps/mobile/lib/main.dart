import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reporting.dart';
import 'device_review.dart';

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
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087e8b)),
      scaffoldBackgroundColor: const Color(0xfff1f7f8),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: Home(prefs: prefs, api: api),
  );
}

Widget page(
  BuildContext context,
  String title,
  List<Widget> children, {
  List<Widget>? actions,
}) => Scaffold(
  appBar: AppBar(title: Text(title), actions: actions),
  body: SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: children
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    ),
  ),
);
Widget heading(String text) => Text(
  text,
  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
);
Widget facts(Json data) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    heading('Employee reported'),
    for (final key in [
      'description',
      'language',
      'incidentType',
      'appName',
      'evidenceNotes',
    ])
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SelectableText(
          '${{'description': 'Description', 'language': 'Report language', 'incidentType': 'Incident type', 'appName': 'App name', 'evidenceNotes': 'Evidence notes'}[key]}\n${data[key] == '' ? 'Not supplied' : data[key]}',
        ),
      ),
    const Text('Employee identity: demo-employee'),
    const SizedBox(height: 20),
    heading('Device observed'),
    if ((data['observations'] as List).isEmpty)
      const Text('No automatic device facts included.'),
    for (final o in data['observations'] as List)
      Text(
        'Secure screen lock: ${o['value'] ? 'configured' : 'not configured'}\nAndroid public API · client-reported\nChecked: ${o['checkedAt']}',
      ),
    const SizedBox(height: 12),
    const Text(
      'These observations do not establish remote access, compromise, or whether a permission was used.',
    ),
  ],
);

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

  @override
  Widget build(BuildContext context) {
    if (!consent) {
      return page(context, 'Welcome to Anuvach.AI', [
        const Icon(
          Icons.forum_outlined,
          size: 64,
          semanticLabel: 'Replaceable Anuvach.AI logo placeholder',
        ),
        heading('A clear account. A safer next step.'),
        const Text(
          'Synthetic demonstration only. Do not enter real employee information.',
        ),
        const Text(
          'A report contains what you describe, your chosen language and incident type, optional app and evidence notes, and only the device check results you choose to include. It is sent to the local API for administrator review.',
        ),
        const Text(
          'Drafts are saved on this device. Submitted reports are stored in local SQLite. This demo has no sign-in or production access controls. No audio is recorded or analysed.',
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
    return page(context, 'Anuvach.AI', [
      const Text('SYNTHETIC DEMO · EMPLOYEE'),
      heading('Tell us what happened.'),
      const Text('You can review every fact before creating a ticket.'),
      if (draft.storageWarning != null) Text(draft.storageWarning!),
      FilledButton.icon(
        icon: const Icon(Icons.edit_note),
        label: Text(
          draft.locked ? 'Retry reviewed report' : 'Report an incident',
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ReportForm(draft: draft)),
          );
          if (mounted) {
            setState(() {});
            load();
          }
        },
      ),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice conversation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Coming in Stage 3'),
              Text('No microphone access or audio analysis in this stage.'),
            ],
          ),
        ),
      ),
      heading('Safety guidance'),
      const Text(
        'If an unexpected caller asks you to install an app or share a code, pause and verify through your organisation’s known helpdesk contact. Avoid sharing passwords or session codes in this report. This is general guidance, not an incident conclusion.',
      ),
      Row(
        children: [
          Expanded(child: heading('Recent reports')),
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      if (loading) const LinearProgressIndicator(),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (!loading && error == null && reports.isEmpty)
        const Text('No reports yet.'),
      for (final r in reports)
        Card(
          child: ListTile(
            title: Text(r['id']),
            subtitle: Text('${r['status']} · ${r['createdAt']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportDetail(api: widget.api, id: r['id']),
                ),
              );
              load();
            },
          ),
        ),
      OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => Help(api: widget.api)),
        ),
        child: const Text('Help, privacy and settings'),
      ),
    ]);
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
    heading('Optional device review'),
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
                  if (mounted) setState(() => error = 'Check unavailable: $e');
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
    SelectableText(widget.id),
    if (loading) const LinearProgressIndicator(),
    if (error != null) Text(error!),
    OutlinedButton(
      onPressed: loading ? null : load,
      child: const Text('Refresh status'),
    ),
    if (report != null) ...[
      heading('Status: ${report!['status']}'),
      Text(
        'Submitted: ${report!['createdAt']}\nUpdated: ${report!['updatedAt']}\nTimes shown in UTC.',
      ),
      facts(report!['facts'] as Json),
    ],
  ]);
}

class Help extends StatelessWidget {
  const Help({super.key, required this.api});
  final Api api;
  @override
  Widget build(
    BuildContext context,
  ) => page(context, 'Help, privacy and settings', [
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
    Text('API address: ${api.base}\nSet API_BASE_URL at build/run time.'),
    const Text(
      'Security and data protection are separate reviewer roles in the demonstration model. Real employee data requires server-enforced access control and a defined retention policy.',
    ),
  ]);
}
