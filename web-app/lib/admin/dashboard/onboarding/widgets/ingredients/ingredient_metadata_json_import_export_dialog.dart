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
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'ingredient_metadata_json_preview_table.dart';

class IngredientMetadataJsonImportExportDialog extends StatefulWidget {
  final AppLocalizations loc;

  const IngredientMetadataJsonImportExportDialog({
    super.key,
    required this.loc,
  });

  static Future<void> show(
      BuildContext context, IngredientMetadataProvider provider) async {
    final loc = AppLocalizations.of(context);
    final typeProvider = context.read<IngredientTypeProvider>();

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
          child: ChangeNotifierProvider<IngredientTypeProvider>.value(
            value: typeProvider,
            child: ChangeNotifierProvider<IngredientMetadataProvider>.value(
              value: provider,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 1400,
                    height: 680,
                    child: IngredientMetadataJsonImportExportDialog(loc: loc!),
                  ),
                ),
              ),
            ),
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
  late final ScrollController _jsonEditorScrollController;
  late final ScrollController _previewTableScrollController;
  String? _errorMessage;
  List<IngredientMetadata>? _previewIngredients;

  @override
  void initState() {
    super.initState();
    final formattedJson = const JsonEncoder.withIndent('  ')
        .convert(pizzaShopIngredientMetadataTemplate);
    _jsonController = TextEditingController(text: formattedJson);
    _jsonEditorScrollController = ScrollController();
    _previewTableScrollController = ScrollController();
    _parsePreview();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _jsonEditorScrollController.dispose();
    _previewTableScrollController.dispose();
    super.dispose();
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
        print(
            '[Dialog] Parsed ${_previewIngredients!.length} preview ingredients');
      });
    } catch (e, stack) {
      setState(() => _previewIngredients = null);
      print('[Dialog] JSON parse error');
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
    print('[Dialog] _saveImport called');
    final loc = widget.loc;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    print('[Dialog] got franchiseId: $franchiseId');
    final provider = context.read<IngredientMetadataProvider>();
    print('[Dialog] got provider hashCode: ${provider.hashCode}');

    if (_previewIngredients == null || franchiseId.isEmpty) {
      print('[Dialog] _saveImport exit: no preview or empty franchiseId');
      return;
    }

    try {
      final firestore = context.read<FirestoreService>();
      print('[Dialog] got firestore');
      final validTypeIds = await firestore.fetchIngredientTypeIds(franchiseId);
      print('[Dialog] validTypeIds: $validTypeIds');

      final invalidIngredients = _previewIngredients!.where((ingredient) {
        return ingredient.typeId == null ||
            !validTypeIds.contains(ingredient.typeId);
      }).toList();
      print('[Dialog] found invalid ingredients: $invalidIngredients');

      if (invalidIngredients.isNotEmpty) {
        final badIds = invalidIngredients.map((e) => e.id).join(', ');
        // List available typeIds
        final typeList = validTypeIds.isEmpty
            ? '(none found for this franchise)'
            : validTypeIds.join(', ');
        setState(() {
          _errorMessage = '${widget.loc.invalidTypeIdError}: $badIds\n'
              'Available typeIds: $typeList';
        });
        print('[Dialog] Exiting, invalid ingredients');
        return;
      }

      print(
          '[Dialog] Provider before calling bulkReplaceIngredientMetadata hashCode: ${provider.hashCode}');
      await provider.bulkReplaceIngredientMetadata(
          franchiseId, _previewIngredients!);

      print('[Dialog] Called bulkReplaceIngredientMetadata');

      if (mounted) {
        Navigator.of(context).pop();
        print('[Dialog] Navigator.pop called');
      }
    } catch (e, stack) {
      print('[Dialog] Caught exception: $e');
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
                            child: Scrollbar(
                              controller: _jsonEditorScrollController,
                              thumbVisibility: true,
                              child: TextField(
                                controller: _jsonController,
                                scrollController: _jsonEditorScrollController,
                                maxLines: null,
                                style: theme.textTheme.bodyMedium,
                                decoration: const InputDecoration.collapsed(
                                  hintText: '{ "key": "value" }',
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _jsonController.text = val;
                                    _parsePreview();
                                  });
                                },
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
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
                            child: IngredientMetadataJsonPreviewTable(
                              rawJson: _jsonController.text,
                              previewIngredients: _previewIngredients,
                              loc: widget.loc,
                              scrollController: _previewTableScrollController,
                            ),
                          )
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
                    onPressed: _previewIngredients != null
                        ? () {
                            print('[Dialog] Import button pressed');
                            _saveImport();
                          }
                        : null,
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
