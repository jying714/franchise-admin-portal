import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class MenuItemFormDialog extends StatefulWidget {
  final shared.MenuItem? initialItem;
  final List<shared.Category> categories;
  final void Function(shared.MenuItem menuItem) onSave;

  const MenuItemFormDialog({
    super.key,
    this.initialItem,
    required this.categories,
    required this.onSave,
  });

  @override
  State<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _category;
  late double _price;
  late String _description;
  String? _image;
  bool _availability = true;
  String _taxCategory = '';
  String _sku = '';
  List<String> _dietaryTags = [];
  List<String> _allergens = [];
  int? _prepTime;
  int _calories = 0;
  double _fat = 0.0, _carbs = 0.0, _protein = 0.0;

  @override
  void initState() {
    super.initState();
    final i = widget.initialItem;
    _name = i?.name ?? '';
    _category = i?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first.name : '');
    _price = i?.price ?? 0.0;
    _description = i?.description ?? '';
    _image = i?.image;
    _availability = i?.availability ?? true;
    _taxCategory = i?.taxCategory ?? '';
    _sku = i?.sku ?? '';
    _dietaryTags = List<String>.from(i?.dietaryTags ?? []);
    _allergens = List<String>.from(i?.allergens ?? []);
    _prepTime = i?.prepTime;
    _calories = i?.nutrition?.calories ?? 0;
    _fat = i?.nutrition?.fat ?? 0.0;
    _carbs = i?.nutrition?.carbs ?? 0.0;
    _protein = i?.nutrition?.protein ?? 0.0;
  }

  Widget _buildChipInput({
    required String label,
    required List<String> values,
    required ValueChanged<List<String>> onChanged,
  }) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 6.0,
          children: values
              .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      final updated = List<String>.from(values)..remove(tag);
                      onChanged(updated);
                    },
                  ))
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: 'Add $label'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty && !values.contains(text)) {
                  onChanged(List<String>.from(values)..add(text));
                  controller.clear();
                }
              },
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialItem == null ? loc.addItem : loc.editItem,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category.isNotEmpty
                      ? _category
                      : (widget.categories.isNotEmpty
                          ? widget.categories.first.name
                          : null),
                  decoration: InputDecoration(labelText: loc.colCategory),
                  items: widget.categories
                      .map((c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? ''),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? loc.requiredField : null,
                ),
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(labelText: loc.colName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? loc.nameRequired : null,
                  onChanged: (v) => setState(() => _name = v),
                ),
                TextFormField(
                  initialValue: _description,
                  decoration: InputDecoration(labelText: loc.description),
                  onChanged: (v) => setState(() => _description = v),
                ),
                TextFormField(
                  initialValue: _price.toString(),
                  decoration: InputDecoration(labelText: loc.colPrice),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    return (val == null || val < 0) ? loc.requiredField : null;
                  },
                  onChanged: (v) =>
                      setState(() => _price = double.tryParse(v) ?? 0.0),
                ),
                SwitchListTile(
                  title: Text(loc.colAvailable),
                  value: _availability,
                  onChanged: (v) => setState(() => _availability = v),
                ),
                const SizedBox(height: 16),
                // M5: dual customizations tree removed from this day-2 form.
                // Full modifier / profile editing is MenuItemEditorSheet only.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Modifiers, sizes, and profile are edited in the full menu item editor. '
                    'This dialog only updates basic fields and preserves existing canonical data on save.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    final selectedCategory = widget.categories.firstWhere(
                      (c) => c.name == _category,
                      orElse: () => widget.categories.first,
                    );

                    final existing = widget.initialItem;

                    // M5: this lightweight day-2 form must not wipe canonical
                    // profile/groups or intentional product fields on edit.
                    // Prefer MenuItemEditorSheet for full modifier editing.
                    final menuItem = shared.MenuItem(
                      id: existing?.id ?? '',
                      name: _name.trim(),
                      category: _category,
                      categoryId: selectedCategory.id,
                      price: _price,
                      description: _description.trim(),
                      image: _image?.trim().isEmpty == true
                          ? null
                          : _image?.trim(),
                      availability: _availability,
                      available: _availability,
                      customizations: existing?.customizations ?? const [],
                      customizationGroups:
                          existing?.customizationGroups ?? const [],
                      taxCategory: _taxCategory,
                      sku: _sku.trim().isEmpty ? null : _sku.trim(),
                      dietaryTags: _dietaryTags,
                      allergens: _allergens,
                      prepTime: _prepTime,
                      nutrition: shared.NutritionInfo(
                        calories: _calories,
                        fat: _fat,
                        carbs: _carbs,
                        protein: _protein,
                      ),
                      sizes: existing?.sizes,
                      sizePrices: existing?.sizePrices,
                      additionalToppingPrices:
                          existing?.additionalToppingPrices,
                      includedIngredients: existing?.includedIngredients,
                      optionalAddOns: existing?.optionalAddOns,
                      crustTypes: existing?.crustTypes,
                      cookTypes: existing?.cookTypes,
                      cutStyles: existing?.cutStyles,
                      sauceOptions: existing?.sauceOptions,
                      dressingOptions: existing?.dressingOptions,
                      maxFreeToppings: existing?.maxFreeToppings,
                      maxFreeSauces: existing?.maxFreeSauces,
                      maxFreeDressings: existing?.maxFreeDressings,
                      maxToppings: existing?.maxToppings,
                      dippingSauceOptions: existing?.dippingSauceOptions,
                      dippingSplits: existing?.dippingSplits,
                      sideDipSauceOptions: existing?.sideDipSauceOptions,
                      freeDipCupCount: existing?.freeDipCupCount,
                      sideDipUpcharge: existing?.sideDipUpcharge,
                      menuProfile: existing?.menuProfile ??
                          existing?.effectiveMenuProfile ??
                          shared.MenuProfile.standard,
                      modifierGroups: existing?.modifierGroups ??
                          existing?.effectiveModifierGroups,
                      inventoryTracked: existing?.inventoryTracked ?? false,
                      stockCount: existing?.stockCount,
                      lowStockThreshold: existing?.lowStockThreshold,
                      templateRefs: existing?.templateRefs,
                      sortOrder: existing?.sortOrder,
                      notes: existing?.notes,
                      exportId: existing?.exportId,
                    );

                    widget.onSave(menuItem);
                    Navigator.pop(context);
                  },
                  child: Text(loc.save),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
