import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../package:shared_core/src/core/models/ingredient_type_model.dart';
import '../package:shared_core/src/core/utils/error_logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IngredientTypeCreationDialog extends StatefulWidget {
  final AppLocalizations loc;
  final String? suggestedName;

  const IngredientTypeCreationDialog({
    Key? key,
    required this.loc,
    this.suggestedName,
  }) : super(key: key);

  @override
  State<IngredientTypeCreationDialog> createState() =>
      _IngredientTypeCreationDialogState();
}

class _IngredientTypeCreationDialogState
    extends State<IngredientTypeCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedName != null) {
      _nameController.text = widget.suggestedName!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final id = _nameController.text.trim().toLowerCase().replaceAll(' ', '_');

      final type = IngredientType(
        id: id,
        name: _nameController.text.trim(),
        systemTag: _tagController.text.trim().isNotEmpty
            ? _tagController.text.trim()
            : null,
        sortOrder: 999, // Default to bottom
      );

      Navigator.of(context).pop(type);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_type_creation_failed',
        source: 'IngredientTypeCreationDialog',
        stack: stack.toString(),
        screen: 'ingredient_type_creation_dialog.dart',
        severity: 'error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.loc.genericErrorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;

    return AlertDialog(
      title: Text(loc.createNewIngredientType),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.typeName,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return loc.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]'))
              ],
              decoration: InputDecoration(
                labelText: loc.systemTagOptional,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.create),
        ),
      ],
    );
  }
}


