import 'package:flutter/material.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/nutrition_info.dart';
import 'package:franchise_admin_portal/core/utils/features/form_validators.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A dialog that allows editing or creating `NutritionInfo`.
///
/// Used inside [MenuItemEditorSheet] when nutritional_info feature is enabled.
class NutritionEditorDialog extends StatefulWidget {
  final NutritionInfo? initialValue;

  const NutritionEditorDialog({Key? key, this.initialValue}) : super(key: key);

  @override
  State<NutritionEditorDialog> createState() => _NutritionEditorDialogState();
}

class _NutritionEditorDialogState extends State<NutritionEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _caloriesController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue;

    _caloriesController =
        TextEditingController(text: init?.calories.toString() ?? '');
    _fatController = TextEditingController(text: init?.fat.toString() ?? '');
    _carbsController =
        TextEditingController(text: init?.carbs.toString() ?? '');
    _proteinController =
        TextEditingController(text: init?.protein.toString() ?? '');
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final result = NutritionInfo(
      calories: double.tryParse(_caloriesController.text.trim())?.round() ?? 0,
      fat: double.tryParse(_fatController.text.trim()) ?? 0.0,
      carbs: double.tryParse(_carbsController.text.trim()) ?? 0.0,
      protein: double.tryParse(_proteinController.text.trim()) ?? 0.0,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.editNutrition),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(
              controller: _caloriesController,
              label: loc.calories,
              suffix: 'kcal',
            ),
            _buildField(
              controller: _fatController,
              label: loc.fat,
              suffix: 'g',
            ),
            _buildField(
              controller: _carbsController,
              label: loc.carbohydrates,
              suffix: 'g',
            ),
            _buildField(
              controller: _proteinController,
              label: loc.protein,
              suffix: 'g',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(loc.save),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: FormValidators.nonNegativeNumber,
      ),
    );
  }
}
