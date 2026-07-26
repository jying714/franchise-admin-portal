// File: lib/admin/hq_owner/onboarding/widgets/feature_toggle_tile.dart

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class FeatureToggleTile extends StatelessWidget {
  final String moduleKey;
  final String? featureKey;
  final String title;
  final String description;
  final bool highlight;
  final bool isInDevelopment;

  const FeatureToggleTile({
    Key? key,
    required this.moduleKey,
    required this.featureKey,
    required this.title,
    required this.description,
    this.highlight = false,
    this.isInDevelopment = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Consumer2<shared.FranchiseFeatureProvider,
        shared.FranchiseInfoProvider>(
      builder: (context, featureProvider, franchiseInfo, _) {
        final isEnabled = (featureKey == null || featureKey == 'enabled')
            ? featureProvider.isModuleEnabled(moduleKey)
            : featureProvider.isSubfeatureEnabled(moduleKey, featureKey!);

        final isLocked = featureProvider.isModuleLocked(moduleKey);
        final effectiveLocked = isLocked || isInDevelopment;
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
                  effectiveLocked
                      ? Icons.lock_outline
                      : Icons.toggle_on_outlined,
                  color: effectiveLocked
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
                          color: effectiveLocked
                              ? theme.disabledColor
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isInDevelopment ? 'In development' : description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isInDevelopment
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.74),
                          fontStyle: isInDevelopment
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Switch(
                  value: isEnabled,
                  onChanged: effectiveLocked
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
