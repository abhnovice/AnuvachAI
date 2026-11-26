import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'language.dart';
import 'local_features.dart';
import 'l10n/app_localizations.dart';
import 'device_review.dart';

class CheckTab extends StatefulWidget {
  const CheckTab({super.key, required this.language, required this.messages});
  final String language;
  final List<String> messages;
  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab> with WidgetsBindingObserver {
  final features = LocalFeatures();
  final controller = TextEditingController();
  bool active = false;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && active) {
      features.stopMicrophone();
      setState(() => active = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    features.stopMicrophone();
    controller.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (active) {
        await features.stopMicrophone();
        if (mounted) setState(() => active = false);
      } else {
        final started = await features.startMicrophone(widget.language);
        if (!mounted) {
          if (started) await features.stopMicrophone();
          return;
        }
        setState(() => active = started);
        if (!started) {
          setState(() => error = AppLocalizations.of(context)!.micDenied);
        }
      }
    } on PlatformException {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.micUnavailable);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) => Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      widget.messages[index],
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
              if (widget.messages.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        tooltip: (active
                            ? AppLocalizations.of(context)!.stop
                            : AppLocalizations.of(context)!.start),
                        onPressed: busy ? null : toggle,
                        iconSize: 38,
                        padding: const EdgeInsets.all(25),
                        icon: Icon(
                          active ? Icons.stop_rounded : Icons.mic_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        active
                            ? AppLocalizations.of(context)!.local
                            : AppLocalizations.of(context)!.soon,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (widget.messages.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: busy ? null : toggle,
                tooltip: (active
                    ? AppLocalizations.of(context)!.stop
                    : AppLocalizations.of(context)!.start),
                icon: Icon(active ? Icons.stop_circle : Icons.mic),
              ),
              Flexible(
                child: Text(
                  active
                      ? AppLocalizations.of(context)!.local
                      : AppLocalizations.of(context)!.soon,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(error!, style: TextStyle(color: scheme.error)),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await PlatformDeviceReview().openSettings();
                    } catch (e) {
                      if (mounted) {
                        setState(
                          () => error = AppLocalizations.of(
                            context,
                          )!.settingsUnavailable,
                        );
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.openSettings),
                ),
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
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.message,
                    ),
                    onSubmitted: send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => send(controller.text),
                  tooltip: AppLocalizations.of(context)!.send,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void send(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    setState(() => widget.messages.add(text));
    controller.clear();
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
