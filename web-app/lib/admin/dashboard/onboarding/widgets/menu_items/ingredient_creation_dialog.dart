import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:uuid/uuid.dart';

class IngredientCreationDialog extends StatefulWidget {
  final String? suggestedName;
  final AppLocalizations loc;
  final List<String> availableTypeIds;
  final Map<String, String> typeIdToName;

  const IngredientCreationDialog({
    super.key,
    this.suggestedName,
    required this.loc,
    required this.availableTypeIds,
    required this.typeIdToName,
  });

  @override
  State<IngredientCreationDialog> createState() =>
      _IngredientCreationDialogState();
}

class _IngredientCreationDialogState extends State<IngredientCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedTypeId;
  bool _isRemovable = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedName != null) {
      _nameController.text = widget.suggestedName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final id = const Uuid().v4();
      final name = _nameController.text.trim();
      final typeId = _selectedTypeId;
      final price = double.tryParse(_priceController.text.trim());

      final typeName = widget.typeIdToName[typeId] ?? 'Uncategorized';

      final newIngredient = shared.IngredientMetadata(
        id: id,
        name: name,
        typeId: typeId,
        type: typeName,
        allergens: [],
        removable: _isRemovable,
        upcharge: price != null ? {'default': price} : null,
        supportsExtra: true,
        sidesAllowed: true,
        notes: '',
        outOfStock: false,
        amountSelectable: false,
        amountOptions: null,
        imageUrl: null,
      );

      Navigator.of(context).pop(newIngredient);
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'ingredient_creation_failed',
        stack: stack.toString(),
        source: 'IngredientCreationDialog',
        severity: 'error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.loc.genericErrorMessage ?? 'An error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.loc;

    return AlertDialog(
      title: Text(l10n.createNewIngredient ?? 'Create New Ingredient'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.ingredientName ?? 'Ingredient Name',
                  hintText: l10n.e_g_anchovies ?? 'e.g. Anchovies',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? l10n.fieldRequired ?? 'Field required'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTypeId,
                isExpanded: true,
                hint: Text(l10n.ingredientType ?? 'Select Ingredient Type'),
                decoration: InputDecoration(
                  labelText: l10n.ingredientType ?? 'Ingredient Type',
                ),
                items: widget.availableTypeIds.map((id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Text(widget.typeIdToName[id] ?? id),
                  );
                }).toList(),
                onChanged: (value) {
                  if (mounted) {
                    setState(() => _selectedTypeId = value);
                  }
                },
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequired ?? 'Field required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                ],
                decoration: InputDecoration(
                  labelText: l10n.upchargeOptional ?? 'Upcharge (Optional)',
                  hintText: '1.00',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isRemovable,
                onChanged: (value) {
                  if (mounted) setState(() => _isRemovable = value);
                },
                title: Text(l10n.removable ?? 'Removable'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.create ?? 'Create'),
        ),
      ],
    );
  }
}
