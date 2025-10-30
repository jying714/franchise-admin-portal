import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:admin_portal/core/models/ingredient_type_model.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/config/design_tokens.dart';

class InlineAddIngredientTypeRow extends StatefulWidget {
  const InlineAddIngredientTypeRow({super.key});

  @override
  State<InlineAddIngredientTypeRow> createState() =>
      _InlineAddIngredientTypeRowState();
}

class _InlineAddIngredientTypeRowState
    extends State<InlineAddIngredientTypeRow> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.ingredientTypeNameRequired)),
      );
      return;
    }

    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final provider = context.read<IngredientTypeProvider>();

    setState(() => _submitting = true);

    try {
      final newType = IngredientType(
        id: null,
        name: name,
        sortOrder: sortOrder,
      );

      await provider.addType(franchiseId, newType);

      _nameController.clear();
      _sortOrderController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.ingredientTypeAdded}: $name')),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to add new ingredient type inline',
        stack: stack.toString(),
        severity: 'error',
        screen: 'ingredient_type_management_screen',
        source: 'InlineAddIngredientTypeRow',
        contextData: {
          'nameAttempted': name,
          'sortOrder': sortOrder,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(color: DesignTokens.cardBorderColor),
      ),
      color: DesignTokens.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.ingredientTypeName,
                  hintText: loc.ingredientTypeNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.sortOrder,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _submitting
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : IconButton(
                    tooltip: loc.add,
                    icon: const Icon(Icons.add_circle_outline),
                    color: colorScheme.primary,
                    onPressed: _submitting ? null : _submit,
                  ),
          ],
        ),
      ),
    );
  }
}
