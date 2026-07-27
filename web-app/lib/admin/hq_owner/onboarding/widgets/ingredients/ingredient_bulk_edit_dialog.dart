import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_tag_selector.dart';

class IngredientBulkEditDialog extends StatefulWidget {
  final Set<String> selectedIds;
  final AppLocalizations loc;
  final BuildContext parentContext;
  final VoidCallback? onSaved;

  const IngredientBulkEditDialog({
    super.key,
    required this.selectedIds,
    required this.loc,
    required this.parentContext,
    this.onSaved,
  });

  @override
  State<IngredientBulkEditDialog> createState() =>
      _IngredientBulkEditDialogState();
}

class _IngredientBulkEditDialogState extends State<IngredientBulkEditDialog> {
  String? _selectedTypeId;
  List<String> _allergens = [];
  bool _removable = true;
  bool _supportsExtra = false;
  bool _sidesAllowed = false;
  bool _outOfStock = false;

  /// When false, that field is left unchanged on save.
  bool _applyType = false;
  bool _applyAllergens = false;
  bool _applyRemovable = false;
  bool _applySupportsExtra = false;
  bool _applySidesAllowed = false;
  bool _applyOutOfStock = false;

  bool _isSaving = false;

  Future<void> _save() async {
    if (!_applyType &&
        !_applyAllergens &&
        !_applyRemovable &&
        !_applySupportsExtra &&
        !_applySidesAllowed &&
        !_applyOutOfStock) {
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(content: Text('Select at least one field to update')),
        );
      }
      return;
    }

    final host = widget.parentContext;
    final meta =
        Provider.of<IngredientMetadataProviderImpl>(host, listen: false);
    final typeProvider =
        Provider.of<IngredientTypeProviderImpl>(host, listen: false);

    String? typeName;
    if (_applyType) {
      final typeId = (_selectedTypeId ?? '').trim();
      if (typeId.isEmpty) {
        if (host.mounted) {
          ScaffoldMessenger.of(host).showSnackBar(
            SnackBar(content: Text(widget.loc.requiredField)),
          );
        }
        return;
      }
      final matched = typeProvider.ingredientTypes.where((t) => t.id == typeId);
      typeName = matched.isNotEmpty ? matched.first.name : null;
      if (typeName == null || typeName.isEmpty) {
        if (host.mounted) {
          ScaffoldMessenger.of(host).showSnackBar(
            const SnackBar(content: Text('Ingredient type name is required')),
          );
        }
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      var count = 0;
      for (final id in widget.selectedIds) {
        final existing = meta.ingredients.where((e) => e.id == id);
        if (existing.isEmpty) continue;
        final cur = existing.first;

        final next = shared.IngredientMetadata(
          id: cur.id,
          name: cur.name,
          type: _applyType ? typeName! : cur.type,
          notes: cur.notes,
          allergens:
              _applyAllergens ? List<String>.from(_allergens) : cur.allergens,
          removable: _applyRemovable ? _removable : cur.removable,
          supportsExtra:
              _applySupportsExtra ? _supportsExtra : cur.supportsExtra,
          sidesAllowed: _applySidesAllowed ? _sidesAllowed : cur.sidesAllowed,
          outOfStock: _applyOutOfStock ? _outOfStock : cur.outOfStock,
          typeId: _applyType ? (_selectedTypeId ?? '').trim() : cur.typeId,
          upcharge: cur.upcharge,
          imageUrl: cur.imageUrl,
          amountSelectable: cur.amountSelectable,
          amountOptions: cur.amountOptions,
        );
        meta.updateIngredient(next);
        count++;
      }

      await meta.saveChanges();

      if (host.mounted) {
        ScaffoldMessenger.of(host).showSnackBar(
          SnackBar(content: Text('Updated $count ingredient(s)')),
        );
      }
      widget.onSaved?.call();
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed bulk edit ingredients: $e',
        source: 'IngredientBulkEditDialog',
        stack: stack.toString(),
        severity: 'error',
      );
      if (host.mounted) {
        ScaffoldMessenger.of(host).showSnackBar(
          SnackBar(content: Text(widget.loc.errorSavingIngredient)),
        );
      }
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final ingredientTypes = Provider.of<IngredientTypeProviderImpl>(
      widget.parentContext,
      listen: false,
    ).ingredientTypes;
    final typeIds = ingredientTypes.map((t) => (t.id ?? '').trim()).toSet();
    final safeTypeId = (_selectedTypeId != null &&
            typeIds.contains((_selectedTypeId ?? '').trim()))
        ? _selectedTypeId
        : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 725),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Group edit (${widget.selectedIds.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only checked fields are applied. Name and description stay per-item.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Type
              CheckboxListTile(
                value: _applyType,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.ingredientType),
                onChanged: (v) => setState(() => _applyType = v ?? false),
              ),
              if (_applyType)
                DropdownButtonFormField<String>(
                  value: safeTypeId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: loc.ingredientType,
                    border: const OutlineInputBorder(),
                  ),
                  items: ingredientTypes
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTypeId = val),
                ),
              const SizedBox(height: 12),

              // Allergens
              CheckboxListTile(
                value: _applyAllergens,
                contentPadding: EdgeInsets.zero,
                title: const Text('Allergen tags'),
                onChanged: (v) => setState(() => _applyAllergens = v ?? false),
              ),
              if (_applyAllergens)
                IngredientTagSelector(
                  selectedTags: _allergens,
                  onChanged: (tags) => setState(() => _allergens = tags),
                  loc: loc,
                ),
              const SizedBox(height: 12),

              // Flags
              CheckboxListTile(
                value: _applyRemovable,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.removable),
                secondary: _applyRemovable
                    ? Switch(
                        value: _removable,
                        onChanged: (v) => setState(() => _removable = v),
                      )
                    : null,
                onChanged: (v) => setState(() => _applyRemovable = v ?? false),
              ),
              CheckboxListTile(
                value: _applySupportsExtra,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.supportsExtra),
                secondary: _applySupportsExtra
                    ? Switch(
                        value: _supportsExtra,
                        onChanged: (v) => setState(() => _supportsExtra = v),
                      )
                    : null,
                onChanged: (v) =>
                    setState(() => _applySupportsExtra = v ?? false),
              ),
              CheckboxListTile(
                value: _applySidesAllowed,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.sidesAllowed),
                secondary: _applySidesAllowed
                    ? Switch(
                        value: _sidesAllowed,
                        onChanged: (v) => setState(() => _sidesAllowed = v),
                      )
                    : null,
                onChanged: (v) =>
                    setState(() => _applySidesAllowed = v ?? false),
              ),
              CheckboxListTile(
                value: _applyOutOfStock,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.outOfStock),
                secondary: _applyOutOfStock
                    ? Switch(
                        value: _outOfStock,
                        onChanged: (v) => setState(() => _outOfStock = v),
                      )
                    : null,
                onChanged: (v) => setState(() => _applyOutOfStock = v ?? false),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.saveIngredient),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
