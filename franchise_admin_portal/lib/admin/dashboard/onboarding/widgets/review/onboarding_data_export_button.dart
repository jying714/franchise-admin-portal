// File: lib/admin/dashboard/onboarding/widgets/review/onboarding_data_export_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_review_provider.dart';

/// Button for exporting onboarding data (including issues) as JSON.
/// - Pulls from OnboardingReviewProvider.exportDataAsJson()
/// - Notifies user on copy/export.
/// - Ready for CSV export or true download integration (see notes).
class OnboardingDataExportButton extends StatefulWidget {
  const OnboardingDataExportButton({Key? key}) : super(key: key);

  @override
  State<OnboardingDataExportButton> createState() =>
      _OnboardingDataExportButtonState();
}

class _OnboardingDataExportButtonState
    extends State<OnboardingDataExportButton> {
  bool _copying = false;
  String? _lastStatusMsg;

  Future<void> _exportJson(
      BuildContext context, OnboardingReviewProvider provider) async {
    setState(() {
      _copying = true;
      _lastStatusMsg = null;
    });
    try {
      final json = provider.exportDataAsJson();
      await Clipboard.setData(ClipboardData(text: json));
      setState(() {
        _lastStatusMsg = "Exported to clipboard as JSON.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Onboarding export copied to clipboard (JSON).'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _lastStatusMsg = "Failed to copy export: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _copying = false;
      });
    }
  }

  // Placeholder for future CSV export logic (not implemented yet)
  Future<void> _exportCsv(
      BuildContext context, OnboardingReviewProvider provider) async {
    setState(() => _copying = true);
    try {
      // You may implement your CSV export logic here.
      setState(() {
        _lastStatusMsg = "CSV export not yet implemented.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV export coming soon.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<OnboardingReviewProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Export Onboarding Data",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17.2,
            color: colorScheme.primary,
            fontFamily: DesignTokens.fontFamily,
            letterSpacing: 0.11,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            // JSON export
            ElevatedButton.icon(
              icon: _copying
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Export JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 19, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15.2),
              ),
              onPressed:
                  _copying ? null : () => _exportJson(context, reviewProvider),
            ),
            const SizedBox(width: 14),
            // CSV export (future)
            OutlinedButton.icon(
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                side: BorderSide(color: colorScheme.primary, width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 15.2),
              ),
              onPressed:
                  _copying ? null : () => _exportCsv(context, reviewProvider),
            ),
          ],
        ),
        if (_lastStatusMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _lastStatusMsg!,
              style: TextStyle(
                color: _lastStatusMsg!.startsWith("Failed")
                    ? colorScheme.error
                    : colorScheme.secondary,
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "Download your full onboarding state (with all issues) for backup, audit, or troubleshooting.",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.68),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}
