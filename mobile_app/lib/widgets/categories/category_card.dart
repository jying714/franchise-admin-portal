import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:shared_core/src/core/config/design_tokens.dart';
import 'package:shared_core/src/core/config/branding_config.dart';

typedef CategoryTapCallback = void Function(shared.Category category);

class CategoryCard extends StatelessWidget {
  final shared.Category category;
  final CategoryTapCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final String imagePath =
        (category.image != null && category.image!.isNotEmpty)
            ? category.image!
            : BrandingConfig.defaultCategoryIcon;

    return Semantics(
      label: loc.menuCategoryLabel(category.name),
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        elevation: DesignTokens.cardElevation,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          onTap: () => onTap?.call(category),
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(
                color: UiConfig.primaryColor,
                width: DesignTokens.categoryCardBorderWidth,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              color: Colors.transparent,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background image fills the card.
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  child: imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            BrandingConfig.defaultCategoryIcon,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                // Overlay gradient for text readability.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.cardRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Text (name & optional description) at the bottom.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: DesignTokens.titleFontSize,
                            fontWeight: UiConfig.fontWeightBold,
                            color: Colors.white,
                            fontFamily: DesignTokens.fontFamily,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.description != null &&
                            category.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              category.description!,
                              style: TextStyle(
                                fontSize: DesignTokens.captionFontSize,
                                color: Colors.white70,
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: UiConfig.fontWeightNormal,
                                shadows: const [
                                  Shadow(color: Colors.black26, blurRadius: 2),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
