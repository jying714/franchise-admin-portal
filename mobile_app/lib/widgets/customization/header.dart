import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

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
                  color: theme.colorScheme.onSurface,
                  fontWeight: shared.UiConfig.bold,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: shared.DesignTokens.gridSpacing / 2),
              Text(
                menuItem.description ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
