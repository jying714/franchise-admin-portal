import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localization missing!')),
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
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('Localization missing!')),
      );
    }

    final firestoreService = Provider.of<shared.FirestoreService>(
      context,
      listen: false,
    );

    final userId = Provider.of<UserProfileNotifier>(
      context,
      listen: false,
    ).user?.id;

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
                    final List<shared.Category> cats = [];

                    for (var line in lines.skip(1)) {
                      if (line.trim().isEmpty) continue;
                      final cols = line.split(',');
                      if (cols.isEmpty || cols[0].trim().isEmpty) continue;

                      cats.add(shared.Category(
                        id: UniqueKey().toString(),
                        name: cols[0].trim(),
                        image: cols.length > 1 ? cols[1].trim() : null,
                        description: cols.length > 2 ? cols[2].trim() : null,
                      ));
                    }

                    for (final cat in cats) {
                      await firestoreService.addCategory(
                        franchiseId: widget.franchiseId,
                        category: cat,
                      );
                    }

                    setState(() {
                      _uploadResult =
                          '${cats.length} ${loc.bulkUploadSuccess.toLowerCase()}';
                    });
                  } catch (e, stack) {
                    shared.ErrorLogger.log(
                      message: e.toString(),
                      source: 'BulkUploadDialog',
                      stack: stack.toString(),
                      severity: 'error',
                      contextData: {
                        'franchiseId': widget.franchiseId,
                        'userId': userId,
                        'errorType': e.runtimeType.toString(),
                      },
                    );

                    setState(() => _uploadResult = loc.bulkUploadError);
                    if (mounted) {
                      await _showErrorDialog(context, loc.bulkUploadError);
                    }
                  } finally {
                    setState(() => _isUploading = false);
                  }
                },
          child: _isUploading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.upload),
        ),
      ],
    );
  }
}
