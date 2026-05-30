import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomizationHeader extends StatelessWidget {
  final shared.MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;

  const CustomizationHeader({
    super.key,
    required this.menuItem,
    required this.theme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected (P1 Batch 1) for franchise/{franchiseId}/ scoping centrality
    Provider.of<shared.FranchiseProvider>(context, listen: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (menuItem.image != null && menuItem.image!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
            child: Image.network(
              menuItem.image!,
              width: shared.DesignTokens.menuItemImageWidth,
              height: shared.DesignTokens.menuItemImageHeight,
              fit: BoxFit.cover,
            ),
          ),
        SizedBox(width: shared.DesignTokens.gridSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                menuItem.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: UiConfig.textColor,
                  fontWeight: UiConfig.bold,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: shared.DesignTokens.gridSpacing / 2),
              Text(
                menuItem.description ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: UiConfig.secondaryTextColor,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }
}
