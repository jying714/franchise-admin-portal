import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/image_upload_field.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/smart_dropdown_or_text_field.dart';
import 'dart:convert';

/// Universal dynamic input renderer for schema-driven forms.
/// Handles all standard types: string, number, boolean, map (nutrition), array (not lists), image, dropdownOrText, etc.
class DynamicFieldInput extends StatelessWidget {
  final String fieldKey;
  final Map<String, dynamic> config;
  final dynamic value;
  final String? errorText;
  final ValueChanged<dynamic> onChanged;

  const DynamicFieldInput({
    super.key,
    required this.fieldKey,
    required this.config,
    required this.value,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = config['type'] as String? ?? 'string';
    final label = config['label'] is Map && config['label'].containsKey('en')
        ? config['label']['en']
        : config['label']?.toString() ?? fieldKey;
    final hint = config['hint'] is Map && config['hint'].containsKey('en')
        ? config['hint']['en']
        : config['hint']?.toString() ?? '';
    final inputMode = config['inputMode'] ?? '';
    final requiredField = config['required'] == true;

    // ✅ Normalize value for all input types
    final dynamic sanitizedValue = value is String
        ? value
        : (value is Map && value.containsKey('en'))
            ? value['en'].toString()
            : (value is Map)
                ? jsonEncode(value)
                : value?.toString() ?? '';

    Widget fieldWidget;

    switch (type) {
      case 'string':
        if (inputMode == 'imageUrlOrUpload') {
          fieldWidget = ImageUploadField(
            label: label,
            url: sanitizedValue,
            onChanged: onChanged,
          );
        } else if (inputMode == 'dropdownOrText' ||
            config['optionsSource'] != null) {
          fieldWidget = SmartDropdownOrTextField(
            fieldKey: fieldKey,
            label: label,
            value: sanitizedValue,
            optionsSource: config['optionsSource'],
            onChanged: onChanged,
            hint: hint,
            requiredField: requiredField,
          );
        } else {
          fieldWidget = TextFormField(
            initialValue: sanitizedValue,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errorText,
            ),
            onChanged: onChanged,
            validator: requiredField
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null
                : null,
          );
        }
        break;

      case 'number':
        fieldWidget = TextFormField(
          initialValue: sanitizedValue,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: errorText,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onChanged(num.tryParse(v) ?? 0),
          validator: requiredField
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        );
        break;

      case 'boolean':
        fieldWidget = SwitchListTile(
          title: Text(label),
          value: sanitizedValue == 'true' || sanitizedValue == true,
          onChanged: onChanged,
          activeColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
        );
        break;

      case 'array':
        fieldWidget = const SizedBox.shrink(); // handled by higher widget
        break;

      case 'map':
        if (fieldKey == 'nutrition') {
          fieldWidget = _buildNutritionFields(context);
        } else {
          fieldWidget = TextFormField(
            initialValue: sanitizedValue,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errorText,
            ),
            onChanged: onChanged,
          );
        }
        break;

      default:
        fieldWidget = TextFormField(
          initialValue: sanitizedValue,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: errorText,
          ),
          onChanged: onChanged,
        );
    }

    if (type != 'boolean' && (errorText ?? '').isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldWidget,
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        ],
      );
    }

    return fieldWidget;
  }

  Widget _buildNutritionFields(BuildContext context) {
    final nutrition = value is Map<String, dynamic>
        ? value
        : {"Calories": 0, "Carbs": 0, "Fat": 0, "Protein": 0};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config['label'] is Map && config['label'].containsKey('en')
              ? config['label']['en']
              : config['label']?.toString() ?? "Nutrition",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = constraints.maxWidth > 500 ? 10.0 : 6.0;
            return Wrap(
              spacing: spacing,
              runSpacing: 8.0,
              children: [
                SizedBox(
                  width: (constraints.maxWidth - spacing * 3) / 4,
                  child: TextFormField(
                    initialValue: (nutrition["Calories"] ?? 0).toString(),
                    decoration: const InputDecoration(labelText: "Calories"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onChanged({
                      ...nutrition,
                      "Calories": int.tryParse(v) ?? 0,
                    }),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - spacing * 3) / 4,
                  child: TextFormField(
                    initialValue: (nutrition["Fat"] ?? 0).toString(),
                    decoration: const InputDecoration(labelText: "Fat"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onChanged({
                      ...nutrition,
                      "Fat": double.tryParse(v) ?? 0.0,
                    }),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - spacing * 3) / 4,
                  child: TextFormField(
                    initialValue: (nutrition["Carbs"] ?? 0).toString(),
                    decoration: const InputDecoration(labelText: "Carbs"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onChanged({
                      ...nutrition,
                      "Carbs": double.tryParse(v) ?? 0.0,
                    }),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - spacing * 3) / 4,
                  child: TextFormField(
                    initialValue: (nutrition["Protein"] ?? 0).toString(),
                    decoration: const InputDecoration(labelText: "Protein"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onChanged({
                      ...nutrition,
                      "Protein": double.tryParse(v) ?? 0.0,
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
