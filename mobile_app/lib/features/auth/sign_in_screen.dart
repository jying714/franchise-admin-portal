// ignore_for_file: unused_import, prefer_const_constructors

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doughboys_pizzeria_final/core/services/auth_service.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/models/user.dart' as db_user;
import 'package:doughboys_pizzeria_final/features/main_menu/main_menu_screen.dart';
import 'package:doughboys_pizzeria_final/features/user_accounts/profile_screen.dart'; // <-- Make sure this is imported!
import 'package:doughboys_pizzeria_final/config/app_config.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:doughboys_pizzeria_final/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;
  bool _passwordVisible = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Ensures a Firestore user profile exists for this Firebase [user].
  /// If not present, creates it with the default safe fields (role: 'customer').
  Future<void> _ensureUserProfile(User user) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final existing = await firestoreService.getUser(user.uid);
    if (existing == null) {
      final newUser = db_user.User(
        id: user.uid,
        name: user.displayName ?? "",
        email: user.email ?? "",
        phoneNumber: user.phoneNumber,
        addresses: [],
        orders: [],
        favorites: [],
        scheduledOrders: [],
        language: "en",
        loyalty: null,
        role: db_user.User.roleCustomer, // Always default to 'customer'
      );
      await firestoreService.addUser(newUser);
    }
  }

  /// Handles standard email/password sign-in.
  Future<void> _signIn(BuildContext ctx) async {
    final authService = Provider.of<AuthService>(ctx, listen: false);
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final user = await authService.signInWithEmail(email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    final loc = AppLocalizations.of(context)!;
    if (user != null) {
      try {
        await _ensureUserProfile(user);

        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        final dbUser = await firestoreService.getUser(user.uid);

        if (!mounted) return;
        // If completeProfile is false or missing, route to ProfileScreen (will show dialog)
        if (dbUser == null || !(dbUser.completeProfile ?? false)) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = loc.signInProfileError;
        });
      }
    } else {
      setState(() {
        _error = loc.signInFailed;
      });
    }
  }

  /// Triggers password reset flow.
  Future<void> _resetPassword(BuildContext ctx) async {
    final authService = Provider.of<AuthService>(ctx, listen: false);
    final email = _emailController.text.trim();
    final loc = AppLocalizations.of(context)!;
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = loc.validEmailRequired;
      });
      return;
    }
    try {
      await authService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.passwordResetSent)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = loc.passwordResetFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.signIn,
          style: TextStyle(
            color: DesignTokens.foregroundColor,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        centerTitle: true,
        backgroundColor: DesignTokens.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.foregroundColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: DesignTokens.gridPadding,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            elevation: DesignTokens.cardElevation,
            color: DesignTokens.surfaceColor,
            child: Padding(
              padding: DesignTokens.cardPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(BrandingConfig.logoMain,
                        height: DesignTokens.logoHeightMedium),
                    const SizedBox(height: 32),
                    // --- Social sign-in buttons (now only Google/Phone) ---
                    SocialSignInButtons(
                      onSuccess: (User? user) async {
                        if (user != null) {
                          setState(() => _loading = true);
                          try {
                            await _ensureUserProfile(user);

                            final firestoreService =
                                Provider.of<FirestoreService>(context,
                                    listen: false);
                            final dbUser =
                                await firestoreService.getUser(user.uid);

                            if (!mounted) return;
                            if (dbUser == null ||
                                !(dbUser.completeProfile ?? false)) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                                (route) => false,
                              );
                            } else {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const MainMenuScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = loc.signInProfileError;
                            });
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        }
                      },
                      onError: (String err) {
                        setState(() => _error = err);
                      },
                      isLoading: _loading,
                      setLoading: (bool loading) =>
                          setState(() => _loading = loading),
                      // Only show Google and Phone sign-in
                      showPhone: true,
                    ),
                    // Removed Apple sign-in (disabled button) block
                    const Divider(height: 36, thickness: 1),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: loc.email,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                        prefixIcon: Icon(DesignTokens.emailIcon),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : loc.validEmailRequired,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      style: TextStyle(color: DesignTokens.textColor),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: loc.password,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                        prefixIcon: Icon(DesignTokens.lockIcon),
                        suffixIcon: IconButton(
                          icon: Icon(_passwordVisible
                              ? DesignTokens.visibilityIcon
                              : DesignTokens.visibilityOffIcon),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (value) => value != null && value.length >= 6
                          ? null
                          : loc.passwordTooShort,
                      autofillHints: const [AutofillHints.password],
                      style: TextStyle(color: DesignTokens.textColor),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            _loading ? null : () => _resetPassword(context),
                        child: Text(loc.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: DesignTokens.errorTextColor,
                          fontSize: DesignTokens.bodyFontSize,
                        ),
                      ),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        Text(loc.rememberMe),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _signIn(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primaryColor,
                          foregroundColor: DesignTokens.foregroundColor,
                          padding: DesignTokens.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius),
                          ),
                          elevation: DesignTokens.buttonElevation,
                          textStyle: TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            fontWeight: DesignTokens.titleFontWeight,
                            fontFamily: DesignTokens.fontFamily,
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: DesignTokens.foregroundColor)
                            : Text(
                                loc.signIn,
                                style: TextStyle(
                                  color: DesignTokens.foregroundColor,
                                  fontSize: DesignTokens.bodyFontSize,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.termsAndPrivacyPolicy,
                      style: TextStyle(
                        color: DesignTokens.secondaryTextColor,
                        fontSize: DesignTokens.captionFontSize,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
