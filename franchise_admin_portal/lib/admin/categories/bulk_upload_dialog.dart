import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Optionally for user id:
import 'package:franchise_admin_portal/core/providers/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class BulkUploadDialog extends StatefulWidget {
  final String franchiseId;

  const BulkUploadDialog({
    super.key,
    required this.franchiseId,
  });

  @override
  State<BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<BulkUploadDialog> {
  final _controller = TextEditingController();
  bool _isUploading = false;
  String? _uploadResult;

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Localization missing! [debug]')),
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = widget.franchiseId;

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    // Optionally get userId for logging:
    final userId =
        Provider.of<UserProfileNotifier?>(context, listen: false)?.user?.id;

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
            enabled: !_isUploading,
          ),
          if (_uploadResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _uploadResult!,
                style: TextStyle(
                  color: _uploadResult!.toLowerCase().contains('success')
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
                      if (line.trim().isEmpty) continue;
                      final cols = line.split(',');
                      if (cols.isEmpty || cols[0].trim().isEmpty) continue;
                      cats.add(Category(
                        id: UniqueKey().toString(),
                        name: cols[0].trim(),
                        image: cols.length > 1 ? cols[1].trim() : null,
                        description: cols.length > 2 ? cols[2].trim() : null,
                      ));
                    }
                    for (final cat in cats) {
                      await firestoreService.addCategory(
                        franchiseId: franchiseId,
                        category: cat,
                      );
                    }
                    setState(() {
                      _uploadResult =
                          '${cats.length} ${loc.bulkUploadSuccess.toLowerCase()}';
                    });
                  } catch (e, stack) {
                    // Remote error logging
                    try {
                      await ErrorLogger.log(
                        message: e.toString(),
                        source: 'bulk_upload_dialog',
                        screen: 'BulkUploadDialog',
                        stack: stack.toString(),
                        severity: 'error',
                        contextData: {
                          'franchiseId': franchiseId,
                          'userId': userId,
                          'errorType': e.runtimeType.toString(),
                          'csvText': _controller.text,
                        },
                      );
                    } catch (_) {}
                    setState(() => _uploadResult = loc.bulkUploadError);
                    await _showErrorDialog(context, loc.bulkUploadError);
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
