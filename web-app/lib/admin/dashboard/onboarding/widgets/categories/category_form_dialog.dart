// lib/admin/dashboard/onboarding/widgets/categories/category_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/category.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? initialCategory;
  final String franchiseId;
  final AppLocalizations loc;

  const CategoryFormDialog({
    super.key,
    this.initialCategory,
    required this.franchiseId,
    required this.loc,
  });

  static Future<Category?> show({
    required BuildContext parentContext,
    Category? initialCategory,
    required String franchiseId,
  }) {
    final loc = AppLocalizations.of(parentContext)!;
    final categoryProvider =
        Provider.of<CategoryProvider>(parentContext, listen: false);
    final franchiseProvider =
        Provider.of<FranchiseProvider>(parentContext, listen: false);

    return showDialog<Category>(
      context: parentContext,
      builder: (dialogContext) =>
          ChangeNotifierProvider<FranchiseProvider>.value(
        value: franchiseProvider,
        child: ChangeNotifierProvider<CategoryProvider>.value(
          value: categoryProvider,
          child: CategoryFormDialog(
            initialCategory: initialCategory,
            franchiseId: franchiseId,
            loc: loc,
          ),
        ),
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
    final loc = widget.loc;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final firestore = context.read<FirestoreService>();
    final categoryProvider = context.read<CategoryProvider>();

    final isEdit = widget.initialCategory != null;
    final id = widget.initialCategory?.id ?? UniqueKey().toString();
    final category = Category(
      id: id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sortOrder: widget.initialCategory?.sortOrder ??
          categoryProvider.categories.length,
    );

    try {
      if (context.mounted) Navigator.of(context).pop(category);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save category',
        stack: stack.toString(),
        source: 'CategoryFormDialog',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'categoryId': id,
          'name': _nameController.text.trim(),
          'operation': isEdit ? 'update' : 'create',
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
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
                      decoration:
                          InputDecoration(labelText: loc.categoryNameLabel),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? loc.requiredField
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                          labelText: loc.categoryDescriptionLabel),
                      maxLines: 2,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                      ),
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
