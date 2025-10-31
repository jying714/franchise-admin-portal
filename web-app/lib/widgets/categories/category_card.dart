import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:shared_core/src/core/models/category.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef CategoryTapCallback = void Function(Category category);

class CategoryCard extends StatelessWidget {
  final Category category;
  final CategoryTapCallback? onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    this.onTap,
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
                color: DesignTokens.primaryColor,
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
                          errorBuilder: (_, __, ___) => Positioned.fill(
                            child: Image.asset(
                              BrandingConfig.defaultCategoryIcon,
                              fit: BoxFit.cover,
                            ),
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
                          style: const TextStyle(
                            fontSize: DesignTokens.titleFontSize,
                            fontWeight: DesignTokens.titleFontWeight,
                            color: Colors.white,
                            fontFamily: DesignTokens.fontFamily,
                            shadows: [
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
                              style: const TextStyle(
                                fontSize: DesignTokens.captionFontSize,
                                color: Colors.white70,
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: DesignTokens.bodyFontWeight,
                                shadows: [
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


