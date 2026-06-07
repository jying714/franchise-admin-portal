import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/social_sign_in_buttons.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart';

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
    if (mounted) {
      setState(() {
        _isLoading = value;
        _errorMessage = null;
      });
    }
  }

  void _handleSuccess(shared.User? user) async {
    if (!mounted) return;
    if (user != null) {
      debugPrint('User signed in: ${user.email}');

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);

      // Concrete notifier (fixes interface resolution)
      final userProfileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      userProfileNotifier.listenToUser(user.id);

      try {
        final userDoc = await firestoreService.getUser(user.id);
        if (!mounted) return;

        if (userDoc == null) {
          await FirebaseAuth.instance.signOut();
          if (mounted)
            setState(() => _errorMessage =
                "Your account is not authorized. Contact your admin.");
          return;
        }
        if (userDoc.status != "active" && userDoc.status != "invited") {
          await FirebaseAuth.instance.signOut();
          if (mounted)
            setState(() => _errorMessage =
                "Your account is not active. Status: ${userDoc.status}");
          return;
        }

        final token = Provider.of<shared.AuthService>(context, listen: false)
            .getInviteToken();
        if (token != null) {
          debugPrint('[SignInScreen] Navigating to onboarding, token=$token');
          Provider.of<shared.AuthService>(context, listen: false)
              .clearInviteToken();
          if (mounted)
            Navigator.pushReplacementNamed(context, '/franchise-onboarding',
                arguments: {'token': token});
          return;
        }

        // Explicit dashboard navigation with mounted guard
        // Explicit dashboard navigation with mounted guard + force refresh
        if (mounted) {
          // Clear any pending navigation and force root rebuild
          Navigator.of(context).pushReplacementNamed('/');
          // Optional: force a small delay for provider handoff
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) Navigator.of(context).pushReplacementNamed('/');
          });
        }
      } catch (e, stack) {
        if (mounted) {
          setState(() => _errorMessage = e.toString());
        }

        // Existing ErrorLogger (console + custom handler)
        shared.ErrorLogger.log(
          message: 'SignInScreen _handleSuccess error: $e',
          source: 'sign_in_screen.dart',
          stack: stack?.toString(),
          severity: 'error',
          contextData: {'userId': user.id, 'email': user.email},
        );

        // === DIRECT FIRESTORE LOGGING (safe signature) ===
        // === DIRECT FIRESTORE LOGGING (matches exact logError signature) ===
        // === DIRECT FIRESTORE LOGGING (exact signature + createdAt handled by service) ===
        try {
          await firestoreService.logError(
            null, // franchiseId (null during sign-in)
            message: 'SignInScreen _handleSuccess error: $e',
            source: 'sign_in_screen.dart',
            severity: 'error',
            contextData: {
              'userId': user.id,
              'email': user.email,
              'screen': 'SignInScreen',
              'method': '_handleSuccess',
            },
          );
          debugPrint(
              '[SignInScreen] Error directly logged to Firestore error_logs collection');
        } catch (logError) {
          debugPrint(
              '[SignInScreen] Failed to log error to Firestore: $logError');
        }
      }
    }
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() => _errorMessage = error);
    }
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
                              final authService =
                                  Provider.of<shared.AuthService>(context,
                                      listen: false);
                              final user =
                                  await authService.signInWithEmailAndPassword(
                                      email: email, password: password);
                              _handleSuccess(user);
                            } catch (e) {
                              if (mounted) {
                                setState(() => _errorMessage = e.toString());
                              }
                            }
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
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
                              final authService =
                                  Provider.of<shared.AuthService>(context,
                                      listen: false);
                              await authService.sendPasswordResetEmail(email);
                              if (mounted) {
                                setState(() {
                                  _errorMessage = "Password reset email sent!";
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _errorMessage =
                                      "Failed to send reset email: $e";
                                });
                              }
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
