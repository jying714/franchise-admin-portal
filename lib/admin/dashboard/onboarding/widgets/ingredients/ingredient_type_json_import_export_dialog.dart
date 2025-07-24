import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/scrolling_json_editor.dart';
import 'ingredient_type_json_preview_table.dart';

class IngredientTypeJsonImportExportDialog extends StatefulWidget {
  const IngredientTypeJsonImportExportDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Import Export Ingredient Types',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 1400,
            height: 680,
            child: const IngredientTypeJsonImportExportDialog(),
          ),
        ),
      ),
    );
  }

  @override
  State<IngredientTypeJsonImportExportDialog> createState() =>
      _IngredientTypeJsonImportExportDialogState();
}

class _IngredientTypeJsonImportExportDialogState
    extends State<IngredientTypeJsonImportExportDialog> {
  late TextEditingController _jsonController;
  String? _errorMessage;
  List<IngredientType>? _previewTypes;
  late String _jsonInput;
  List<IngredientType>? _parsedPreview;

  @override
  void initState() {
    super.initState();
    final provider = context.read<IngredientTypeProvider>();
    final prefill = provider.types.map((e) => e.toMap()).toList();
    _jsonInput = const JsonEncoder.withIndent('  ').convert(prefill);
    _jsonController = TextEditingController(text: _jsonInput);
    _parsePreview();
  }

  List<IngredientType>? _tryParseJson(String val) {
    try {
      final decoded = json.decode(val);
      if (decoded is! List) return null;
      return decoded.map((e) => IngredientType.fromMap(e)).toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Error parsing preview JSON in dialog',
        source: 'ingredient_type_json_import_export_dialog.dart',
        severity: 'warning',
        screen: 'ingredient_type_management_screen',
        stack: stack.toString(),
        contextData: {'input': val},
      );
      return null;
    }
  }

  void _parsePreview() {
    try {
      setState(() {
        _errorMessage = null;
        final decoded = jsonDecode(_jsonController.text);
        if (decoded is! List) {
          _errorMessage = AppLocalizations.of(context)!.invalidJsonFormat;
          _previewTypes = null;
          return;
        }
        _previewTypes = decoded.map((e) => IngredientType.fromMap(e)).toList();
      });
    } catch (e, stack) {
      setState(() => _previewTypes = null);
      ErrorLogger.log(
        message: 'JSON import preview parse error',
        source: 'ingredient_type_json_import_export_dialog.dart',
        severity: 'warning',
        screen: 'ingredient_type_management_screen',
        stack: stack.toString(),
        contextData: {
          'input': _jsonController.text,
        },
      );
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.jsonParseError;
      });
    }
  }

  Future<void> _saveImport() async {
    final loc = AppLocalizations.of(context)!;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final provider = context.read<IngredientTypeProvider>();

    if (_previewTypes == null || franchiseId.isEmpty) return;

    try {
      await provider.bulkReplaceIngredientTypes(franchiseId, _previewTypes!);
      if (mounted) Navigator.of(context).pop();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save imported ingredient types',
        source: 'ingredient_type_json_import_export_dialog.dart',
        severity: 'error',
        screen: 'ingredient_type_management_screen',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1400, // ⬅️ Wider panel
        height: 680,
        child: Column(
          children: [
            AppBar(
              title: Text(loc.importExportIngredientTypes),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // JSON Editor Column
                    Expanded(
                      flex: 6, // ⬅️ More width
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.editJsonBelow,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ScrollingJsonEditor(
                              initialJson: _jsonController.text,
                              onChanged: (val) {
                                setState(() {
                                  _jsonController.text = val;
                                  _parsePreview();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Preview Table Column
                    Expanded(
                      flex: 6, // ⬅️ Equal width for preview table
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.preview, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: IngredientTypeJsonPreviewTable(
                                  rawJson: _jsonController.text,
                                  previewTypes: _previewTypes,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _previewTypes != null ? _saveImport : null,
                    child: Text(loc.saveChanges),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
