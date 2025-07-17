import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _callSetClaimsForExistingUsers() async {
    setState(() => _isLoading = true);
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'setClaimsForExistingUsers',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );
      final result = await callable.call(<String, dynamic>{});
      setState(() {
        _errorMessage = "Claims sync OK: ${result.data}";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Sync claims failed: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
      _errorMessage = null;
    });
  }

  void _handleSuccess(User? user) async {
    if (user != null) {
      await user.getIdToken(true);
      debugPrint('User signed in: ${user.email}');
      // --- START PROFILE STREAM before navigation ---
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final userProfileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      userProfileNotifier.listenToUser(firestoreService, user.uid);
      // --- THEN navigate ---
      final token =
          Provider.of<AuthService>(context, listen: false).getInviteToken();
      if (token != null) {
        Provider.of<AuthService>(context, listen: false).clearInviteToken();
        Navigator.pushReplacementNamed(context, '/franchise-onboarding',
            arguments: {'token': token});
        return;
      }
      // If no token, continue to your default post-login navigation here (if needed)
    }
  }

  void _handleError(String error) {
    setState(() => _errorMessage = error);
  }

  @override
  Widget build(BuildContext context) {
    print('[sign_in_screen.dart] build: Sign-in screen showing');
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);

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
              ElevatedButton(
                child: Text('Print ID Token'),
                onPressed: () async {
                  final token =
                      await FirebaseAuth.instance.currentUser?.getIdToken(true);
                  debugPrint('ID TOKEN: $token');
                },
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _callSetClaimsForExistingUsers,
                child: const Text("Sync Claims (TEMP ADMIN BUTTON)"),
              ),
              SocialSignInButtons(
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
