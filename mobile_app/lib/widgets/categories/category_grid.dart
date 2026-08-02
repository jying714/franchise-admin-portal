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

    final int gridCount =
        crossAxisCount ?? (MediaQuery.of(context).size.width > 600 ? 3 : 2);

    int orderOf(shared.Category c) => c.sortOrder ?? 999999;

    final withImage = categories
        .where((c) => c.image != null && c.image!.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => orderOf(a).compareTo(orderOf(b)));

    final reducedList = categories
        .where((c) => c.image == null || c.image!.trim().isEmpty)
        .toList()
      ..sort((a, b) => orderOf(a).compareTo(orderOf(b)));

    // Unified slots: each image category = 1 cell; each pair of reduced = 1 cell.
    // Reduced pairs append after image cells so they fill the next open grid cell
    // (e.g. empty right slot beside the last image card).
    final List<List<shared.Category>> slots = [
      for (final c in withImage) [c],
      for (var i = 0; i < reducedList.length; i += 2)
        reducedList.sublist(
          i,
          i + 2 > reducedList.length ? reducedList.length : i + 2,
        ),
    ];

    return GridView.builder(
      padding: padding ?? shared.UiConfig.defaultPadding,
      itemCount: slots.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        childAspectRatio:
            childAspectRatio ?? shared.DesignTokens.gridCardAspectRatio,
        crossAxisSpacing: shared.DesignTokens.gridSpacing,
        mainAxisSpacing: shared.DesignTokens.gridSpacing,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];

        // Image category — full card
        if (slot.length == 1 &&
            slot.first.image != null &&
            slot.first.image!.trim().isNotEmpty) {
          return CategoryCard(
            category: slot.first,
            onTap: onCategoryTap,
            reduced: false,
          );
        }

        // Reduced pair (or single leftover) stacked in one cell
        return Column(
          children: [
            Expanded(
              child: CategoryCard(
                category: slot.first,
                onTap: onCategoryTap,
                reduced: true,
              ),
            ),
            if (slot.length > 1) ...[
              SizedBox(height: shared.DesignTokens.gridSpacing),
              Expanded(
                child: CategoryCard(
                  category: slot[1],
                  onTap: onCategoryTap,
                  reduced: true,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
