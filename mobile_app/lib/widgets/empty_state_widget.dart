import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

/// Reusable empty state widget with support for image, icon, retry button, and admin branding.
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
            ? shared.BrandingConfig.adminEmptyStateImage
            : shared.BrandingConfig.bannerPlaceholder);

    return Center(
      child: Padding(
        padding: UiConfig.defaultPadding
            .add(const EdgeInsets.symmetric(vertical: 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null)
              Icon(iconData, size: 80, color: UiConfig.primaryColor)
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
              style: UiConfig.titleStyle.copyWith(
                color: UiConfig.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message!,
                  style: UiConfig.bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UiConfig.secondaryColor,
                    foregroundColor: UiConfig.foregroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          shared.DesignTokens.buttonRadius),
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
