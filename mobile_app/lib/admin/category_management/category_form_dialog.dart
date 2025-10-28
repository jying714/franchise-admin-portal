import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/core/models/category.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final Future<void> Function(Category category) onSaved;

  const CategoryFormDialog({super.key, this.category, required this.onSaved});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  String? _image;
  String? _description;

  @override
  void initState() {
    super.initState();
    _name = widget.category?.name ?? '';
    _image = widget.category?.image;
    _description = widget.category?.description;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.category == null ? loc.addCategory : loc.editCategory),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: loc.categoryName),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? loc.requiredField
                    : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              TextFormField(
                initialValue: _image,
                decoration: InputDecoration(labelText: loc.categoryImageUrl),
                onSaved: (val) => _image = val?.trim(),
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: loc.categoryDescription),
                onSaved: (val) => _description = val?.trim(),
                minLines: 1,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              final category = Category(
                id: widget.category?.id ?? UniqueKey().toString(),
                name: _name,
                image: _image,
                description: _description,
              );
              await widget.onSaved(category);
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
