import 'package:flutter/material.dart';

import 'design.dart';
import 'l10n/app_localizations.dart';
import 'local_features.dart';
import 'reporting.dart';

class ReportsDashboard extends StatelessWidget {
  const ReportsDashboard({
    super.key,
    required this.reports,
    required this.loading,
    required this.hasError,
  });

  final List<Json> reports;
  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final allStatuses = [
      'submitted',
      'in_review',
      'awaiting_employee',
      'escalated',
      'closed',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        heading(strings.reportsOverview),
        const SizedBox(height: 10),
        if (loading)
          const LinearProgressIndicator(minHeight: 2)
        else if (hasError)
          Text(strings.reportCountsUnavailable)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in allStatuses)
                Chip(
                  label: Text(
                    '${reportStatus(strings, status)} · '
                    '${reports.where((report) => report['status'] == status).length}',
                  ),
                ),
            ],
          ),
        const SizedBox(height: 20),
        heading(strings.scamTips),
        const SizedBox(height: 8),
        for (final (icon, tip, source, url) in [
          (
            Icons.lock_outline_rounded,
            strings.protectCodes,
            'RBI · BE(A)WARE',
            'https://rbi.org.in/Scripts/FS_PressRelease.aspx?fn=2745&prid=53372',
          ),
          (
            Icons.link_rounded,
            strings.verifyRequests,
            'CERT-In',
            'https://www.cert-in.org.in/s2cMainServlet?VLCODE=CIAD-2024-0050&pageid=PUBVLNOTES02',
          ),
          (
            Icons.flag_outlined,
            strings.reportFraudPrompt,
            'National Cyber Crime Reporting Portal',
            'https://cybercrime.gov.in/',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              padding: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await LocalFeatures().openLink(Uri.parse(url));
                      } catch (_) {
                        if (!context.mounted) return;
                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(source),
                            content: SelectableText(url),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: Text(source),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
