import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared; // Phase 3 scoped fix
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class IngredientCreationDialog extends StatefulWidget {
  final String? suggestedName;
  final AppLocalizations loc;
  final List<String> availableTypeIds; // New
  final Map<String, String> typeIdToName; // New

  const IngredientCreationDialog({
    Key? key,
    this.suggestedName,
    required this.loc,
    required this.availableTypeIds,
    required this.typeIdToName,
  }) : super(key: key);

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
    final l10n = widget.loc;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uuid = const Uuid();
      final id = uuid.v4();
      final name = _nameController.text.trim();
      final typeId = _selectedTypeId;
      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);

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
        contextData: {'name': _nameController.text, 'typeId': _selectedTypeId},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.loc.genericErrorMessage),
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
      title: Text(l10n.createNewIngredient),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.ingredientName,
                  hintText: l10n.e_g_anchovies,
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTypeId,
                isExpanded: true,
                hint: Text(l10n.ingredientType),
                decoration: InputDecoration(labelText: l10n.ingredientType),
                items: widget.availableTypeIds.map((id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Text(widget.typeIdToName[id] ?? id),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedTypeId = value),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequired
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
                  labelText: l10n.upchargeOptional,
                  hintText: '1.00',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isRemovable,
                onChanged: (value) => setState(() => _isRemovable = value),
                title: Text(l10n.removable),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.create),
        ),
      ],
    );
  }
}
