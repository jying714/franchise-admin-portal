import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/widgets/menu_item_validator.dart';
import 'dart:convert';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/dynamic_form/smart_dropdown_or_text_field.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_field_input.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_array_editor.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/customization_group_editor.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/image_upload_field.dart';

class DynamicMenuItemForm extends StatefulWidget {
  final Map<String, dynamic> schema;
  final shared.MenuItem? initialItem;
  final void Function(shared.MenuItem menuItem) onSave;
  final VoidCallback? onCancel;
  final String franchiseId;

  const DynamicMenuItemForm({
    super.key,
    required this.schema,
    this.initialItem,
    required this.onSave,
    this.onCancel,
    required this.franchiseId,
  });

  @override
  State<DynamicMenuItemForm> createState() => _DynamicMenuItemFormState();
}

class _DynamicMenuItemFormState extends State<DynamicMenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, String?> _fieldErrors = {};

  List<Map<String, dynamic>> _includedIngredients = [];
  List<Map<String, dynamic>> _optionalAddOns = [];
  List<Map<String, dynamic>> _customizations = [];

  @override
  void didUpdateWidget(DynamicMenuItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItem != oldWidget.initialItem) {
      _initializeFromSchema();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFromSchema();
  }

  void _initializeFromSchema() {
    print(
        '[DynamicMenuItemForm] _initializeFromSchema() called - initialItem ID: ${widget.initialItem?.id ?? "null"}');
    final initial = widget.initialItem?.toJson() ?? {};
    print(
        '[DynamicMenuItemForm] initial keys from item: ${initial.keys.toList()}');
    // Only loop through scalar fields (schema['fields'])
    final fields = widget.schema['fields'] as Map<String, dynamic>? ?? {};

    for (final entry in fields.entries) {
      final key = entry.key;
      final fieldConfig = entry.value as Map<String, dynamic>;
      final value = initial[key] ?? fieldConfig['default'];
      _fieldValues[key] = _sanitizeValue(value);
    }

    print(
        '[DynamicMenuItemForm] After scalar init - fieldValues keys: ${_fieldValues.keys.toList()}');

    // Handle includedIngredients (array of maps, not a scalar field)
    if (initial['includedIngredients'] != null) {
      _includedIngredients =
          List<Map<String, dynamic>>.from(initial['includedIngredients']);
    } else {
      _includedIngredients = [];
    }

    // Handle optionalAddOns (array of maps, not a scalar field)
    if (initial['optionalAddOns'] != null) {
      _optionalAddOns =
          List<Map<String, dynamic>>.from(initial['optionalAddOns']);
    } else {
      _optionalAddOns = [];
    }

    // Handle customizations (array of maps, not a scalar field)
    if (initial['customizations'] != null) {
      _customizations =
          List<Map<String, dynamic>>.from(initial['customizations']);
    } else {
      _customizations = [];
    }

    // M5: carry canonical profile/groups through this form so Save cannot wipe them.
    if (widget.initialItem?.menuProfile != null) {
      _fieldValues['menuProfile'] = widget.initialItem!.menuProfile;
    }
    if (widget.initialItem?.modifierGroups != null &&
        widget.initialItem!.modifierGroups!.isNotEmpty) {
      _fieldValues['modifierGroups'] =
          widget.initialItem!.modifierGroups!.map((g) => g.toMap()).toList();
    }
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Map && value.containsKey('en')) {
      return value['en'].toString();
    } else if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, _sanitizeValue(v)));
    } else if (value is List) {
      return value.map((v) => _sanitizeValue(v)).toList();
    } else {
      return value;
    }
  }

  void _onSavePressed() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      print('[DEBUG] Form invalid. Aborting save.');
      return;
    }

    // Set categoryId to match category slug (not item name)
    if (_fieldValues.containsKey('category')) {
      _fieldValues['categoryId'] = (_fieldValues['category'] as String)
          .trim()
          .toLowerCase()
          .replaceAll(' ', '_');
    }

    // Set required fields
    _fieldValues['available'] = true;
    _fieldValues['schemaVersion'] = 1;
    _fieldValues['image'] ??= '';

    // Ensure base price is a number for customer UI
    if (_fieldValues.containsKey('sizePrices')) {
      final sizePrices = _fieldValues['sizePrices'] as Map<String, dynamic>;
      if (sizePrices.isNotEmpty) {
        _fieldValues['price'] = sizePrices.entries.first.value;
      }
    }

    final existing = widget.initialItem;

    final map = <String, dynamic>{
      ..._fieldValues,
      'includedIngredients': _includedIngredients,
      'optionalAddOns': _optionalAddOns,
      'customizations': _customizations,
      // M5: never drop canonical fields on this secondary form path.
      'menuProfile': _fieldValues['menuProfile'] ??
          existing?.menuProfile ??
          existing?.effectiveMenuProfile ??
          shared.MenuProfile.standard,
      if (existing?.modifierGroups != null &&
          existing!.modifierGroups!.isNotEmpty)
        'modifierGroups':
            existing.modifierGroups!.map((g) => g.toMap()).toList()
      else if (_fieldValues['modifierGroups'] is List)
        'modifierGroups': _fieldValues['modifierGroups'],
      if (existing?.sizes != null)
        'sizes': existing!.sizes!.map((s) => s.toMap()).toList(),
      if (existing?.sizePrices != null) 'sizePrices': existing!.sizePrices,
      if (existing?.additionalToppingPrices != null)
        'additionalToppingPrices': existing!.additionalToppingPrices,
      if (existing?.dippingSauceOptions != null)
        'dippingSauceOptions': existing!.dippingSauceOptions,
      if (existing?.dippingSplits != null)
        'dippingSplits': existing!.dippingSplits,
      if (existing?.sideDipSauceOptions != null)
        'sideDipSauceOptions': existing!.sideDipSauceOptions,
      if (existing?.freeDipCupCount != null)
        'freeDipCupCount': existing!.freeDipCupCount,
      if (existing?.sideDipUpcharge != null)
        'sideDipUpcharge': existing!.sideDipUpcharge,
      if (existing?.crustTypes != null) 'crustTypes': existing!.crustTypes,
      if (existing?.cookTypes != null) 'cookTypes': existing!.cookTypes,
      if (existing?.cutStyles != null) 'cutStyles': existing!.cutStyles,
      if (existing?.inventoryTracked == true) 'inventoryTracked': true,
      if (existing?.stockCount != null) 'stockCount': existing!.stockCount,
      if (existing?.lowStockThreshold != null)
        'lowStockThreshold': existing!.lowStockThreshold,
      if (existing?.templateRefs != null)
        'templateRefs': existing!.templateRefs,
      if (existing?.id != null && existing!.id.isNotEmpty) 'id': existing.id,
    };

    final item = shared.MenuItem.fromMap(
        map, existing?.id ?? map['id']?.toString() ?? '');

    // Calculate extra sauce charges if applicable (legacy schema path only)
    final saucesGroup = _customizations.firstWhere(
      (g) =>
          (g['label'] is Map ? g['label']['en'] : g['label'])
              ?.toString()
              .toLowerCase() ==
          'sauces',
      orElse: () => {},
    );

    final maxFree = _fieldValues['maxFreeSauces'] ?? 0;
    final upchargeRate =
        double.tryParse('${_fieldValues['extraSauceUpcharge'] ?? 0}') ?? 0;
    final selectedSauceCount =
        (saucesGroup['ingredientIds'] as List?)?.length ?? 0;
    final extraCount =
        selectedSauceCount > maxFree ? selectedSauceCount - maxFree : 0;

    item.extraCharges = {
      'sauceUpcharge': extraCount * upchargeRate,
    };

    print('[DEBUG] Final MenuItem for submission: ${item.toJson()}');
    widget.onSave(item);
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.schema['fields'] as Map<String, dynamic>? ?? {};
    final sortedFields = fields.entries
        .where((entry) => entry.key != 'categoryId')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...sortedFields.map((entry) {
            final key = entry.key;
            final config = entry.value as Map<String, dynamic>;
            final value = _fieldValues[key];
            final error = _fieldErrors[key];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DynamicFieldInput(
                fieldKey: key,
                config: config,
                value: value,
                errorText: error,
                onChanged: (val) {
                  setState(() => _fieldValues[key] = val);
                },
              ),
            );
          }),
          const Divider(thickness: 1.2),
          DynamicArrayEditor(
            title: 'Included Ingredients',
            arrayKey: 'includedIngredients',
            items: _includedIngredients,
            template: widget.schema['includedIngredientsTemplate'] ?? {},
            onChanged: (updated) =>
                setState(() => _includedIngredients = updated),
            franchiseId: widget.franchiseId,
          ),
          const SizedBox(height: 16),
          DynamicArrayEditor(
            title: 'Optional Add-Ons',
            arrayKey: 'optionalAddOns',
            items: _optionalAddOns,
            template: widget.schema['optionalAddOnsTemplate'] ?? {},
            onChanged: (updated) => setState(() => _optionalAddOns = updated),
            franchiseId: widget.franchiseId,
          ),
          const SizedBox(height: 16),
          // M5: this schema form is not the canonical modifier editor.
          // Full profile + modifierGroups editing is MenuItemEditorSheet only.
          // Keep residual CustomizationGroupEditor only to avoid breaking
          // category schemas that still ship a customizations block; Save
          // now preserves menuProfile/modifierGroups from the existing item.
          CustomizationGroupEditor(
            customizations: _customizations,
            onChanged: (updated) => setState(() => _customizations = updated),
            franchiseId: widget.franchiseId,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Canonical modifiers (profile, crust/cook/cut, wings binds) are edited in the full menu item editor. '
              'This form preserves those fields on save.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: widget.onCancel,
                  child: Text('Cancel'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _onSavePressed,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
