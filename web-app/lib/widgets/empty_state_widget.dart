import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    final img = imageAsset ??
        (isAdmin
            ? BrandingConfig.adminEmptyStateImage
            : BrandingConfig.bannerPlaceholder);

    return Semantics(
      label: title,
      header: true,
      child: Center(
        child: Padding(
          padding: DesignTokens.gridPadding
              .add(const EdgeInsets.symmetric(vertical: 32)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconData != null)
                Icon(
                  iconData,
                  size: 80,
                  color: colorScheme.primary,
                )
              else if (img != null && img.isNotEmpty)
                Image.asset(
                  img,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  semanticLabel: title,
                )
              else
                Icon(
                  Icons.info_outline,
                  size: 80,
                  color: colorScheme.primary,
                ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: DesignTokens.titleFontSize,
                  fontWeight: DesignTokens.titleFontWeight,
                  color: colorScheme.primary,
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
                      color: colorScheme.onSurface.withOpacity(0.7),
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
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      buttonText ?? (isAdmin ? loc.reload : loc.tryAgain),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


