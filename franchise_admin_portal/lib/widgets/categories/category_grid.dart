import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/widgets/categories/category_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef CategoryTapCallback = void Function(Category category);

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final CategoryTapCallback? onCategoryTap;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const CategoryGrid({
    Key? key,
    required this.categories,
    this.onCategoryTap,
    this.crossAxisCount,
    this.childAspectRatio,
    this.padding,
    this.emptyWidget,
    this.loadingWidget,
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

    if (categories.isEmpty) {
      // Show provided emptyWidget, or a default empty state
      return emptyWidget ??
          Center(
            child: Text(
              loc.noCategoriesAvailable,
              style: const TextStyle(
                color: DesignTokens.secondaryTextColor,
                fontSize: DesignTokens.bodyFontSize,
                fontWeight: DesignTokens.bodyFontWeight,
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
      padding: padding ?? DesignTokens.gridPadding,
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
