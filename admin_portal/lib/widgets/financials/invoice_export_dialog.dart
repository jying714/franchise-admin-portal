// File: lib/admin/hq_owner/invoice_export_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:admin_portal/core/models/invoice.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/export_utils.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/config/design_tokens.dart';

/// InvoiceExportDialog
/// Dialog widget to allow HQ/Owner users to export invoices data.
/// Supports export format selection (CSV, PDF placeholder),
/// date range filtering, and selection of all or filtered invoices.
///
/// Integrates with FirestoreService to fetch data,
/// uses ExportUtils for CSV generation,
/// and logs errors with ErrorLogger.
///
/// Designed with localization, theming, and modularity in mind.

class InvoiceExportDialog extends StatefulWidget {
  final String franchiseId;

  const InvoiceExportDialog({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<InvoiceExportDialog> createState() => _InvoiceExportDialogState();
}

class _InvoiceExportDialogState extends State<InvoiceExportDialog> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _exportFormat = 'csv'; // 'csv' or 'pdf'

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[InvoiceExportDialog] loc is null! Localization not available for this context.');
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(loc.exportInvoices),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDatePicker(context, loc, label: loc.startDate,
                onSelected: (d) {
              setState(() => _startDate = d);
            }, selectedDate: _startDate),
            const SizedBox(height: DesignTokens.paddingMd),
            _buildDatePicker(context, loc, label: loc.endDate, onSelected: (d) {
              setState(() => _endDate = d);
            }, selectedDate: _endDate),
            const SizedBox(height: DesignTokens.paddingMd),
            _buildFormatSelector(loc),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _exportInvoices,
          child: _loading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(loc.export),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, AppLocalizations loc,
      {required String label,
      required ValueChanged<DateTime> onSelected,
      DateTime? selectedDate}) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? now,
              firstDate: DateTime(now.year - 10),
              lastDate: now,
            );
            if (picked != null) {
              onSelected(picked);
            }
          },
          child: Text(selectedDate != null
              ? MaterialLocalizations.of(context).formatShortDate(selectedDate)
              : loc.selectDate),
        ),
      ],
    );
  }

  Widget _buildFormatSelector(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.exportFormat),
        RadioListTile<String>(
          title: Text('CSV'),
          value: 'csv',
          groupValue: _exportFormat,
          onChanged: (val) {
            if (val != null) {
              setState(() => _exportFormat = val);
            }
          },
        ),
        RadioListTile<String>(
          title: Text('PDF (Coming Soon)'),
          value: 'pdf',
          groupValue: _exportFormat,
          onChanged: null, // Disabled for now
        ),
      ],
    );
  }

  Future<void> _exportInvoices() async {
    setState(() {
      _loading = true;
    });
    try {
      final invoices = await _firestoreService.fetchInvoicesFiltered(
        franchiseId: widget.franchiseId,
        startDate: _startDate,
        endDate: _endDate,
      );

      String exportedData;
      if (_exportFormat == 'csv') {
        exportedData = ExportUtils.invoicesToCsv(context, invoices);
      } else {
        // Placeholder for PDF export implementation
        exportedData = '';
      }

      // TODO: Trigger file save or share dialog with exportedData
      // This is app-specific: platform file pickers or share plugins
      // For now, just print to console:
      debugPrint('Exported Data:\n$exportedData');

      Navigator.of(context).pop(); // Close dialog on success
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'InvoiceExportDialog',
        screen: '_exportInvoices',
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
          'startDate': _startDate?.toIso8601String(),
          'endDate': _endDate?.toIso8601String(),
          'exportFormat': _exportFormat,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)?.exportFailed ??
                  'Export failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
