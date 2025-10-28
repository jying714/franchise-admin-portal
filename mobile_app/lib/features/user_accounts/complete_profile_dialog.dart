import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/models/user.dart' as user_model;

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
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        completeProfile: true,
      );

      await firestore.updateUser(updatedUser);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
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
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final updatedUser = widget.user.copyWith(completeProfile: true);
      await firestore.updateUser(updatedUser);
      if (context.mounted) Navigator.of(context).pop(false);
    } catch (_) {
      // Optionally show error
      if (context.mounted) {
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        backgroundColor: DesignTokens.surfaceColor,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Padding(
          padding: DesignTokens.cardPadding,
          child: AbsorbPointer(
            absorbing: _loading,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle,
                      color: DesignTokens.primaryColor, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    l10n.completeProfileTitle,
                    style: TextStyle(
                      fontSize: DesignTokens.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.textColor,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.completeProfileMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: DesignTokens.secondaryTextColor,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(color: DesignTokens.textColor),
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
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(color: DesignTokens.textColor),
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
                            backgroundColor: DesignTokens.primaryColor,
                            foregroundColor: DesignTokens.foregroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.buttonRadius),
                            ),
                            padding: DesignTokens.buttonPadding,
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
                            foregroundColor: DesignTokens.secondaryColor,
                            side: BorderSide(
                                color: DesignTokens.secondaryColor, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.buttonRadius),
                            ),
                            padding: DesignTokens.buttonPadding,
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
