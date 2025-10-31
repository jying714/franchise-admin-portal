import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../packages/shared_core/lib/src/core/services/auth_service.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../packages/shared_core/lib/src/core/providers/user_profile_notifier.dart';

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
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      // --- NEW: Check Firestore user status ---
      final userDoc = await firestoreService.getUser(user.uid);
      if (userDoc == null) {
        // Not invited or user doc deleted
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = "Your account is not authorized. Contact your admin.";
        });
        return;
      }
      if (userDoc.status != "active" && userDoc.status != "invited") {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage =
              "Your account is not active. Status: ${userDoc.status}";
        });
        return;
      }

      // Existing logic:
      final userProfileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      userProfileNotifier.listenToUser(firestoreService, user.uid);

      final token =
          Provider.of<AuthService>(context, listen: false).getInviteToken();
      if (token != null) {
        debugPrint(
            '[SignInScreen] Navigating to onboarding, token=$token'); // <-- ADD THIS LINE
        Provider.of<AuthService>(context, listen: false).clearInviteToken();
        Navigator.pushReplacementNamed(context, '/franchise-onboarding',
            arguments: {'token': token});
        return;
      }
      // Go to dashboard, etc.
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

    // --- Email/password fields state ---
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? emailError;
    String? passwordError;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: StatefulBuilder(builder: (context, setDialogState) {
            return Column(
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
                // --- EMAIL/PASSWORD SIGN-IN SECTION ---
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: loc.emailLabel ?? "Email",
                    errorText: emailError,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: loc.password ?? "Password",
                    errorText: passwordError,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscurePassword,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                              emailError = null;
                              passwordError = null;
                            });
                            final email = emailController.text.trim();
                            final password = passwordController.text;
                            // --- Simple validation
                            if (email.isEmpty || !email.contains('@')) {
                              setDialogState(() {
                                emailError =
                                    loc.emailRequired ?? "Email required";
                              });
                              setState(() => _isLoading = false);
                              return;
                            }
                            if (password.isEmpty || password.length < 6) {
                              setDialogState(() {
                                passwordError = loc.passwordTooShort ??
                                    "Password required (min 6 chars)";
                              });
                              setState(() => _isLoading = false);
                              return;
                            }
                            try {
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              final user = await authService.signInWithEmail(
                                  email, password);
                              if (user != null) {
                                _handleSuccess(user);
                              } else {
                                setState(() => _errorMessage =
                                    "Sign in failed. Check your credentials.");
                              }
                            } catch (e) {
                              setState(() => _errorMessage = e.toString());
                            }
                            setState(() => _isLoading = false);
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            loc.signInWithEmailButton ?? "Sign in with Email"),
                  ),
                ),
                // --- FORGOT PASSWORD ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              setDialogState(() {
                                emailError = loc.emailRequired ??
                                    "Enter your email above.";
                              });
                              return;
                            }
                            try {
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              await authService.resetPassword(email);
                              setState(() {
                                _errorMessage = "Password reset email sent!";
                              });
                            } catch (e) {
                              setState(() {
                                _errorMessage =
                                    "Failed to send reset email: $e";
                              });
                            }
                          },
                    child: Text(loc.forgotPassword ?? "Forgot password?"),
                  ),
                ),
                // --- DIVIDER ---
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(loc.orDivider ?? "OR"),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 10),
                // --- SOCIAL SIGN-IN BUTTONS ---
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
            );
          }),
        ),
      ),
    );
  }
}
