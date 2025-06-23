// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final String? imageAsset;
  final IconData? iconData;
  final VoidCallback? onRetry;
  final String? buttonText;
  final bool isAdmin;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.imageAsset,
    this.iconData,
    this.onRetry,
    this.buttonText,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = imageAsset ??
        (isAdmin
            ? BrandingConfig.adminEmptyStateImage
            : BrandingConfig.bannerPlaceholder);

    return Center(
      child: Padding(
        padding: DesignTokens.gridPadding
            .add(const EdgeInsets.symmetric(vertical: 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null)
              Icon(iconData, size: 80, color: DesignTokens.primaryColor)
            else if (img != null && img.isNotEmpty)
              Image.asset(
                img,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.titleFontSize,
                fontWeight: DesignTokens.titleFontWeight,
                color: DesignTokens.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message!,
                  style: TextStyle(
                    fontSize: DesignTokens.bodyFontSize,
                    color: DesignTokens.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.secondaryColor,
                    foregroundColor: DesignTokens.foregroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(buttonText ?? (isAdmin ? 'Reload' : 'Try Again')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
