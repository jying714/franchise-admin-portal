// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:doughboys_pizzeria_final/config/app_config.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:doughboys_pizzeria_final/features/auth/sign_in_screen.dart';
import 'package:doughboys_pizzeria_final/features/auth/sign_up_screen.dart';
import 'package:doughboys_pizzeria_final/features/main_menu/main_menu_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        title: Image.asset(
          BrandingConfig.logoMain,
          height: DesignTokens.logoHeightSmall,
          errorBuilder: (c, e, s) => Image.asset(
            BrandingConfig.fallbackAppIcon,
            height: DesignTokens.logoHeightSmall,
            fit: BoxFit.contain,
            semanticLabel: loc.logoErrorTooltip,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColorDark),
      ),
      body: SafeArea(
        child: Center(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      BrandingConfig.logoLarge,
                      height: DesignTokens.logoHeightLarge,
                      errorBuilder: (c, e, s) => Image.asset(
                        BrandingConfig.fallbackAppIcon,
                        height: DesignTokens.logoHeightLarge,
                        fit: BoxFit.contain,
                        semanticLabel: loc.logoErrorTooltip,
                      ),
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 4),
                    Text(
                      loc.welcomeTitle(BrandingConfig.franchiseName),
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.titleFontWeight,
                        fontSize: DesignTokens.titleFontSize,
                        color: DesignTokens.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 2),
                    Text(
                      loc.welcomeSubtitle,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.bodyFontSize,
                        color: DesignTokens.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignInScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primaryColor,
                          foregroundColor: DesignTokens.foregroundColorDark,
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
                        child: Text(loc.signInButton),
                      ),
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 1.75),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.secondaryColor,
                          foregroundColor: DesignTokens.textColor,
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
                        child: Text(loc.signUpNowButton),
                      ),
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 1.75),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainMenuScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: DesignTokens.primaryColor,
                        padding: EdgeInsets.symmetric(
                            vertical: DesignTokens.gridSpacing * 1.5),
                        textStyle: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.bodyFontSize,
                        ),
                      ),
                      child: Text(loc.continueAsGuestButton),
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
