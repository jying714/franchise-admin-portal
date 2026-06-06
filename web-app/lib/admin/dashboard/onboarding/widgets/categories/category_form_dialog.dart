import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;

class CategoryFormDialog extends StatefulWidget {
  final shared.Category? initialCategory;
  final String franchiseId;
  final AppLocalizations loc;

  const CategoryFormDialog({
    super.key,
    this.initialCategory,
    required this.franchiseId,
    required this.loc,
  });

  static Future<shared.Category?> show({
    required BuildContext parentContext,
    shared.Category? initialCategory,
    required String franchiseId,
  }) {
    final loc = AppLocalizations.of(parentContext)!;

    return showDialog<shared.Category>(
      context: parentContext,
      builder: (dialogContext) => CategoryFormDialog(
        initialCategory: initialCategory,
        franchiseId: franchiseId,
        loc: loc,
      ),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCategory?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialCategory?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final loc = widget.loc;

    try {
      final categoryProvider =
          Provider.of<shared.CategoryProvider>(context, listen: false);
      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);

      final isEdit = widget.initialCategory != null;
      final id = widget.initialCategory?.id ?? UniqueKey().toString();

      final category = shared.Category(
        id: id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sortOrder: widget.initialCategory?.sortOrder ??
            categoryProvider.categories.length,
        isActive: true,
      );

      categoryProvider.addOrUpdateCategory(category);

      if (mounted) {
        Navigator.of(context).pop(category);
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to save category: $e',
        stack: stack.toString(),
        source: 'CategoryFormDialog',
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
          'isEdit': widget.initialCategory != null,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialCategory == null
                    ? loc.addCategoryTitle
                    : loc.editCategoryTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.categoryNameLabel,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? loc.requiredField
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: loc.categoryDescriptionLabel,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitForm,
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(loc.save),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
