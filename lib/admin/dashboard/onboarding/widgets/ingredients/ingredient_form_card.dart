import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_tag_selector.dart';

class IngredientFormCard extends StatefulWidget {
  final IngredientMetadata? initialData;
  final VoidCallback? onSaved;

  const IngredientFormCard({
    Key? key,
    this.initialData,
    this.onSaved,
  }) : super(key: key);

  @override
  State<IngredientFormCard> createState() => _IngredientFormCardState();
}

class _IngredientFormCardState extends State<IngredientFormCard> {
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

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _nameController.text = data.name;
      _typeController.text = data.type;
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

    final firestore = context.read<FirestoreService>();
    final franchiseId = context.read<FranchiseInfoProvider>().franchise?.id;
    final l10n = AppLocalizations.of(context)!;

    if (franchiseId == null || franchiseId.isEmpty) {
      await ErrorLogger.log(
        message: 'Franchise ID missing during ingredient save',
        source: 'IngredientFormCard',
        screen: 'OnboardingIngredientsScreen',
        severity: 'error',
      );
      return;
    }

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
    );

    try {
      setState(() => _isSaving = true);
      await firestore.createOrUpdateIngredientMetadata(
        franchiseId: franchiseId,
        ingredient: ingredient,
      );
      if (widget.onSaved != null) widget.onSaved!();
      Navigator.of(context).pop();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save ingredient: $e',
        stack: stack.toString(),
        source: 'IngredientFormCard',
        screen: 'OnboardingIngredientsScreen',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'ingredientName': ingredient.name
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSavingIngredient)),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.ingredientName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: l10n.ingredientType,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              IngredientTagSelector(
                selectedTags: _allergens,
                onChanged: (tags) => setState(() => _allergens = tags),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.ingredientDescription,
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
                    onChanged: (v) => setState(() => _removable = v ?? true),
                    title: Text(l10n.removable),
                  ),
                  CheckboxListTile(
                    value: _supportsExtra,
                    onChanged: (v) =>
                        setState(() => _supportsExtra = v ?? false),
                    title: Text(l10n.supportsExtra),
                  ),
                  CheckboxListTile(
                    value: _sidesAllowed,
                    onChanged: (v) =>
                        setState(() => _sidesAllowed = v ?? false),
                    title: Text(l10n.sidesAllowed),
                  ),
                  CheckboxListTile(
                    value: _outOfStock,
                    onChanged: (v) => setState(() => _outOfStock = v ?? false),
                    title: Text(l10n.outOfStock),
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
                      : Text(l10n.saveIngredient),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
