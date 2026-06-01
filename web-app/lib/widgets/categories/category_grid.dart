import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/categories/category_card.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }

    if (categories.isEmpty) {
      return emptyWidget ??
          Center(
            child: Text(
              loc.noCategoriesAvailable,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              semanticsLabel: loc.noCategoriesAvailable,
            ),
          );
    }

    final int gridCount =
        crossAxisCount ?? (MediaQuery.of(context).size.width > 600 ? 3 : 2);

    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
