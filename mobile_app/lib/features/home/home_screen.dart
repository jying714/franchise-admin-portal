// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_up_screen.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: shared.UiConfig.backgroundColorDark,
      appBar: FranchiseAppBar(
        title: "",
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.UiConfig.logoMain,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: shared.UiConfig.defaultPadding,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.cardRadius),
              ),
              elevation: shared.DesignTokens.cardElevation,
              color: shared.UiConfig.surfaceColorDark,
              child: Padding(
                padding: shared.UiConfig.defaultPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      shared.UiConfig.logoLarge,
                      height: shared.DesignTokens.logoHeightLarge,
                      errorBuilder: (c, e, s) => Image.asset(
                        shared.UiConfig.defaultPizzaIcon,
                        height: shared.DesignTokens.logoHeightLarge,
                        fit: BoxFit.contain,
                        semanticLabel: loc.logoErrorTooltip,
                      ),
                    ),
                    SizedBox(height: shared.DesignTokens.gridSpacing * 4),
                    Text(
                      loc.welcomeTitle(shared.BrandingConfig.franchiseName),
                      style: TextStyle(
                        fontFamily: shared.DesignTokens.fontFamily,
                        fontWeight: shared.UiConfig.fontWeightBold,
                        fontSize: shared.DesignTokens.titleFontSize,
                        color: shared.UiConfig.textColorDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: shared.DesignTokens.gridSpacing * 2),
                    Text(
                      loc.welcomeSubtitle,
                      style: TextStyle(
                        fontFamily: shared.DesignTokens.fontFamily,
                        fontSize: shared.DesignTokens.bodyFontSize,
                        color: shared.UiConfig.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: shared.DesignTokens.gridSpacing * 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignInScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: shared.UiConfig.primaryColor,
                          foregroundColor: shared.UiConfig.foregroundColorDark,
                          padding: shared.UiConfig.defaultPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                shared.DesignTokens.buttonRadius),
                          ),
                          elevation: shared.DesignTokens.buttonElevation,
                          textStyle: TextStyle(
                            fontSize: shared.DesignTokens.bodyFontSize,
                            fontWeight: shared.UiConfig.fontWeightBold,
                            fontFamily: shared.DesignTokens.fontFamily,
                          ),
                        ),
                        child: Text(loc.signInButton),
                      ),
                    ),
                    SizedBox(height: shared.DesignTokens.gridSpacing * 1.75),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: shared.UiConfig.secondaryColor,
                          foregroundColor: shared.UiConfig.textColorDark,
                          padding: shared.UiConfig.defaultPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                shared.DesignTokens.buttonRadius),
                          ),
                          elevation: shared.DesignTokens.buttonElevation,
                          textStyle: TextStyle(
                            fontSize: shared.DesignTokens.bodyFontSize,
                            fontWeight: shared.UiConfig.fontWeightBold,
                            fontFamily: shared.DesignTokens.fontFamily,
                          ),
                        ),
                        child: Text(loc.signUpNowButton),
                      ),
                    ),
                    SizedBox(height: shared.DesignTokens.gridSpacing * 1.75),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainMenuScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: shared.UiConfig.primaryColor,
                        padding: EdgeInsets.symmetric(
                            vertical: shared.DesignTokens.gridSpacing * 1.5),
                        textStyle: TextStyle(
                          fontFamily: shared.DesignTokens.fontFamily,
                          fontSize: shared.DesignTokens.bodyFontSize,
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
