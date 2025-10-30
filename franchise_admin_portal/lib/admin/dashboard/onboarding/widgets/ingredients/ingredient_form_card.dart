import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_tag_selector.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';

class IngredientFormCard extends StatefulWidget {
  final IngredientMetadata? initialData;
  final VoidCallback? onSaved;
  final AppLocalizations loc;
  final BuildContext parentContext;

  const IngredientFormCard({
    Key? key,
    this.initialData,
    this.onSaved,
    required this.loc,
    required this.parentContext,
  }) : super(key: key);

  @override
  State<IngredientFormCard> createState() => _IngredientFormCardState();
}

class _IngredientFormCardState extends State<IngredientFormCard> {
  String? _selectedTypeId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();
  List<String> _allergens = [];

  bool _removable = true;
  bool _supportsExtra = false;
  bool _sidesAllowed = false;
  bool _outOfStock = false;

  bool _isSaving = false;

  late final String _id;

  final GlobalKey _formRootKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    final provider = context.read<IngredientMetadataProvider>();

    // Stable ID for highlight mapping
    _id = data?.id ?? '_new_${DateTime.now().millisecondsSinceEpoch}';

    // 🔹 Register card-level key for section-level focus
    provider.itemGlobalKeys[_id] ??= GlobalKey();

    // Register highlight keys (only once)
    provider.fieldGlobalKeys['$_id::name'] ??= GlobalKey();
    provider.fieldGlobalKeys['$_id::typeId'] ??= GlobalKey();
    provider.fieldGlobalKeys['$_id::notes'] ??= GlobalKey();
    provider.fieldGlobalKeys['$_id::allergens'] ??= GlobalKey();

    if (data != null) {
      _nameController.text = data.name;
      _typeController.text = data.type;
      _selectedTypeId = data.typeId;
      _notesController.text = data.notes ?? '';
      _allergens = List.from(data.allergens);
      _removable = data.removable;
      _supportsExtra = data.supportsExtra;
      _sidesAllowed = data.sidesAllowed;
      _outOfStock = data.outOfStock;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredient = IngredientMetadata(
      id: widget.initialData?.id ??
          _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
      name: _nameController.text.trim(),
      type: _typeController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      allergens: _allergens,
      removable: _removable,
      supportsExtra: _supportsExtra,
      sidesAllowed: _sidesAllowed,
      outOfStock: _outOfStock,
      upcharge: null,
      imageUrl: null,
      amountSelectable: false,
      amountOptions: null,
      typeId: _selectedTypeId,
    );

    try {
      setState(() => _isSaving = true);

      context.read<IngredientMetadataProvider>().updateIngredient(ingredient);

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to update ingredient (local only): $e',
        stack: stack.toString(),
        source: 'IngredientFormCard',
        screen: 'OnboardingIngredientsScreen',
        severity: 'error',
        contextData: {'ingredientName': ingredient.name},
      );

      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(widget.loc.errorSavingIngredient)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = widget.loc;
    final colorScheme = theme.colorScheme;
    final ingredientTypes =
        context.watch<IngredientTypeProvider>().ingredientTypes;
    final provider = context.read<IngredientMetadataProvider>();

    if (_selectedTypeId == null && ingredientTypes.isNotEmpty) {
      _selectedTypeId = ingredientTypes.first.id;
      _typeController.text = ingredientTypes.first.name;
    }

    return KeyedSubtree(
        key: _formRootKey,
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 725,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      key: provider.fieldGlobalKeys['$_id::name'],
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.ingredientName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? loc.requiredField
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: provider.fieldGlobalKeys['$_id::typeId'],
                      value: _selectedTypeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: loc.ingredientType,
                        border: const OutlineInputBorder(),
                      ),
                      items: ingredientTypes.map((type) {
                        return DropdownMenuItem(
                          value: type.id,
                          child: Text(type.name),
                        );
                      }).toList(),
                      validator: (val) =>
                          val == null ? loc.requiredField : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedTypeId = val;
                          final type = ingredientTypes.firstWhere(
                            (t) => t.id == val,
                            orElse: () => IngredientType(id: '', name: ''),
                          );
                          _typeController.text = type.name;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    IngredientTagSelector(
                      key: provider.fieldGlobalKeys['$_id::allergens'],
                      selectedTags: _allergens,
                      onChanged: (tags) => setState(() => _allergens = tags),
                      loc: loc,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: provider.fieldGlobalKeys['$_id::notes'],
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: loc.ingredientDescription,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        CheckboxListTile(
                          value: _removable,
                          onChanged: (v) =>
                              setState(() => _removable = v ?? true),
                          title: Text(loc.removable),
                        ),
                        CheckboxListTile(
                          value: _supportsExtra,
                          onChanged: (v) =>
                              setState(() => _supportsExtra = v ?? false),
                          title: Text(loc.supportsExtra),
                        ),
                        CheckboxListTile(
                          value: _sidesAllowed,
                          onChanged: (v) =>
                              setState(() => _sidesAllowed = v ?? false),
                          title: Text(loc.sidesAllowed),
                        ),
                        CheckboxListTile(
                          value: _outOfStock,
                          onChanged: (v) =>
                              setState(() => _outOfStock = v ?? false),
                          title: Text(loc.outOfStock),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveIngredient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Text(loc.saveIngredient),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
