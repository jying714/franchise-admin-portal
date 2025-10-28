import 'dart:io';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/analytics_summary.dart';
import 'package:franchise_admin_portal/core/utils/export_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExportAnalyticsDialogSingleSummary extends StatelessWidget {
  final AnalyticsSummary summary;

  const ExportAnalyticsDialogSingleSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final csv = ExportUtils.analyticsSummaryToCsv(context, summary);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: colorScheme.surface,
      title: Text(
        'Export Analytics Data',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Analytics export generated.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 100,
                height: 40,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 24),
                  label: const Text('Share', style: TextStyle(fontSize: 18)),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: DesignTokens.primaryColor, width: 2),
                    foregroundColor: DesignTokens.primaryColor,
                    backgroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onPressed: () async {
                    final dir = await getTemporaryDirectory();
                    final file = File(
                      '${dir.path}/analytics_export_${summary.period}.csv',
                    );
                    await file.writeAsString(csv);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: 'Analytics Export (${summary.period})',
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
