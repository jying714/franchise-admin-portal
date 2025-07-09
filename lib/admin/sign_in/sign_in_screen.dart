import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
      _errorMessage = null;
    });
  }

  void _handleSuccess(User? user) {
    // Navigation happens automatically via main.dart stream
  }

  void _handleError(String error) {
    setState(() => _errorMessage = error);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId!;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                BrandingConfig.logoMain,
                height: 80,
              ),
              const SizedBox(height: 24),
              Text(
                loc.adminSignInTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.adminSignInDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SocialSignInButtons(
                franchiseId: franchiseId,
                isLoading: _isLoading,
                setLoading: _setLoading,
                onSuccess: _handleSuccess,
                onError: _handleError,
              ),
              const SizedBox(height: 16),
              Text(
                loc.adminOnlyNotice,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.hintTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
