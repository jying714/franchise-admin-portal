// lib/admin/dashboard/onboarding/widgets/ingredients/ingredient_metadata_json_import_export_dialog.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/schema_templates.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/scrolling_json_editor.dart';

import 'ingredient_metadata_json_preview_table.dart';

class IngredientMetadataJsonImportExportDialog extends StatefulWidget {
  final AppLocalizations loc;

  const IngredientMetadataJsonImportExportDialog({
    super.key,
    required this.loc,
  });

  static Future<void> show(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final provider = context.read<IngredientMetadataProvider>();

    if (loc == null) {
      debugPrint(
          '[IngredientMetadataJsonImportExportDialog] ERROR: loc is null!');
      return;
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Import Export Ingredient Metadata',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        return Localizations.override(
          context: ctx,
          child: Builder(
            builder: (innerCtx) {
              return ChangeNotifierProvider.value(
                value: provider,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 1400,
                      height: 680,
                      child:
                          IngredientMetadataJsonImportExportDialog(loc: loc!),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  State<IngredientMetadataJsonImportExportDialog> createState() =>
      _IngredientMetadataJsonImportExportDialogState();
}

class _IngredientMetadataJsonImportExportDialogState
    extends State<IngredientMetadataJsonImportExportDialog> {
  late TextEditingController _jsonController;
  String? _errorMessage;
  List<IngredientMetadata>? _previewIngredients;

  @override
  void initState() {
    super.initState();
    final formattedJson = const JsonEncoder.withIndent('  ')
        .convert(pizzaShopIngredientMetadataTemplate);
    _jsonController = TextEditingController(text: formattedJson);
    _parsePreview();
  }

  List<IngredientMetadata>? _tryParseJson(String val) {
    try {
      final decoded = json.decode(val);
      if (decoded is! List) return null;
      return decoded.map((e) => IngredientMetadata.fromMap(e)).toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message:
            'Error parsing preview JSON in ingredient_metadata_json_import_export_dialog.dart',
        source: 'ingredient_metadata_json_import_export_dialog.dart',
        severity: 'warning',
        screen: 'onboarding_ingredients_screen',
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
          _errorMessage = widget.loc.invalidJsonFormat;
          _previewIngredients = null;
          return;
        }
        _previewIngredients =
            decoded.map((e) => IngredientMetadata.fromMap(e)).toList();
      });
    } catch (e, stack) {
      setState(() => _previewIngredients = null);
      ErrorLogger.log(
        message: 'JSON import preview parse error',
        source: 'ingredient_metadata_json_import_export_dialog.dart',
        severity: 'warning',
        screen: 'onboarding_ingredients_screen',
        stack: stack.toString(),
        contextData: {'input': _jsonController.text},
      );
      setState(() {
        _errorMessage = widget.loc.jsonParseError;
      });
    }
  }

  Future<void> _saveImport() async {
    final loc = widget.loc;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final provider = context.read<IngredientMetadataProvider>();

    if (_previewIngredients == null || franchiseId.isEmpty) return;

    try {
      final firestore = context.read<FirestoreService>();
      final validTypeIds = await firestore.fetchIngredientTypeIds(franchiseId);

// Filter invalid ingredients
      final invalidIngredients = _previewIngredients!.where((ingredient) {
        return ingredient.typeId == null ||
            !validTypeIds.contains(ingredient.typeId);
      }).toList();

      if (invalidIngredients.isNotEmpty) {
        final badIds = invalidIngredients.map((e) => e.id).join(', ');
        setState(() {
          _errorMessage = '${widget.loc.invalidTypeIdError}: $badIds';
        });
        return;
      }

      await provider.bulkReplaceIngredientMetadata(
          franchiseId, _previewIngredients!);
      if (mounted) Navigator.of(context).pop();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save imported ingredient metadata',
        source: 'ingredient_metadata_json_import_export_dialog.dart',
        severity: 'error',
        screen: 'onboarding_ingredients_screen',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1400,
        height: 680,
        child: Column(
          children: [
            AppBar(
              title: Text(widget.loc.importExportIngredientMetadata),
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
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.loc.editJsonBelow,
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
                              loc: loc,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Preview Table Column
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.loc.preview,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: IngredientMetadataJsonPreviewTable(
                                  rawJson: _jsonController.text,
                                  previewIngredients: _previewIngredients,
                                  loc: widget.loc,
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
                    child: Text(widget.loc.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _previewIngredients != null ? _saveImport : null,
                    child: Text(widget.loc.importChanges),
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
