import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/import_csv_file_button.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BulkMenuUploadDialog extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onComplete;
  final String franchiseId;

  const BulkMenuUploadDialog({
    super.key,
    required this.categories,
    required this.onComplete,
    required this.franchiseId,
  });

  @override
  State<BulkMenuUploadDialog> createState() => _BulkMenuUploadDialogState();
}

class _BulkMenuUploadDialogState extends State<BulkMenuUploadDialog> {
  static const String csvTemplate =
      'category,name,price,description,imageUrl,available,sku,dietary,allergens\n'
      'Pizzas,Pepperoni Pizza,12.99,"Classic pepperoni, cheese, and sauce",https://img.url/pepperoni.jpg,true,SKU001,"Vegetarian",';

  final TextEditingController _csvController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _uploaded = false;

  @override
  void initState() {
    super.initState();
    // Preload with template if empty
    if (_csvController.text.isEmpty) {
      _csvController.text = csvTemplate;
    }
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _resetToTemplate() {
    setState(() {
      _csvController.text = csvTemplate;
      _error = null;
    });
  }

  void _onImportFilePressed() async {
    // TODO: Implement file picker logic
    // This is only a placeholder/snackbar for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.importCSVPlaceholder)),
    );
  }

  void _onSubmit() {
    // TODO: Add actual CSV parsing/upload logic
    // For now, just close and show success in UI (no actual import)
    setState(() {
      _uploaded = true;
      _loading = false;
      _error = null;
    });
    widget.onComplete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.bulkImport,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                loc.bulkUploadInstructions,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ImportCsvFileButton(
                    label: loc.importCSV,
                    onCsvPicked: (csvContent) {
                      if (csvContent != null) {
                        setState(() {
                          _csvController.text = csvContent;
                          // Optionally trigger CSV preview/parse if desired
                          // _parseCsv();
                        });
                      } else {
                        // User canceled, no action needed (optional: show a message)
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _resetToTemplate,
                    child: Text(loc.resetTemplate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _csvController,
                  minLines: 8,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: loc.bulkUploadPasteCsv,
                    border: const OutlineInputBorder(),
                    hintText: csvTemplate,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_uploaded)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    loc.bulkImportSuccess,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() => _loading = true);
                            Future.delayed(
                                const Duration(milliseconds: 400), _onSubmit);
                          },
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.upload),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
