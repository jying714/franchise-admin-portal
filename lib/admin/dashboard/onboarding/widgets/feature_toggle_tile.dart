// File: lib/admin/dashboard/onboarding/widgets/feature_toggle_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class FeatureToggleTile extends StatelessWidget {
  final String moduleKey;
  final String? featureKey;
  final String title;
  final String description;
  final bool
      highlight; // <-- new, to visually focus when navigating for error repair

  const FeatureToggleTile({
    Key? key,
    required this.moduleKey,
    required this.featureKey,
    required this.title,
    required this.description,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // For animated highlight, this can later be changed to an AnimatedContainer if desired.
    return Consumer2<FranchiseFeatureProvider, FranchiseInfoProvider>(
      builder: (context, featureProvider, franchiseInfo, _) {
        final isEnabled = (featureKey == null || featureKey == 'enabled')
            ? featureProvider.isModuleEnabled(moduleKey)
            : featureProvider.isSubfeatureEnabled(moduleKey, featureKey!);

        final isLocked = featureProvider.isModuleLocked(moduleKey);
        final franchiseId = franchiseInfo.franchise?.id ?? '';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            border: highlight
                ? Border.all(
                    color: theme.colorScheme.secondary,
                    width: 2.6,
                  )
                : Border.all(
                    color: theme.dividerColor.withOpacity(0.22),
                    width: 1.0,
                  ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withOpacity(0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
            color: theme.colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
            child: Row(
              children: [
                Icon(
                  isLocked ? Icons.lock_outline : Icons.toggle_on_outlined,
                  color: isLocked
                      ? theme.disabledColor
                      : (isEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isLocked
                              ? theme.disabledColor
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.74),
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Switch(
                  value: isEnabled,
                  onChanged: isLocked
                      ? null
                      : (newValue) {
                          if (featureKey == null || featureKey == 'enabled') {
                            featureProvider.setModuleEnabled(
                                moduleKey, newValue);
                          } else {
                            featureProvider.toggleSubfeature(
                              moduleKey,
                              featureKey!,
                              newValue,
                            );
                          }
                        },
                  activeColor: theme.colorScheme.primary,
                  inactiveThumbColor: theme.colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
