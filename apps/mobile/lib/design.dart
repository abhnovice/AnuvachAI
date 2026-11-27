import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;
import 'reporting.dart';
import 'l10n/app_localizations.dart';

const _teal = Color(0xff006b64);

ThemeData anuvachTheme() => _theme(Brightness.light);
ThemeData anuvachDarkTheme() => _theme(Brightness.dark);

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final canvas = dark ? const Color(0xff0e1620) : const Color(0xfff6f9fa);
  final scheme = ColorScheme.fromSeed(seedColor: _teal, brightness: brightness)
      .copyWith(
        primary: dark ? const Color(0xff76e3d6) : _teal,
        onPrimary: dark ? const Color(0xff003832) : Colors.white,
        primaryContainer: dark
            ? const Color(0xff12453f)
            : const Color(0xffcdf5ee),
        onPrimaryContainer: dark
            ? const Color(0xffb6f3e9)
            : const Color(0xff003b35),
        surface: canvas,
        secondaryContainer: dark
            ? const Color(0xff203c41)
            : const Color(0xffdeeeed),
        surfaceContainerLow: dark ? const Color(0xff141f2a) : Colors.white,
        surfaceContainer: dark
            ? const Color(0xff192632)
            : const Color(0xffedf3f5),
        surfaceContainerHigh: dark
            ? const Color(0xff223342)
            : const Color(0xffe5edef),
        onSurface: dark ? const Color(0xffe7eef5) : const Color(0xff142430),
        onSurfaceVariant: dark
            ? const Color(0xffb2c2cc)
            : const Color(0xff435761),
        outlineVariant: dark
            ? const Color(0xff374a57)
            : const Color(0xffcddadf),
        surfaceTint: Colors.transparent,
      );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    colorScheme: scheme,
  );
  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    textTheme: base.textTheme
        .copyWith(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -.8,
            color: scheme.onSurface,
            height: 1.2,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: scheme.onSurfaceVariant,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        )
        .apply(fontFamily: 'NotoSans'),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      counterStyle: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.secondaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 28),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      iconColor: scheme.primary,
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Anuvach.AI',
    image: true,
    child: Image.asset(
      'assets/branding/anuvach-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.primary
          : null,
      colorBlendMode: BlendMode.srcIn,
      excludeFromSemantics: true,
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.tint = false,
    this.padding = 22,
  });
  final Widget child;
  final bool tint;
  final double padding;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: tint ? colors.surfaceContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

Widget heading(String text) => Builder(
  builder: (context) => Semantics(
    header: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.3),
    ),
  ),
);
Widget eyebrow(String text) => Builder(
  builder: (context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
);
String reportStatus(AppLocalizations strings, String status) =>
    switch (status) {
      'submitted' => strings.statusSubmitted,
      'in_review' => strings.statusInReview,
      'awaiting_employee' => strings.statusAwaitingEmployee,
      'escalated' => strings.statusEscalated,
      'closed' => strings.statusClosed,
      _ => status.replaceAll('_', ' '),
    };

Widget statusPill(String status) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          reportStatus(AppLocalizations.of(context)!, status),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  },
);

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class FlowSteps extends StatelessWidget {
  const FlowSteps({super.key, required this.current});
  final int current;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context)!;
    final labels = [
      strings.stepDescribe,
      strings.stepReview,
      strings.stepSubmit,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                selected: i == current,
                child: Column(
                  children: [
                    Divider(
                      height: 8,
                      thickness: 3,
                      color: i <= current
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: i == current
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget page(
  BuildContext context,
  String title,
  List<Widget> children, {
  List<Widget>? actions,
  Widget? navigation,
  String? storageId,
}) => Scaffold(
  appBar: AppBar(
    title: Text(title),
    actions: actions,
    toolbarHeight: 68,
    leading: navigation == null
        ? null
        : const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20, 16, 0, 16),
            child: BrandMark(size: 36),
          ),
    leadingWidth: navigation == null ? null : 62,
  ),
  bottomNavigationBar: navigation,
  body: SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: PageStorageKey(storageId ?? title),
          padding: const EdgeInsetsDirectional.fromSTEB(22, 12, 22, 28),
          children: children
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    ),
  ),
);
Widget facts(Json data, {bool submitted = true}) => Builder(
  builder: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (submitted) ...[
              eyebrow(AppLocalizations.of(context)!.submittedStatements),
              const SizedBox(height: 8),
            ],
            heading(AppLocalizations.of(context)!.employeeReported),
            const SizedBox(height: 18),
            for (final key in [
              'description',
              'language',
              'incidentType',
              'appName',
              'evidenceNotes',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      {
                        'description': AppLocalizations.of(
                          context,
                        )!.descriptionLabel,
                        'language': AppLocalizations.of(
                          context,
                        )!.reportLanguageLabel,
                        'incidentType': AppLocalizations.of(
                          context,
                        )!.incidentTypeLabel,
                        'appName': AppLocalizations.of(context)!.appNameLabel,
                        'evidenceNotes': AppLocalizations.of(
                          context,
                        )!.evidenceNotesLabel,
                      }[key]!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (data[key] == '')
                      Text(AppLocalizations.of(context)!.notSupplied)
                    else
                      SelectableText(
                        '${data[key]}',
                        textDirection:
                            Bidi.detectRtlDirectionality('${data[key]}')
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        textAlign:
                            Directionality.of(context) == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                  ],
                ),
              ),
            Text(
              AppLocalizations.of(context)!.demoEmployeeIdentity,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow(AppLocalizations.of(context)!.optionalChecks),
            const SizedBox(height: 8),
            heading(AppLocalizations.of(context)!.deviceObserved),
            const SizedBox(height: 14),
            if ((data['observations'] as List).isEmpty)
              Text(AppLocalizations.of(context)!.noDeviceFacts),
            for (final o in data['observations'] as List)
              InfoRow(
                icon: Icons.phonelink_lock_outlined,
                title:
                    '${AppLocalizations.of(context)!.secureScreenLock}: ${o['value'] ? AppLocalizations.of(context)!.configured : AppLocalizations.of(context)!.notConfigured}',
                text:
                    '${AppLocalizations.of(context)!.publicApiClientReported}\n${AppLocalizations.of(context)!.checkedAt}: ${o['checkedAt']}',
              ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.observationDisclaimer,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
