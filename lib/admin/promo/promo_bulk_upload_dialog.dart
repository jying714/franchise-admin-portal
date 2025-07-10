import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:franchise_admin_portal/core/models/promo.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/confirmation_dialog.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:provider/provider.dart';

class PromoBulkUploadDialog extends StatefulWidget {
  final VoidCallback? onUploadComplete;
  const PromoBulkUploadDialog({super.key, this.onUploadComplete});

  @override
  State<PromoBulkUploadDialog> createState() => _PromoBulkUploadDialogState();
}

class _PromoBulkUploadDialogState extends State<PromoBulkUploadDialog> {
  bool isLoading = false;
  String? errorMsg;
  List<Promo> previewPromos = [];

  Future<void> _pickAndParseFile() async {
    setState(() => errorMsg = null);
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json', 'csv']);
    if (result == null || result.files.isEmpty) return;

    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      if (result.files.single.extension == 'json') {
        final List<dynamic> data = json.decode(content);
        previewPromos =
            data.map((e) => Promo.fromFirestore(e, e['id'] ?? '')).toList();
      } else if (result.files.single.extension == 'csv') {
        // TODO: Add CSV parsing logic (headers must match Promo fields)
        throw UnimplementedError('CSV import not implemented.');
      }
      setState(() {});
    } catch (e) {
      setState(() => errorMsg = 'Failed to parse file: $e');
    }
  }

  Future<void> _uploadAll() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;

    setState(() => isLoading = true);
    for (final promo in previewPromos) {
      await FirestoreService().addPromo(franchiseId, promo);
    }
    setState(() => isLoading = false);
    if (widget.onUploadComplete != null) widget.onUploadComplete!();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Upload Promos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose File (JSON/CSV)'),
            onPressed: _pickAndParseFile,
          ),
          if (errorMsg != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
            ),
          if (previewPromos.isNotEmpty)
            Text('Preview (${previewPromos.length} items):'),
          if (previewPromos.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView(
                children: previewPromos
                    .take(5)
                    .map((promo) => ListTile(
                          title: Text('${promo.type} (${promo.discount})'),
                          subtitle: Text(
                              'Active: ${promo.active}, Ends: ${promo.endDate}'),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        if (previewPromos.isNotEmpty)
          ElevatedButton(
            onPressed: isLoading ? null : _uploadAll,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Upload All'),
          ),
      ],
    );
  }
}
