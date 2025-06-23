// ignore: unused_import
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';

class PromoExportDialog extends StatefulWidget {
  const PromoExportDialog({Key? key}) : super(key: key);

  @override
  State<PromoExportDialog> createState() => _PromoExportDialogState();
}

class _PromoExportDialogState extends State<PromoExportDialog> {
  bool isExporting = false;
  String? downloadPath;

  Future<void> _exportPromos() async {
    setState(() => isExporting = true);
    final promos = await FirestoreService().getPromos().first;
    final csvHeader = [
      'id',
      'type',
      'items',
      'discount',
      'maxUses',
      'maxUsesType',
      'minOrderValue',
      'startDate',
      'endDate',
      'active'
    ];
    final csvRows = promos
        .map((p) =>
            '${p.id},${p.type},"${p.items.join(';')}",${p.discount},${p.maxUses},${p.maxUsesType},${p.minOrderValue},${p.startDate.toIso8601String()},${p.endDate.toIso8601String()},${p.active}')
        .toList();

    final csvContent = '${csvHeader.join(',')}\n${csvRows.join('\n')}';
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/promos_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvContent);

    setState(() {
      downloadPath = file.path;
      isExporting = false;
    });
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
