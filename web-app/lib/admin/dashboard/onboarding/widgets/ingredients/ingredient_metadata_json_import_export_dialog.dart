import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/scrolling_json_editor.dart';
import 'ingredient_metadata_json_preview_table.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';

class IngredientMetadataJsonImportExportDialog extends StatefulWidget {
  final AppLocalizations loc;

  const IngredientMetadataJsonImportExportDialog({
    super.key,
    required this.loc,
  });

  static Future<void> show(
    BuildContext context,
    IngredientMetadataProviderImpl provider,
  ) async {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Import Export Ingredient Metadata',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        return Localizations.override(
          context: ctx,
          child: ChangeNotifierProvider<IngredientMetadataProviderImpl>.value(
            value: provider,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 1400,
                  height: 680,
                  child: IngredientMetadataJsonImportExportDialog(loc: loc),
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
  List<shared.IngredientMetadata>? _previewIngredients;

  @override
  void initState() {
    super.initState();
    final formattedJson = const JsonEncoder.withIndent('  ')
        .convert(shared.pizzaShopIngredientMetadataTemplate);
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

  List<shared.IngredientMetadata>? _tryParseJson(String val) {
    try {
      final decoded = json.decode(val);
      if (decoded is! List) return null;
      return decoded
          .map((e) =>
              shared.IngredientMetadata.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Error parsing preview JSON',
        source: 'IngredientMetadataJsonImportExportDialog',
        severity: 'warning',
        stack: stack.toString(),
      );
      return null;
    }
  }

  void _parsePreview() {
    final parsed = _tryParseJson(_jsonController.text);
    setState(() {
      _previewIngredients = parsed;
      _errorMessage = parsed == null ? widget.loc.invalidJsonFormat : null;
    });
  }

  Future<void> _saveImport() async {
    final loc = widget.loc;
    final provider = Provider.of<IngredientMetadataProviderImpl>(
      context,
      listen: false,
    );
    final franchiseId = Provider.of<shared.FranchiseProvider>(
      context,
      listen: false,
    ).franchiseId;

    if (_previewIngredients == null || franchiseId.isEmpty) return;

    try {
      await provider.bulkReplaceIngredientMetadata(
        franchiseId,
        _previewIngredients!,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to save imported ingredient metadata',
        source: 'IngredientMetadataJsonImportExportDialog',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
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
              title: Text(loc.importExportIngredientMetadata),
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
                    // JSON Editor
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.editJsonBelow,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ScrollingJsonEditor(
                              initialJson: _jsonController.text,
                              onChanged: (val) => _parsePreview(),
                              loc: widget.loc,
                            ),
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Preview Table
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.preview, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: IngredientMetadataJsonPreviewTable(
                              rawJson: _jsonController.text,
                              previewIngredients: _previewIngredients,
                              loc: loc,
                              scrollController: _previewTableScrollController,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _previewIngredients != null ? _saveImport : null,
                    child: Text(loc.importChanges),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
