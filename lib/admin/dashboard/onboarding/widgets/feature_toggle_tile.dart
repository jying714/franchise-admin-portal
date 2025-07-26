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

  const FeatureToggleTile({
    Key? key,
    required this.moduleKey,
    required this.featureKey,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    debugPrint('[FeatureToggleTile] $moduleKey / $featureKey');

    return Consumer2<FranchiseFeatureProvider, FranchiseInfoProvider>(
      builder: (context, featureProvider, franchiseInfo, _) {
        final isEnabled = (featureKey == null || featureKey == 'enabled')
            ? featureProvider.isModuleEnabled(moduleKey)
            : featureProvider.isSubfeatureEnabled(moduleKey, featureKey!);

        final isLocked = featureProvider.isModuleLocked(moduleKey);
        final franchiseId = franchiseInfo.franchise?.id ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
              const SizedBox(width: 12),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: isEnabled,
                onChanged: isLocked
                    ? null
                    : (newValue) {
                        if (featureKey == null || featureKey == 'enabled') {
                          featureProvider.setModuleEnabled(moduleKey, newValue);
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
        );
      },
    );
  }
}
