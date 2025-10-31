// ignore_for_file: unused_import, prefer_const_constructors
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_core/src/core/services/auth_service.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as db_user;
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:shared_core/src/core/config/app_config.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:franchise_mobile_app/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;

  String _passwordStrengthLabel(BuildContext context) {
    final pw = _passwordController.text;
    final loc = AppLocalizations.of(context)!;
    if (pw.length >= 12 &&
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_])').hasMatch(pw)) {
      return loc.strong;
    } else if (pw.length >= 8) {
      return loc.medium;
    } else if (pw.isNotEmpty) {
      return loc.weak;
    } else {
      return '';
    }
  }

  Color _passwordStrengthColor(BuildContext context) {
    final pw = _passwordController.text;
    if (pw.length >= 12 &&
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_])').hasMatch(pw)) {
      return DesignTokens.successColor;
    } else if (pw.length >= 8) {
      return DesignTokens.warningColor;
    } else if (pw.isNotEmpty) {
      return DesignTokens.errorColor;
    } else {
      return Colors.transparent;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Ensures a Firestore user profile exists for this Firebase [user].
  /// If not present, creates it with the default safe fields (role: 'customer').
  Future<void> _ensureUserProfile(User user, {String? displayName}) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final existing = await firestoreService.getUser(user.uid);
    if (existing == null) {
      final newUser = db_user.User(
        id: user.uid,
        name: displayName ?? user.displayName ?? "",
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

  Future<void> _signUp(BuildContext ctx) async {
    final loc = AppLocalizations.of(context)!;
    if (!_acceptTerms) {
      setState(() {
        _error = loc.mustAcceptTerms;
      });
      return;
    }

    final authService = Provider.of<AuthService>(ctx, listen: false);

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (password != confirmPassword) {
      setState(() {
        _loading = false;
        _error = loc.passwordsDoNotMatch;
      });
      return;
    }

    final firebaseUser =
        await authService.registerWithEmail(email, password, name, '');

    if (!mounted) return;
    setState(() => _loading = false);

    if (firebaseUser != null) {
      try {
        await authService.sendEmailVerification();
        await _ensureUserProfile(firebaseUser, displayName: name);

        // Fetch updated user model from Firestore
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        final dbUser = await firestoreService.getUser(firebaseUser.uid);

        if (!mounted) return;
        // Route to ProfileScreen if not completeProfile; else to MainMenuScreen
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
          _error = loc.signUpProfileFailed;
        });
      }
    } else {
      setState(() {
        _error = loc.signUpFailed;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.couldNotLaunchUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.signUp,
          style: const TextStyle(
            color: DesignTokens.foregroundColor,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        centerTitle: true,
        backgroundColor: DesignTokens.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
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
                    // --- Social sign-in buttons (Google/Phone only) ---
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
                              _error = loc.signUpProfileFailed;
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
                      showPhone: true,
                    ),
                    // Removed: Apple sign-in (disabled/placeholder) block
                    const Divider(height: 36, thickness: 1),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.name,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? loc.enterName : null,
                      style: TextStyle(color: DesignTokens.textColor),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: loc.email,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : loc.validEmailRequired,
                      style: TextStyle(color: DesignTokens.textColor),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: loc.password,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? DesignTokens.visibilityOffIcon
                                : DesignTokens.visibilityIcon,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? loc.passwordTooShort
                          : null,
                      style: TextStyle(color: DesignTokens.textColor),
                      onChanged: (v) => setState(() {}),
                    ),
                    if (_passwordStrengthLabel(context).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${loc.passwordStrength}: ${_passwordStrengthLabel(context)}',
                          style: TextStyle(
                            color: _passwordStrengthColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: loc.confirmPassword,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        hintStyle: TextStyle(color: DesignTokens.hintTextColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? DesignTokens.visibilityOffIcon
                                : DesignTokens.visibilityIcon,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value == null || value != _passwordController.text
                              ? loc.passwordsDoNotMatch
                              : null,
                      style: TextStyle(color: DesignTokens.textColor),
                    ),
                    const SizedBox(height: 32),
                    CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (checked) =>
                          setState(() => _acceptTerms = checked ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Wrap(
                        children: [
                          Text('${loc.iAgreeToThe} '),
                          GestureDetector(
                            onTap: () =>
                                _launchURL(BrandingConfig.termsOfServiceUrl),
                            child: Text(
                              loc.termsOfService,
                              style: TextStyle(
                                color: DesignTokens.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(' ${loc.and} '),
                          GestureDetector(
                            onTap: () =>
                                _launchURL(BrandingConfig.privacyPolicyUrl),
                            child: Text(
                              loc.privacyPolicy,
                              style: TextStyle(
                                color: DesignTokens.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: DesignTokens.errorTextColor,
                          fontSize: DesignTokens.bodyFontSize,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _signUp(context);
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
                                loc.createAccount,
                                style: TextStyle(
                                  color: DesignTokens.foregroundColor,
                                  fontSize: DesignTokens.bodyFontSize,
                                ),
                              ),
                      ),
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
