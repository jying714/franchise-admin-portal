import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/categories/category_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:shared_core/src/core/config/design_tokens.dart';

typedef CategoryTapCallback = void Function(shared.Category category);

class CategoryGrid extends StatelessWidget {
  final List<shared.Category> categories;
  final CategoryTapCallback? onCategoryTap;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.crossAxisCount,
    this.childAspectRatio,
    this.padding,
    this.emptyWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (categories.isEmpty) {
      // Show provided emptyWidget, or a default empty state
      return emptyWidget ??
          Center(
            child: Text(
              loc.noCategoriesAvailable,
              style: TextStyle(
                color: UiConfig.secondaryTextColor,
                fontSize: DesignTokens.bodyFontSize,
                fontWeight: UiConfig.fontWeightNormal,
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
              semanticsLabel: loc.noCategoriesAvailable,
            ),
          );
    }

    // Responsive grid columns: default 2 (mobile), 3 (tablet+)
    final int gridCount =
        crossAxisCount ?? (MediaQuery.of(context).size.width > 600 ? 3 : 2);

    return GridView.builder(
      padding: padding ?? UiConfig.defaultPadding,
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        childAspectRatio: childAspectRatio ?? DesignTokens.gridCardAspectRatio,
        crossAxisSpacing: DesignTokens.gridSpacing,
        mainAxisSpacing: DesignTokens.gridSpacing,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: onCategoryTap,
        );
      },
    );
  }
}
