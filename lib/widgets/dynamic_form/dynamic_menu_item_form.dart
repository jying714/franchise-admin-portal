import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/widgets/menu_item_validator.dart';
import 'dart:convert';
import 'package:franchise_admin_portal/core/models/customization.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/smart_dropdown_or_text_field.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/nutrition_info.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_field_input.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_array_editor.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/customization_group_editor.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/image_upload_field.dart';

class DynamicMenuItemForm extends StatefulWidget {
  final Map<String, dynamic> schema;
  final MenuItem? initialItem;
  final void Function(MenuItem menuItem) onSave;
  final VoidCallback? onCancel;

  const DynamicMenuItemForm({
    super.key,
    required this.schema,
    this.initialItem,
    required this.onSave,
    this.onCancel,
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
  void initState() {
    super.initState();
    _initializeFromSchema();
  }

  void _initializeFromSchema() {
    final initial = widget.initialItem?.toJson() ?? {};

    // Only loop through scalar fields (schema['fields'])
    final fields = widget.schema['fields'] as Map<String, dynamic>? ?? {};

    for (final entry in fields.entries) {
      final key = entry.key;
      final fieldConfig = entry.value as Map<String, dynamic>;
      final value = initial[key] ?? fieldConfig['default'];
      _fieldValues[key] = _sanitizeValue(value);
    }

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

    final item = MenuItem.fromMap({
      ..._fieldValues,
      'includedIngredients': _includedIngredients,
      'optionalAddOns': _optionalAddOns,
      'customizations': _customizations,
    });

    // Calculate extra sauce charges if applicable
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
        .where((entry) => entry.key != 'categoryId') // <-- Exclude categoryId
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            ),
            const SizedBox(height: 16),
            DynamicArrayEditor(
              title: 'Optional Add-Ons',
              arrayKey: 'optionalAddOns',
              items: _optionalAddOns,
              template: widget.schema['optionalAddOnsTemplate'] ?? {},
              onChanged: (updated) => setState(() => _optionalAddOns = updated),
            ),
            const SizedBox(height: 16),
            CustomizationGroupEditor(
              customizations: _customizations,
              onChanged: (updated) => setState(() => _customizations = updated),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ElevatedButton(
                  onPressed: _onSavePressed,
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
