import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'report_voice.dart';
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
  });

  final String language;
  final List<Json> messages;
  final Api api;
  final String sessionId;
  final Future<void> Function(String) reviewStatement;

  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  bool reviewing = false;
  String? error;

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
        setState(
          () => error =
              'Reporting assistant unavailable. You can still use your statement in a report.',
        );
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Reporting assistant'),
              ReportVoice(
                api: widget.api,
                language: widget.language,
                enabled: !reviewing,
                useStatement: (statement) => unawaited(review(statement)),
              ),
              for (final message in widget.messages)
                Align(
                  alignment: message['speaker'] == 'agent'
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  child: Card(
                    color: message['speaker'] == 'agent'
                        ? scheme.surfaceContainer
                        : scheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message['speaker'] == 'agent')
                            const Text('Reporting assistant'),
                          Text(message['text'] as String),
                          if (message['speaker'] == 'employee')
                            TextButton(
                              onPressed: reviewing
                                  ? null
                                  : () => review(message['text'] as String),
                              child: const Text('Use in report'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Text(error!, style: TextStyle(color: scheme.error)),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLength: 5000,
                    decoration: InputDecoration(
                      labelText: strings.message,
                      counterText: '',
                    ),
                    onSubmitted: send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: busy ? null : () => send(controller.text),
                  tooltip: strings.send,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
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
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.settings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          DropdownButtonFormField<String>(
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
