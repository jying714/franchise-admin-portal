import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/widgets/social_sign_in_buttons.dart';
import 'package:franchise_mobile_app/config/feature_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginMode = true;
  bool loading = false;
  String error = '';

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      error = '';
    });
  }

  Future<void> _handleEmailAuth(shared.AuthService auth) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final user = isLoginMode
          ? await auth.signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            )
          : await auth.createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

      if (!mounted) return;

      // For registration, update display name
      if (!isLoginMode) {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          await auth.updateUserProfile(displayName: name);
        }
      }

      if (user == null) {
        setState(() {
          error = isLoginMode
              ? "Invalid email or password."
              : "Registration failed. Please try again.";
        });
        return;
      }

      await _handleAuthSuccess(user);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleAuthSuccess(shared.User user) async {
    setState(() => loading = true);
    try {
      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final dbUser = await firestoreService.getUser(user.id);

      if (!mounted) return;

      // Clean initialization with new FranchiseProvider
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
      if (mounted) setState(() => error = 'Profile initialization error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleGuest(shared.AuthService auth) async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await auth.setGuestSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleDemo(shared.AuthService auth) async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await auth.setDemoSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<shared.AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: shared.UiConfig.backgroundColorDark,
      body: Center(
        child: SingleChildScrollView(
          padding: shared.UiConfig.defaultScreenPadding,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            elevation: DesignTokens.cardElevation,
            color: shared.UiConfig.surfaceColor,
            child: Padding(
              padding: shared.UiConfig.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    shared.UiConfig.logoMain,
                    height: DesignTokens.logoHeightLarge,
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  Text(
                    isLoginMode ? 'Sign In' : 'Register',
                    style: TextStyle(
                      fontSize: DesignTokens.titleFontSize,
                      fontWeight: shared.UiConfig.fontWeightBold,
                      fontFamily: DesignTokens.fontFamily,
                      color: shared.UiConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  TextField(
                    controller: emailController,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(shared.UiConfig.emailIcon),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      color: shared.UiConfig.textColorDark,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  TextField(
                    controller: passwordController,
                    enabled: !loading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(shared.UiConfig.lockIcon),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      color: shared.UiConfig.textColorDark,
                    ),
                  ),
                  if (!isLoginMode) ...[
                    const SizedBox(height: DesignTokens.gridSpacing),
                    TextField(
                      controller: nameController,
                      enabled: !loading,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        color: shared.UiConfig.textColorDark,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.gridSpacing),
                    TextField(
                      controller: phoneController,
                      enabled: !loading,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        color: shared.UiConfig.textColorDark,
                      ),
                    ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.gridSpacing),
                    Text(
                      error,
                      style: TextStyle(
                        color: shared.UiConfig.errorColor,
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shared.UiConfig.primaryColor,
                      foregroundColor: shared.UiConfig.foregroundColorDark,
                      padding: shared.UiConfig.defaultPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                    ),
                    onPressed: loading ? null : () => _handleEmailAuth(auth),
                    child: loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: shared.UiConfig.onPrimaryColor),
                          )
                        : Text(
                            isLoginMode ? 'Sign In' : 'Register',
                            style: TextStyle(
                              fontSize: DesignTokens.bodyFontSize,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: shared.UiConfig.fontWeightBold,
                              color: shared.UiConfig.foregroundColorDark,
                            ),
                          ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLoginMode
                            ? "Don't have an account?"
                            : "Already have an account?",
                        style: TextStyle(
                          fontSize: DesignTokens.bodyFontSize,
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: shared.UiConfig.fontWeightNormal,
                          color: shared.UiConfig.textColorDark,
                        ),
                      ),
                      TextButton(
                        onPressed: loading ? null : _toggleMode,
                        child: Text(
                          isLoginMode ? 'Register' : 'Sign In',
                          style: TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: shared.UiConfig.fontWeightBold,
                            color: shared.UiConfig.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                      height: DesignTokens.gridSpacing * 4, thickness: 1),
                  SocialSignInButtons(
                    onSuccess: (user) {
                      if (user != null) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const MainMenuScreen()),
                          (route) => false,
                        );
                      }
                    },
                    onError: (err) => setState(() => error = err),
                    isLoading: loading,
                    setLoading: (val) => setState(() => loading = val),
                    showPhone: true,
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline),
                    label: const Text("Continue as Guest"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: shared.UiConfig.primaryColor,
                      side: BorderSide(color: shared.UiConfig.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius)),
                    ),
                    onPressed: loading ? null : () => _handleGuest(auth),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text("Try Demo Mode"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: shared.UiConfig.secondaryColor,
                      side: BorderSide(color: shared.UiConfig.secondaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius)),
                    ),
                    onPressed: loading ? null : () => _handleDemo(auth),
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
