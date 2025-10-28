import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; // Use share_plus for sharing files
import 'package:path_provider/path_provider.dart';

class ExportAnalyticsDialog extends StatelessWidget {
  final String csvData;
  final String periodLabel; // e.g. "2025-06" or "June 2025"

  const ExportAnalyticsDialog({
    Key? key,
    required this.csvData,
    required this.periodLabel,
  }) : super(key: key);

  Future<void> _shareCsv(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/analytics_export_$periodLabel.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Analytics Export ($periodLabel)',
          text: 'Analytics CSV Export for $periodLabel');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Analytics Data',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Analytics export generated.',
                style: TextStyle(color: Colors.green)),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 260, minWidth: 320),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                csvData,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share'),
          onPressed: () => _shareCsv(context),
        ),
      ],
    );
  }
}
