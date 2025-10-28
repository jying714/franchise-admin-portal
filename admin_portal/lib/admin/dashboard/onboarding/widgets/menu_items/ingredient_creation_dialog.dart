import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class IngredientCreationDialog extends StatefulWidget {
  final String? suggestedName;
  final AppLocalizations loc;

  const IngredientCreationDialog({
    Key? key,
    this.suggestedName,
    required this.loc,
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
    final typeProvider = context.read<IngredientTypeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uuid = const Uuid();
      final id = uuid.v4();
      final name = _nameController.text.trim();
      final typeId = _selectedTypeId;
      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);

      final typeName = typeProvider.typeIdToName[typeId] ?? 'Uncategorized';

      final newIngredient = IngredientMetadata(
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
      await ErrorLogger.log(
        message: 'ingredient_creation_failed',
        stack: stack.toString(),
        source: 'IngredientCreationDialog',
        screen: 'ingredient_creation_dialog.dart',
        severity: 'error',
        contextData: {
          'name': _nameController.text,
          'typeId': _selectedTypeId,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.loc.genericErrorMessage),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.loc;
    final typeProvider = context.watch<IngredientTypeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.loc.createNewIngredient),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.loc.ingredientName,
                  hintText: widget.loc.e_g_anchovies,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return widget.loc.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type dropdown
              DropdownButtonFormField<String>(
                value: _selectedTypeId,
                isExpanded: true,
                hint: Text(widget.loc.ingredientType),
                decoration:
                    InputDecoration(labelText: widget.loc.ingredientType),
                items: [
                  for (final id in typeProvider.allTypeIds)
                    DropdownMenuItem(
                      value: id,
                      child: Text(typeProvider.typeIdToName[id] ?? id),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _selectedTypeId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.loc.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Upcharge field
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                ],
                decoration: InputDecoration(
                  labelText: widget.loc.upchargeOptional,
                  hintText: '1.00',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 16),

              // Removable toggle
              SwitchListTile(
                value: _isRemovable,
                onChanged: (value) {
                  setState(() => _isRemovable = value);
                },
                title: Text(widget.loc.removable),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(widget.loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.loc.create),
        ),
      ],
    );
  }
}
