import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/widgets/social_sign_in_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureUserProfile(shared.User user) async {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final existing = await firestoreService.getUser(user.id);
    if (existing == null) {
      final newUser = shared.User(
        id: user.id,
        name: user.name ?? "",
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

  // Synchronous wrapper required by SocialSignInButtons
  // Synchronous wrapper required by SocialSignInButtons
  void _handleSocialSuccess(shared.User? user) {
    // ← Changed parameter type to shared.User?
    if (user == null) return;
    _handleSocialSuccessAsync(user);
  }

  // Actual async logic
  Future<void> _handleSocialSuccessAsync(shared.User user) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      await _ensureUserProfile(user);

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final dbUser = await firestoreService.getUser(user.id);

      if (!mounted) return;

      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);
      await franchiseProvider.initializeWithUser(dbUser ?? user);

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
      if (mounted) setState(() => _error = 'Profile initialization error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<shared.AuthService>(context, listen: false);
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final user = await authService.signInWithEmailAndPassword(
        email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      await _handleAuthSuccess(user);
    } else {
      setState(() => _error = 'Sign in failed');
    }
  }

  Future<void> _handleAuthSuccess(shared.User user) async {
    setState(() => _loading = true);
    try {
      await _ensureUserProfile(user);

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final dbUser = await firestoreService.getUser(user.id);

      if (!mounted) return;

      // Initialize FranchiseProvider cleanly
      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);
      await franchiseProvider.initializeWithUser(dbUser ?? user);

      // Optional: Load full franchise details for branding
      if (franchiseProvider.hasValidFranchise) {
        // await franchiseProvider.loadCurrentFranchiseDetails(firestoreService); // Uncomment if you re-add this method
      }

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
      if (mounted) setState(() => _error = 'Profile initialization error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Valid email required');
      return;
    }
    try {
      await authService.sendPasswordResetEmail(email);
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.passwordResetSent)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Reset failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: UiConfig.backgroundColorDark,
      appBar: AppBar(
        title: Text(
          loc.signIn,
          style: TextStyle(
            color: UiConfig.foregroundColorDark,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        centerTitle: true,
        backgroundColor: UiConfig.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius)),
            color: UiConfig.surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(UiConfig.logoMain, height: 120),
                    const SizedBox(height: 32),
                    SocialSignInButtons(
                      onSuccess: _handleSocialSuccess, // Keep as-is
                      onError: (String err) => setState(() => _error = err),
                      isLoading: _loading,
                      setLoading: (bool loading) =>
                          setState(() => _loading = loading),
                      showPhone: true,
                    ),
                    const Divider(height: 36, thickness: 1),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: loc.email,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.formFieldRadius)),
                        prefixIcon: Icon(UiConfig.emailIcon),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : loc.validEmailRequired,
                      style: TextStyle(color: UiConfig.textColorDark),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: loc.password,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.formFieldRadius)),
                        prefixIcon: Icon(UiConfig.lockIcon),
                        suffixIcon: IconButton(
                          icon: Icon(_passwordVisible
                              ? UiConfig.visibilityOffIcon
                              : UiConfig.visibilityIcon),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (value) => value != null && value.length >= 6
                          ? null
                          : loc.passwordTooShort,
                      style: TextStyle(color: UiConfig.textColorDark),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: Text(loc.forgotPassword),
                      ),
                    ),
                    if (_error != null)
                      Text(_error!,
                          style: TextStyle(color: UiConfig.errorColor)),
                    Row(
                      children: [
                        Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false)),
                        Text(loc.rememberMe),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ?? false)
                                  _signIn();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UiConfig.primaryColor,
                          foregroundColor: UiConfig.foregroundColorDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.buttonRadius)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(loc.signIn),
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
