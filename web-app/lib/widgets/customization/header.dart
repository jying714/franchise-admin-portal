import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/models/menu_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class CustomizationHeader extends StatelessWidget {
  final MenuItem menuItem;
  final ThemeData theme;
  final AppLocalizations loc;

  const CustomizationHeader({
    Key? key,
    required this.menuItem,
    required this.theme,
    required this.loc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (menuItem.image != null && menuItem.image!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: Image.network(
              menuItem.image!,
              width: DesignTokens.menuItemImageWidth,
              height: DesignTokens.menuItemImageHeight,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                BrandingConfig.defaultPizzaIcon,
                width: DesignTokens.menuItemImageWidth,
                height: DesignTokens.menuItemImageHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
        SizedBox(width: DesignTokens.gridSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                menuItem.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: DesignTokens.textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.gridSpacing / 2),
              Text(
                menuItem.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.secondaryTextColor,
                  fontFamily: DesignTokens.fontFamily,
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


