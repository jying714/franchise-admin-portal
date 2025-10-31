// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter/material.dart';
// Don't import dart:io at top-level if you want to build for web.
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:path_provider/path_provider.dart'
    if (dart.library.io) 'package:path_provider/path_provider.dart';
import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'dart:html' as html; // For web file download

class PromoExportDialog extends StatefulWidget {
  const PromoExportDialog({Key? key}) : super(key: key);

  @override
  State<PromoExportDialog> createState() => _PromoExportDialogState();
}

class _PromoExportDialogState extends State<PromoExportDialog> {
  bool isExporting = false;
  String? downloadPath;

  Future<void> _exportPromos() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    setState(() => isExporting = true);
    final promos = await FirestoreService().getPromos(franchiseId).first;
    final csvHeader = [/* ... */];
    final csvRows = [/* ... */];
    final csvContent = '${csvHeader.join(',')}\n${csvRows.join('\n')}';

    if (kIsWeb) {
      // Web: Offer download via AnchorElement
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "promos_export.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
      setState(() {
        downloadPath = "Download started (browser)";
        isExporting = false;
      });
    } else {
      // Mobile/Desktop: Write to file
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/promos_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent);

      setState(() {
        downloadPath = file.path;
        isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Promos'),
      content: isExporting
          ? const Center(child: CircularProgressIndicator())
          : downloadPath != null
              ? SelectableText('Exported to: $downloadPath')
              : const Text('Export all active promos to CSV.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        if (downloadPath == null && !isExporting)
          ElevatedButton(onPressed: _exportPromos, child: const Text('Export')),
      ],
    );
  }
}


