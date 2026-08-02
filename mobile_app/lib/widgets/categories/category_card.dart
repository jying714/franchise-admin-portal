import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

typedef CategoryTapCallback = void Function(shared.Category category);

class CategoryCard extends StatelessWidget {
  final shared.Category category;
  final CategoryTapCallback? onTap;

  /// When true, render a compact text tile (no image). Used for categories
  /// with empty/missing [Category.image], placed under image cards.
  final bool reduced;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.reduced = false,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    if (reduced) {
      return Semantics(
        label: loc.menuCategoryLabel(category.name),
        button: true,
        child: Material(
          type: MaterialType.transparency,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
            onTap: () => onTap?.call(category),
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(
                  color: scheme.primary,
                  width: shared.DesignTokens.categoryCardBorderWidth,
                ),
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.cardRadius),
                color: scheme.surface,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Center(
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.titleFontSize,
                      fontWeight: shared.UiConfig.fontWeightBold,
                      color: scheme.onSurface,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final String imagePath =
        (category.image != null && category.image!.isNotEmpty)
            ? category.image!
            : shared.BrandingConfig.defaultCategoryIcon;

    return Semantics(
      label: loc.menuCategoryLabel(category.name),
      button: true,
      child: Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          onTap: () => onTap?.call(category),
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(
                color: scheme.primary,
                width: shared.DesignTokens.categoryCardBorderWidth,
              ),
              borderRadius:
                  BorderRadius.circular(shared.DesignTokens.cardRadius),
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: shared.UiConfig.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background image fills the card.
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(shared.DesignTokens.cardRadius),
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: imagePath.startsWith('http')
                        ? Image.network(
                            imagePath,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              shared.BrandingConfig.defaultCategoryIcon,
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
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Colors.transparent,
                              child: Center(
                                child: Icon(Icons.restaurant_menu, size: 40),
                              ),
                            ),
                          ),
                  ),
                ),
                // Overlay gradient for text readability.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(shared.DesignTokens.cardRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          shared.UiConfig.shadowColor.withValues(alpha: 0.55),
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
                            fontSize: shared.DesignTokens.titleFontSize,
                            fontWeight: shared.UiConfig.fontWeightBold,
                            color: scheme.onPrimary,
                            fontFamily: shared.DesignTokens.fontFamily,
                            shadows: [
                              Shadow(
                                  color: shared.UiConfig.shadowColor
                                      .withValues(alpha: 0.34),
                                  blurRadius: 4),
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
                                fontSize: shared.DesignTokens.captionFontSize,
                                color: scheme.onPrimary.withValues(alpha: 0.7),
                                fontFamily: shared.DesignTokens.fontFamily,
                                fontWeight: shared.UiConfig.fontWeightNormal,
                                shadows: [
                                  Shadow(
                                      color: shared.UiConfig.shadowColor
                                          .withValues(alpha: 0.2),
                                      blurRadius: 2),
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
