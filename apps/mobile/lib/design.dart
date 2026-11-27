import 'package:flutter/material.dart';
import 'reporting.dart';
import 'l10n/app_localizations.dart';

const brandTeal = Color(0xff006b60);
const brandMint = Color(0xffb6f1e5);
const brandInk = Color(0xff14211d);
const brandMuted = Color(0xff475952);
const brandCanvas = Color(0xfff4f9f7);
const brandLine = Color(0xffd4e0db);

ThemeData anuvachTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: brandTeal).copyWith(
    primary: brandTeal,
    onPrimary: Colors.white,
    primaryContainer: brandMint,
    onPrimaryContainer: const Color(0xff002822),
    surface: Colors.white,
    secondaryContainer: const Color(0xffd2ede5),
    surfaceContainerLow: const Color(0xfff4f8f6),
    surfaceContainer: const Color(0xffeef4f1),
    surfaceContainerHigh: const Color(0xffe7efeb),
    onSurface: brandInk,
    onSurfaceVariant: brandMuted,
    outlineVariant: brandLine,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    colorScheme: scheme,
  );
  return base.copyWith(
    scaffoldBackgroundColor: brandCanvas,
    textTheme: base.textTheme
        .copyWith(
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -.8,
            color: brandInk,
            height: 1.2,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
            color: brandInk,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: brandInk,
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: brandInk,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.55,
            color: brandMuted,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: brandMuted,
          ),
        )
        .apply(fontFamily: 'NotoSans'),
    appBarTheme: const AppBarTheme(
      backgroundColor: brandCanvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: brandInk,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: brandInk,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
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
        side: const BorderSide(color: brandLine),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xfff4f8f6),
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: brandLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: brandLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: brandTeal, width: 1.5),
      ),
      labelStyle: const TextStyle(color: brandMuted),
      counterStyle: const TextStyle(fontSize: 10, color: brandMuted),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: brandLine),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xffd2ede5),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? brandTeal : brandMuted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: brandLine, space: 28),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      iconColor: brandTeal,
    ),
  );
}

ThemeData anuvachDarkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brandTeal,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xffa4e9d9),
        onPrimary: const Color(0xff00382f),
        primaryContainer: const Color(0xff26564a),
        onPrimaryContainer: const Color(0xffc5f5e8),
        surface: const Color(0xff1a2521),
        surfaceContainerLow: const Color(0xff17231d),
        surfaceContainer: const Color(0xff1d2c24),
        surfaceContainerHigh: const Color(0xff26372d),
        outlineVariant: const Color(0xff3c5147),
        secondaryContainer: const Color(0xff25483e),
        onSurface: const Color(0xffe1eee6),
      );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xff101c17),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xff101c17),
      foregroundColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff243c31),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
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
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .30),
      child: Image.asset(
        'assets/branding/anuvach-logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      ),
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
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: tint ? brandMint : Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: tint ? brandMint : brandLine),
    ),
    child: Theme(
      data: Theme.of(context).brightness == Brightness.dark
          ? anuvachTheme()
          : Theme.of(context),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: brandInk),
        child: child,
      ),
    ),
  );
}

Widget heading(String text) => Builder(
  builder: (context) => Text(
    text,
    style: TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 23,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -.6,
      color: Theme.of(context).colorScheme.onSurface,
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
Widget statusPill(String status) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: const Color(0xffd2ede5),
    borderRadius: BorderRadius.circular(30),
  ),
  child: Text(
    status.replaceAll('_', ' '),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: brandTeal,
    ),
  ),
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
          decoration: const BoxDecoration(
            color: brandCanvas,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: brandTeal),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: brandInk,
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
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0)
          Expanded(
            child: Container(
              height: 1,
              color: brandLine,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= current ? brandTeal : const Color(0xffe3ece7),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: i <= current ? Colors.white : brandMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                AppLocalizations.of(context)!.stepDescribe,
                AppLocalizations.of(context)!.stepReview,
                AppLocalizations.of(context)!.stepSubmit,
              ][i],
              style: TextStyle(
                fontSize: 11,
                color: i <= current ? brandTeal : brandMuted,
              ),
            ),
          ],
        ),
      ],
    ],
  );
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
                  child: w is Form
                      ? SurfaceCard(child: w)
                      : w is Text && (w.data?.length ?? 0) > 130
                      ? SurfaceCard(padding: 18, child: w)
                      : w,
                ),
              )
              .toList(),
        ),
      ),
    ),
  ),
);
Widget facts(Json data) => Builder(
  builder: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow(AppLocalizations.of(context)!.submittedStatements),
            const SizedBox(height: 8),
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
                      style: const TextStyle(fontSize: 11, color: brandMuted),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      data[key] == ''
                          ? AppLocalizations.of(context)!.notSupplied
                          : '${data[key]}',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 14,
                        height: 1.5,
                        color: brandInk,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              AppLocalizations.of(context)!.demoEmployeeIdentity,
              style: const TextStyle(fontSize: 11, color: brandMuted),
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
              style: const TextStyle(fontSize: 12, color: brandMuted),
            ),
          ],
        ),
      ),
    ],
  ),
);
