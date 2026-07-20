import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:shared_core/shared_core.dart' show BrandingConfig;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

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
      return shared.UiConfig.successColor;
    } else if (pw.length >= 8) {
      return shared
          .UiConfig.warningColor; // add this getter to UiConfig if missing
    } else if (pw.isNotEmpty) {
      return shared.UiConfig.errorColor;
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

  Future<void> _ensureUserProfile(shared.User user,
      {String? displayName}) async {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final existing = await firestoreService.getUser(user.id);
    if (existing == null) {
      final newUser = shared.User(
        id: user.id,
        name: displayName ?? user.name ?? "",
        email: user.email ?? "",
        phoneNumber: user.phoneNumber,
        roles: [shared.User.roleCustomer],
        addresses: [],
        language: "en",
        status: "active",
      );
      await firestoreService.addUser(newUser);
    }
  }

  Future<void> _handleSocialSuccess(firebase.User? firebaseUser) async {
    if (firebaseUser == null) return;
    setState(() => _loading = true);
    try {
      final sharedUser = shared.User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? "",
        email: firebaseUser.email ?? "",
        phoneNumber: firebaseUser.phoneNumber,
        roles: [shared.User.roleCustomer],
        addresses: [],
        language: "en",
        status: "active",
      );

      await _ensureUserProfile(sharedUser);

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final dbUser = await firestoreService.getUser(sharedUser.id);

      if (!mounted) return;
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
      if (mounted) setState(() => _error = 'Profile error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final loc = AppLocalizations.of(context)!;
    if (!_acceptTerms) {
      setState(() => _error = loc.mustAcceptTerms);
      return;
    }

    final authService = Provider.of<shared.AuthService>(context, listen: false);
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

    final user = await authService.createUserWithEmailAndPassword(
        email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      try {
        await authService.sendEmailVerification();
        await _ensureUserProfile(user, displayName: name);

        final firestoreService =
            Provider.of<shared.FirestoreService>(context, listen: false);
        final dbUser = await firestoreService.getUser(user.id);

        if (!mounted) return;

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
        setState(() => _error = loc.signUpProfileFailed);
      }
    } else {
      setState(() => _error = loc.signUpFailed);
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
      backgroundColor: shared.UiConfig.backgroundColorDark,
      appBar: FranchiseAppBar(
        title: loc.signUp,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius)),
            color: shared.UiConfig.surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(shared.UiConfig.logoMain, height: 120),
                    const SizedBox(height: 32),
                    SocialSignInButtons(
                      onSuccess: _handleSocialSuccessWrapper,
                      onError: (String err) => setState(() => _error = err),
                      isLoading: _loading,
                      setLoading: (bool loading) =>
                          setState(() => _loading = loading),
                      showPhone: true,
                    ),
                    const Divider(height: 36, thickness: 1),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.name,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.formFieldRadius)),
                        prefixIcon: Icon(shared.UiConfig.emailIcon), // optional
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? loc.enterName : null,
                      style: TextStyle(color: shared.UiConfig.textColorDark),
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
                                DesignTokens.formFieldRadius)),
                        prefixIcon: Icon(shared.UiConfig.emailIcon),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : loc.validEmailRequired,
                      style: TextStyle(color: shared.UiConfig.textColorDark),
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
                                DesignTokens.formFieldRadius)),
                        prefixIcon: Icon(shared.UiConfig.lockIcon),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword
                              ? shared.UiConfig.visibilityOffIcon
                              : shared.UiConfig.visibilityIcon),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? loc.passwordTooShort
                          : null,
                      style: TextStyle(color: shared.UiConfig.textColorDark),
                      onChanged: (v) => setState(() {}),
                    ),
                    if (_passwordStrengthLabel(context).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${loc.passwordStrength}: ${_passwordStrengthLabel(context)}',
                          style: TextStyle(
                              color: _passwordStrengthColor(context),
                              fontSize: 12),
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
                                DesignTokens.formFieldRadius)),
                        prefixIcon: Icon(shared.UiConfig.lockIcon),
                        suffixIcon: IconButton(
                          icon: Icon(_showConfirmPassword
                              ? shared.UiConfig.visibilityOffIcon
                              : shared.UiConfig.visibilityIcon),
                          onPressed: () => setState(() =>
                              _showConfirmPassword = !_showConfirmPassword),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value != _passwordController.text
                              ? loc.passwordsDoNotMatch
                              : null,
                      style: TextStyle(color: shared.UiConfig.textColorDark),
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
                            onTap: () => _launchURL(BrandingConfig
                                .termsOfServiceUrl), // or UiConfig if you prefer
                            child: Text(loc.termsOfService,
                                style: TextStyle(
                                    color: shared.UiConfig.primaryColor,
                                    decoration: TextDecoration.underline)),
                          ),
                          Text(' ${loc.and} '),
                          GestureDetector(
                            onTap: () =>
                                _launchURL(BrandingConfig.privacyPolicyUrl),
                            child: Text(loc.privacyPolicy,
                                style: TextStyle(
                                    color: shared.UiConfig.primaryColor,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!,
                          style: TextStyle(color: shared.UiConfig.errorColor)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _signUp();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: shared.UiConfig.primaryColor,
                          foregroundColor: shared.UiConfig.foregroundColorDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.buttonRadius)),
                        ),
                        child: _loading
                            ? CircularProgressIndicator(
                                color: shared.UiConfig.onPrimaryColor)
                            : Text(loc.createAccount),
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

  void _handleSocialSuccessWrapper(shared.User? user) {
    if (user == null) return;
    _handleSocialSuccessFromShared(user);
  }

  Future<void> _handleSocialSuccessFromShared(shared.User user) async {
    setState(() => _loading = true);
    try {
      await _ensureUserProfile(user);

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final dbUser = await firestoreService.getUser(user.id);

      if (!mounted) return;
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
      if (mounted) setState(() => _error = 'Profile error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
