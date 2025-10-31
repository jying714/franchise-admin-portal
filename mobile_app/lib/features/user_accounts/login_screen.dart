import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:shared_core/src/core/services/auth_service.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
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

  Future<void> _handleEmailAuth(AuthService auth) async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final user = isLoginMode
          ? await auth.signInWithEmail(
              emailController.text.trim(),
              passwordController.text.trim(),
            )
          : await auth.registerWithEmail(
              emailController.text.trim(),
              passwordController.text.trim(),
              nameController.text.trim(),
              phoneController.text.trim(),
            );
      if (!mounted) return;
      if (user == null) {
        setState(() {
          error = isLoginMode
              ? "Invalid email or password."
              : "Registration failed. Please try again.";
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleGuest(AuthService auth) async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await auth.setGuestSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleDemo(AuthService auth) async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await auth.setDemoSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final featureConfig = FeatureConfig.instance;
    final enableGuest = featureConfig.enableGuestMode;
    final enableDemo = featureConfig.enableDemoMode && !enableGuest;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.gridSpacing * 3),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.dialogRadius),
            ),
            elevation: DesignTokens.cardElevation,
            color: DesignTokens.surfaceColor,
            child: Padding(
              padding: DesignTokens.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    BrandingConfig.logoMain,
                    height: DesignTokens.logoHeightLarge,
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  Text(
                    isLoginMode ? 'Sign In' : 'Register',
                    style: const TextStyle(
                      fontSize: DesignTokens.titleFontSize,
                      fontWeight: DesignTokens.titleFontWeight,
                      fontFamily: DesignTokens.fontFamily,
                      color: DesignTokens.primaryColor,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  TextField(
                    controller: emailController,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      color: DesignTokens.textColor,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  TextField(
                    controller: passwordController,
                    enabled: !loading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      color: DesignTokens.textColor,
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
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.textColor,
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
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.textColor,
                      ),
                    ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.gridSpacing),
                    Text(
                      error,
                      style: const TextStyle(
                        color: DesignTokens.errorColor,
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.bodyFontWeight,
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
                      foregroundColor: DesignTokens.foregroundColor,
                      padding: DesignTokens.buttonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                    ),
                    onPressed: loading ? null : () => _handleEmailAuth(auth),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isLoginMode ? 'Sign In' : 'Register',
                            style: const TextStyle(
                              fontSize: DesignTokens.bodyFontSize,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.bodyFontWeight,
                              color: DesignTokens.foregroundColor,
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
                        style: const TextStyle(
                          fontSize: DesignTokens.bodyFontSize,
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.bodyFontWeight,
                          color: DesignTokens.textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: loading ? null : _toggleMode,
                        child: Text(
                          isLoginMode ? 'Register' : 'Sign In',
                          style: const TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.bodyFontWeight,
                            color: DesignTokens.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: DesignTokens.gridSpacing * 4,
                    thickness: 1,
                  ),
                  SocialSignInButtons(
                    onSuccess: (user) {
                      if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainMenuScreen()),
                        );
                      }
                    },
                    onError: (err) {
                      setState(() => error = err);
                    },
                    isLoading: loading,
                    setLoading: (val) => setState(() => loading = val),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  if (enableGuest)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_outline),
                      label: const Text("Continue as Guest"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.primaryColor,
                        side:
                            const BorderSide(color: DesignTokens.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                        textStyle: const TextStyle(
                          fontSize: DesignTokens.bodyFontSize,
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.bodyFontWeight,
                        ),
                      ),
                      onPressed: loading ? null : () => _handleGuest(auth),
                    ),
                  if (enableDemo)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text("Try Demo Mode"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.secondaryColor,
                        side: const BorderSide(
                            color: DesignTokens.secondaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                        textStyle: const TextStyle(
                          fontSize: DesignTokens.bodyFontSize,
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.bodyFontWeight,
                        ),
                      ),
                      onPressed: loading ? null : () => _handleDemo(auth),
                    ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  Text(
                    FeatureConfig.instance.forceLogin ? '' : '',
                    style: const TextStyle(
                      color: DesignTokens.disabledTextColor,
                      fontSize: DesignTokens.captionFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.bodyFontWeight,
                    ),
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
