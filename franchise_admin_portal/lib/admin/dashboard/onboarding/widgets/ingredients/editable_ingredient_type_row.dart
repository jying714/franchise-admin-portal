import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class EditableIngredientTypeRow extends StatefulWidget {
  final IngredientType type;
  final bool isEditing;
  final VoidCallback onEditTapped;
  final VoidCallback onDeleteTapped;
  final VoidCallback onSaveTapped;
  final Widget? trailing; // <-- Added trailing param

  const EditableIngredientTypeRow({
    super.key,
    required this.type,
    required this.isEditing,
    required this.onEditTapped,
    required this.onDeleteTapped,
    required this.onSaveTapped,
    this.trailing, // <-- Added trailing param
  });

  @override
  State<EditableIngredientTypeRow> createState() =>
      _EditableIngredientTypeRowState();
}

class _EditableIngredientTypeRowState extends State<EditableIngredientTypeRow> {
  late TextEditingController _nameController;
  late TextEditingController _sortOrderController;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.type.name);
    _sortOrderController =
        TextEditingController(text: widget.type.sortOrder.toString());
  }

  @override
  void didUpdateWidget(covariant EditableIngredientTypeRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final updated = widget.type;

    if (oldWidget.type.name != updated.name ||
        oldWidget.type.sortOrder != updated.sortOrder ||
        oldWidget.type.id != updated.id) {
      _nameController.text = updated.name;
      _sortOrderController.text = updated.sortOrder.toString();
    }

    if (oldWidget.isEditing != widget.isEditing && widget.isEditing) {
      _nameController.text = updated.name;
      _sortOrderController.text = updated.sortOrder.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _updateField() async {
    final loc = AppLocalizations.of(context)!;
    final provider = context.read<IngredientTypeProvider>();
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    final updated = widget.type.copyWith(
      name: _nameController.text.trim(),
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ??
          widget.type.sortOrder,
    );

    if (updated == widget.type) {
      widget.onSaveTapped();
      return;
    }

    setState(() => _updating = true);

    try {
      await provider.updateType(franchiseId, updated);
      widget.onSaveTapped();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${loc.ingredientTypeUpdated}: ${updated.name}')),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to update ingredient type inline',
        stack: stack.toString(),
        severity: 'error',
        source: 'EditableIngredientTypeRow',
        screen: 'ingredient_type_management_screen',
        contextData: {
          'franchiseId': franchiseId,
          'typeId': widget.type.id,
          'attemptedName': updated.name,
          'attemptedSortOrder': updated.sortOrder,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
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
            widget.isEditing
                ? Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.ingredientTypeName,
                        border: const OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _updateField(),
                    ),
                  )
                : Expanded(
                    child: Text(
                      widget.type.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
            const SizedBox(width: 12),
            widget.isEditing
                ? SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.sortOrder,
                        border: const OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _updateField(),
                    ),
                  )
                : SizedBox(
                    width: 80,
                    child: Text(
                      widget.type.sortOrder.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
            const SizedBox(width: 12),
            if (_updating)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (widget.isEditing)
              IconButton(
                tooltip: loc.save,
                icon: const Icon(Icons.check),
                color: colorScheme.primary,
                onPressed: _updateField,
              )
            else
              IconButton(
                tooltip: loc.edit,
                icon: const Icon(Icons.edit),
                onPressed: widget.onEditTapped,
              ),
            IconButton(
              tooltip: loc.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onDeleteTapped,
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
