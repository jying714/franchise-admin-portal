import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:uuid/uuid.dart';

class CategoryCreationDialog extends StatefulWidget {
  final AppLocalizations loc;
  final String? suggestedName;

  const CategoryCreationDialog({
    Key? key,
    required this.loc,
    this.suggestedName,
  }) : super(key: key);

  @override
  State<CategoryCreationDialog> createState() => _CategoryCreationDialogState();
}

class _CategoryCreationDialogState extends State<CategoryCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.suggestedName ?? '';
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final newCategory = Category(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sortOrder: null,
      );
      Navigator.of(context).pop(newCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;

    return AlertDialog(
      title: Text(loc.createNewCategory),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.categoryName),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: loc.descriptionOptional),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(loc.create),
        ),
      ],
    );
  }
}
