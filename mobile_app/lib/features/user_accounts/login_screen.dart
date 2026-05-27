import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
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

      // For registration, update display name (phone is handled in profile)
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

      // Align with stabilized flow: ensure profile + franchise init
      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final franchiseProvider =
          Provider.of<FranchiseProvider>(context, listen: false);

      final dbUser = await firestoreService.getUser(user.id);
      if (!mounted) return;

      final defaultId = dbUser?.defaultFranchise ??
          (dbUser?.franchiseIds.isNotEmpty == true
              ? dbUser!.franchiseIds.first
              : null);

      await franchiseProvider.initializeFromUser(defaultFranchiseId: defaultId);
      if (defaultId != null) {
        await franchiseProvider.loadCurrentFranchiseDetails(firestoreService);
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
      if (mounted) setState(() => error = e.toString());
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
      backgroundColor: UiConfig.backgroundColorDark,
      body: Center(
        child: SingleChildScrollView(
          padding: UiConfig.defaultScreenPadding,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            elevation: DesignTokens.cardElevation,
            color: UiConfig.surfaceColor,
            child: Padding(
              padding: UiConfig.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    UiConfig.logoMain,
                    height: DesignTokens.logoHeightLarge,
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  Text(
                    isLoginMode ? 'Sign In' : 'Register',
                    style: TextStyle(
                      fontSize: DesignTokens.titleFontSize,
                      fontWeight: UiConfig.fontWeightBold,
                      fontFamily: DesignTokens.fontFamily,
                      color: UiConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  TextField(
                    controller: emailController,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(UiConfig.emailIcon),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      color: UiConfig.textColorDark,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  TextField(
                    controller: passwordController,
                    enabled: !loading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(UiConfig.lockIcon),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.formFieldRadius),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      color: UiConfig.textColorDark,
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
                        color: UiConfig.textColorDark,
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
                        color: UiConfig.textColorDark,
                      ),
                    ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.gridSpacing),
                    Text(
                      error,
                      style: TextStyle(
                        color: UiConfig.errorColor,
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.gridSpacing * 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UiConfig.primaryColor,
                      foregroundColor: UiConfig.foregroundColorDark,
                      padding: UiConfig.defaultPadding,
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
                            style: TextStyle(
                              fontSize: DesignTokens.bodyFontSize,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: UiConfig.fontWeightBold,
                              color: UiConfig.foregroundColorDark,
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
                          fontWeight: UiConfig.fontWeightNormal,
                          color: UiConfig.textColorDark,
                        ),
                      ),
                      TextButton(
                        onPressed: loading ? null : _toggleMode,
                        child: Text(
                          isLoginMode ? 'Register' : 'Sign In',
                          style: TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: UiConfig.fontWeightBold,
                            color: UiConfig.accentColor,
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
                  // Guest & Demo always available (FeatureConfig flags removed in current config)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline),
                    label: const Text("Continue as Guest"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UiConfig.primaryColor,
                      side: BorderSide(color: UiConfig.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                      textStyle: TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: UiConfig.fontWeightNormal,
                      ),
                    ),
                    onPressed: loading ? null : () => _handleGuest(auth),
                  ),
                  const SizedBox(height: DesignTokens.gridSpacing),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text("Try Demo Mode"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UiConfig.secondaryColor,
                      side: BorderSide(color: UiConfig.secondaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                      textStyle: TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: UiConfig.fontWeightNormal,
                      ),
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
