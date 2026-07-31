import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as user_model;

class CompleteProfileDialog extends StatefulWidget {
  final user_model.User user;

  const CompleteProfileDialog({
    super.key,
    required this.user,
  });

  @override
  State<CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends State<CompleteProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final firestore =
          Provider.of<shared.FirestoreService>(context, listen: false);

      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        completeProfile: true,
      );

      await firestore.updateUser(updatedUser);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unexpectedError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _loading = true);
    try {
      final firestore =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final updatedUser = widget.user.copyWith(completeProfile: true);
      await firestore.updateUser(updatedUser);
      if (mounted) Navigator.of(context).pop(false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.unexpectedError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop:
          false, // prevent accidental back-button dismissal (original intent)
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        ),
        backgroundColor: shared.UiConfig.surfaceColor,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Padding(
          padding: shared.UiConfig.cardPadding,
          child: AbsorbPointer(
            absorbing: _loading,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle,
                      color: Theme.of(context).colorScheme.primary, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    l10n.completeProfileTitle,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.titleFontSize,
                      fontWeight: shared.UiConfig.bold,
                      color: shared.UiConfig.textColor,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.completeProfileMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.bodyFontSize,
                      color: shared.UiConfig.secondaryTextColor,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(color: shared.UiConfig.textColor),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.enterName
                        : null,
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(color: shared.UiConfig.textColor),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          !RegExp(r'^\+?\d{7,}$').hasMatch(value.trim())) {
                        return l10n.invalidPhoneNumber;
                      }
                      return null;
                    },
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: shared.UiConfig.primaryColor,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.buttonRadius),
                            ),
                            padding: shared.UiConfig.defaultPadding,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  l10n.saveAndContinue,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: shared.UiConfig.secondaryColor,
                            side: BorderSide(
                                color: shared.UiConfig.secondaryColor,
                                width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.buttonRadius),
                            ),
                            padding: shared.UiConfig.defaultPadding,
                          ),
                          child: Text(l10n.skipForNow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
