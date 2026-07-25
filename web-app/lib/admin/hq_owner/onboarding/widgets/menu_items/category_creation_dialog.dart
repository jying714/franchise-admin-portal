import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:uuid/uuid.dart';

class CategoryCreationDialog extends StatefulWidget {
  final AppLocalizations loc;
  final String? suggestedName;

  const CategoryCreationDialog({
    super.key,
    required this.loc,
    this.suggestedName,
  });

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
      final newCategory = shared.Category(
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
      title: Text(loc.createNewCategory ?? 'Create New Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.categoryName ?? 'Category Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.requiredField ?? 'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: loc.descriptionOptional ?? 'Description (Optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(loc.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(loc.create ?? 'Create'),
        ),
      ],
    );
  }
}
