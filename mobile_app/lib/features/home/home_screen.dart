// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/src/core/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_up_screen.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: UiConfig.backgroundColorDark,
      appBar: AppBar(
        title: Image.asset(
          UiConfig.logoMain,
          height: DesignTokens.logoHeightSmall,
          errorBuilder: (c, e, s) => Image.asset(
            UiConfig.defaultPizzaIcon,
            height: DesignTokens.logoHeightSmall,
            fit: BoxFit.contain,
            semanticLabel: loc.logoErrorTooltip,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: UiConfig.defaultPadding,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              elevation: DesignTokens.cardElevation,
              color: UiConfig.surfaceColorDark,
              child: Padding(
                padding: UiConfig.defaultPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      UiConfig.logoLarge,
                      height: DesignTokens.logoHeightLarge,
                      errorBuilder: (c, e, s) => Image.asset(
                        UiConfig.defaultPizzaIcon,
                        height: DesignTokens.logoHeightLarge,
                        fit: BoxFit.contain,
                        semanticLabel: loc.logoErrorTooltip,
                      ),
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 4),
                    Text(
                      loc.welcomeTitle(shared.BrandingConfig.franchiseName),
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: UiConfig.fontWeightBold,
                        fontSize: DesignTokens.titleFontSize,
                        color: UiConfig.textColorDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DesignTokens.gridSpacing * 2),
                    Text(
                      loc.welcomeSubtitle,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.bodyFontSize,
                        color: UiConfig.secondaryTextColor,
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
                          backgroundColor: UiConfig.primaryColor,
                          foregroundColor: UiConfig.foregroundColorDark,
                          padding: UiConfig.defaultPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius),
                          ),
                          elevation: DesignTokens.buttonElevation,
                          textStyle: TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            fontWeight: UiConfig.fontWeightBold,
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
                          backgroundColor: UiConfig.secondaryColor,
                          foregroundColor: UiConfig.textColorDark,
                          padding: UiConfig.defaultPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius),
                          ),
                          elevation: DesignTokens.buttonElevation,
                          textStyle: TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            fontWeight: UiConfig.fontWeightBold,
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
                        foregroundColor: UiConfig.primaryColor,
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
