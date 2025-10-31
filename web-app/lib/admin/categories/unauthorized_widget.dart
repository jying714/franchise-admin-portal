import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class UnauthorizedWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onHome;
  final String? actionLabel;

  const UnauthorizedWidget({
    Key? key,
    this.message,
    this.onHome,
    this.actionLabel,
  }) : super(key: key);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          color: colorScheme.surface,
          elevation: DesignTokens.adminCardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: loc.unauthorizedAccess,
                  child: CircleAvatar(
                    backgroundColor: colorScheme.error.withOpacity(0.13),
                    radius: 38,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.error,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  loc.unauthorizedAccessTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message ?? loc.unauthorizedAccessMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white : colorScheme.primary,
                    foregroundColor:
                        isDark ? Colors.black : colorScheme.onPrimary,
                    elevation: DesignTokens.adminButtonElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.adminButtonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                  ),
                  onPressed: onHome,
                  icon: Icon(Icons.home_rounded,
                      color: isDark ? Colors.black : colorScheme.onPrimary),
                  label: Text(
                    actionLabel ?? loc.returnHome,
                    style: TextStyle(
                      color: isDark ? Colors.black : colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  BrandingConfig.bannerPlaceholder,
                  height: 72,
                  fit: BoxFit.contain,
                  semanticLabel: loc.adminDashboardTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


