import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/categories/category_card.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

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
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

    final loc = AppLocalizations.of(context)!;

    if (categories.isEmpty) {
      // Show provided emptyWidget, or a default empty state
      return emptyWidget ??
          Center(
            child: Text(
              loc.noCategoriesAvailable,
              style: TextStyle(
                color: shared.UiConfig.secondaryTextColor,
                fontSize: shared.DesignTokens.bodyFontSize,
                fontWeight: shared.UiConfig.fontWeightNormal,
                fontFamily: shared.DesignTokens.fontFamily,
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
      padding: padding ?? shared.UiConfig.defaultPadding,
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        childAspectRatio:
            childAspectRatio ?? shared.DesignTokens.gridCardAspectRatio,
        crossAxisSpacing: shared.DesignTokens.gridSpacing,
        mainAxisSpacing: shared.DesignTokens.gridSpacing,
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
