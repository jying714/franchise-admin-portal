import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Optionally: If your user profile notifier/provider is named differently, update this import.
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

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
  bool _saving = false;

  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _name = widget.category?.name ?? '';
    _image = widget.category?.image;
    _description = widget.category?.description;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    final loc = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.category == null ? loc.addCategory : loc.editCategory),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field (required, autofocus)
                TextFormField(
                  initialValue: _name,
                  focusNode: _nameFocus,
                  decoration: InputDecoration(
                    labelText: loc.categoryName,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? loc.requiredField
                      : null,
                  onSaved: (val) => _name = val!.trim(),
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 12),
                // Image URL field
                TextFormField(
                  initialValue: _image,
                  decoration: InputDecoration(
                    labelText: loc.categoryImageUrl,
                  ),
                  onSaved: (val) => _image = val?.trim(),
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.url],
                ),
                const SizedBox(height: 12),
                // Description field
                TextFormField(
                  initialValue: _description,
                  decoration: InputDecoration(
                    labelText: loc.categoryDescription,
                  ),
                  onSaved: (val) => _description = val?.trim(),
                  minLines: 1,
                  maxLines: 3,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                ),
                // --- Placeholder for future custom fields here ---
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
          onPressed: _saving
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    setState(() => _saving = true);
                    final category = Category(
                      id: widget.category?.id ?? UniqueKey().toString(),
                      name: _name,
                      image: _image,
                      description: _description,
                    );
                    try {
                      await widget.onSaved(category);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e, stack) {
                      // --- Remote error logging to Firestore ---
                      try {
                        final userId = Provider.of<UserProfileNotifier>(context,
                                listen: false)
                            .user
                            ?.id;
                        await Provider.of<FirestoreService>(context,
                                listen: false)
                            .logError(
                          message: e.toString(),
                          source: 'category_form_dialog',
                          screen: 'CategoryFormDialog',
                          userId: userId,
                          stackTrace: stack.toString(),
                          errorType: e.runtimeType.toString(),
                          severity: 'error',
                          contextData: {
                            'categoryId': widget.category?.id ?? 'new',
                            'name': _name,
                            'image': _image,
                            'description': _description,
                          },
                        );
                      } catch (_) {
                        // If even logging fails, continue to show error to user.
                      }
                      if (context.mounted) {
                        await _showErrorDialog(
                          context,
                          AppLocalizations.of(context)!.failedToSaveCategory,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.save),
        ),
      ],
    );
  }
}
