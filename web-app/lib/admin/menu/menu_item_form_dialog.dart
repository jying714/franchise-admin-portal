import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/models/customization.dart';
import 'package:franchise_admin_portal/core/models/nutrition_info.dart';
import 'package:franchise_admin_portal/admin/menu/menu_item_customizations_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/menu/customization_types.dart';

class MenuItemFormDialog extends StatefulWidget {
  final MenuItem? initialItem;
  final List<Category> categories;
  final void Function(MenuItem menuItem) onSave;

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
  List<Customization> _customizations = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initialItem;
    _name = i?.name ?? '';
    _category = i?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first.name : '');
    _price = i?.price ?? 0.0;
    _description = i?.description ?? '';
    _image = i?.image ?? '';
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
    _customizations = List<Customization>.from(i?.customizations ?? []);
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
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.addChipHint(label) ??
                      'Add $label',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty && !values.contains(text)) {
                  onChanged(List<String>.from(values)..add(text));
                  controller.clear();
                  setState(() {});
                }
              },
            )
          ],
        )
      ],
    );
  }

  // ======= REVISED CONVERSION HELPERS =======
  // Use new structure for customizations.
  CustomizationGroup customizationToGroup(Customization c) =>
      customizationToGroupFull(c);

  Customization groupToCustomization(CustomizationGroup g) =>
      groupToCustomizationFull(g);

  CustomizationGroup customizationToGroupFull(Customization c) {
    return CustomizationGroup(
      groupName: c.name,
      type: (c.maxChoices ?? 1) > 1 ? 'multi' : 'single',
      minSelect: c.minChoices ?? 1,
      maxSelect: c.maxChoices ?? 1,
      maxFree: c.maxFree,
      allowExtra: c.allowExtra,
      allowSide: c.allowSide,
      required: c.required,
      groupUpcharge: c.price > 0.0 ? c.price : null,
      groupTag: c.group,
      options: (c.options ?? [])
          .map((o) => CustomizationOption(
                name: o.name,
                price: o.price,
                upcharges: o.upcharges,
                isDefault: o.isDefault,
                outOfStock: o.outOfStock,
                allowExtra: o.allowExtra,
                allowSide: o.allowSide,
                quantity: o.quantity,
                portion: o.portion,
                tag: o.group,
                // Removed: supportsExtra, sidesAllowed -- not standard
              ))
          .toList(),
    );
  }

  Customization groupToCustomizationFull(CustomizationGroup g) {
    return Customization(
      name: g.groupName,
      isGroup: true,
      price: g.groupUpcharge ?? 0.0,
      required: g.required,
      minChoices: g.minSelect,
      maxChoices: g.maxSelect,
      maxFree: g.maxFree,
      group: g.groupTag,
      allowExtra: g.allowExtra,
      allowSide: g.allowSide,
      options: g.options
          .map((o) => Customization(
                name: o.name,
                isGroup: false,
                price: o.price,
                upcharges: o.upcharges,
                isDefault: o.isDefault,
                outOfStock: o.outOfStock,
                allowExtra: o.allowExtra,
                allowSide: o.allowSide,
                quantity: o.quantity,
                portion: o.portion,
                group: o.tag,
                // Removed: supportsExtra, sidesAllowed -- not standard
              ))
          .toList(),
    );
  }

  void _openCustomizationDialog() async {
    final groups = _customizations.map(customizationToGroup).toList();
    final result = await showDialog<List<CustomizationGroup>>(
      context: context,
      builder: (ctx) => MenuItemCustomizationsDialog(
        initialGroups: groups,
      ),
    );
    if (result != null) {
      setState(
          () => _customizations = result.map(groupToCustomization).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialItem == null
                      ? localizations.addItem
                      : localizations.edit,
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
                  decoration:
                      InputDecoration(labelText: localizations.colCategory),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? ''),
                  validator: (v) => (v == null || v.isEmpty)
                      ? localizations.requiredField
                      : null,
                ),
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(labelText: localizations.colName),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? localizations.nameRequired
                      : null,
                  onChanged: (v) => setState(() => _name = v),
                ),
                TextFormField(
                  initialValue: _description,
                  decoration:
                      InputDecoration(labelText: localizations.description),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? localizations.requiredField
                      : null,
                  onChanged: (v) => setState(() => _description = v),
                ),
                TextFormField(
                  initialValue: _image ?? '',
                  decoration:
                      InputDecoration(labelText: localizations.colImage),
                  onChanged: (v) => setState(() => _image = v),
                ),
                TextFormField(
                  initialValue: _price.toString(),
                  decoration:
                      InputDecoration(labelText: localizations.colPrice),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value < 0) {
                      return localizations.requiredField;
                    }
                    return null;
                  },
                  onChanged: (v) =>
                      setState(() => _price = double.tryParse(v) ?? 0.0),
                ),
                TextFormField(
                  initialValue: _taxCategory,
                  decoration: InputDecoration(labelText: localizations.tax),
                  onChanged: (v) => setState(() => _taxCategory = v),
                ),
                TextFormField(
                  initialValue: _sku,
                  decoration: InputDecoration(labelText: localizations.colSKU),
                  onChanged: (v) => setState(() => _sku = v),
                ),
                SwitchListTile(
                  title: Text(localizations.colAvailable),
                  value: _availability,
                  onChanged: (v) => setState(() => _availability = v),
                ),
                TextFormField(
                  initialValue: _prepTime?.toString() ?? '',
                  decoration: InputDecoration(labelText: localizations.time),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _prepTime = int.tryParse(v)),
                ),
                const SizedBox(height: 8),
                Text(localizations.nutrition,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _calories.toString(),
                        decoration: InputDecoration(
                            labelText: localizations.caloriesLabel),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            setState(() => _calories = int.tryParse(v) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _fat.toString(),
                        decoration:
                            InputDecoration(labelText: localizations.fatLabel),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            setState(() => _fat = double.tryParse(v) ?? 0.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _carbs.toString(),
                        decoration: InputDecoration(
                            labelText: localizations.carbsLabel),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            setState(() => _carbs = double.tryParse(v) ?? 0.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _protein.toString(),
                        decoration: InputDecoration(
                            labelText: localizations.proteinLabel),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(
                            () => _protein = double.tryParse(v) ?? 0.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildChipInput(
                  label: localizations.colDietary,
                  values: _dietaryTags,
                  onChanged: (v) => setState(() => _dietaryTags = v),
                ),
                const SizedBox(height: 8),
                _buildChipInput(
                  label: localizations.colAllergens,
                  values: _allergens,
                  onChanged: (v) => setState(() => _allergens = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(localizations.customizations,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: localizations.editCustomization,
                      onPressed: _openCustomizationDialog,
                    ),
                  ],
                ),
                _customizations.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          localizations.noCustomizations,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _customizations.length,
                        itemBuilder: (context, idx) {
                          final c = _customizations[idx];
                          return ListTile(
                            title: Text(
                              '${c.name} ${(c.options != null && c.options!.isNotEmpty) ? '(${c.options!.length} options)' : ''}',
                            ),
                            subtitle: c.options != null && c.options!.isNotEmpty
                                ? Text(c.options!.map((o) => o.name).join(', '))
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() => _customizations.removeAt(idx));
                              },
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final nutrition = NutritionInfo(
                          calories: _calories,
                          fat: _fat,
                          carbs: _carbs,
                          protein: _protein,
                        );
                        final selectedCategory = widget.categories.firstWhere(
                          (c) => c.name == _category,
                          orElse: () => widget.categories.first,
                        );
                        final menuItem = MenuItem(
                          id: widget.initialItem?.id ?? '',
                          available: _availability,
                          category: _category,
                          categoryId: selectedCategory.id,
                          name: _name.trim(),
                          price: _price,
                          description: _description.trim(),
                          customizationGroups: [],
                          image: _image?.trim().isEmpty ?? true
                              ? null
                              : _image?.trim(),
                          customizations: _customizations,
                          taxCategory: _taxCategory,
                          availability: _availability,
                          sku: _sku.trim().isEmpty ? null : _sku.trim(),
                          dietaryTags: _dietaryTags,
                          allergens: _allergens,
                          prepTime: _prepTime,
                          nutrition: nutrition,
                        );

                        widget.onSave(menuItem);
                        Navigator.pop(context);
                      },
                      child: Text(localizations.save),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.cancel),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
