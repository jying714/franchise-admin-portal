import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BulkUploadDialog extends StatefulWidget {
  const BulkUploadDialog({super.key});

  @override
  State<BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<BulkUploadDialog> {
  final _controller = TextEditingController();
  bool _isUploading = false;
  String? _uploadResult;

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.bulkUploadCategories),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loc.bulkUploadInstructions),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: loc.bulkUploadPasteCsv,
              hintText:
                  'name,image,description\nPizza,https://...,Delicious...',
            ),
          ),
          if (_uploadResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _uploadResult!,
                style: TextStyle(
                  color: _uploadResult!.contains('success')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isUploading
              ? null
              : () async {
                  setState(() => _isUploading = true);
                  try {
                    final lines = _controller.text.split('\n');
                    final List<Category> cats = [];
                    for (var line in lines.skip(1)) {
                      final cols = line.split(',');
                      if (cols.length < 1 || cols[0].trim().isEmpty) continue;
                      cats.add(Category(
                        id: UniqueKey().toString(),
                        name: cols[0].trim(),
                        image: cols.length > 1 ? cols[1].trim() : null,
                        description: cols.length > 2 ? cols[2].trim() : null,
                      ));
                    }
                    for (final cat in cats) {
                      await firestoreService.addCategory(cat);
                    }
                    setState(() {
                      _uploadResult =
                          '${cats.length} ${loc.bulkUploadSuccess.toLowerCase()}';
                    });
                  } catch (e) {
                    setState(() => _uploadResult = loc.bulkUploadError);
                  } finally {
                    setState(() => _isUploading = false);
                  }
                },
          child: _isUploading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc.upload),
        ),
      ],
    );
  }
}
