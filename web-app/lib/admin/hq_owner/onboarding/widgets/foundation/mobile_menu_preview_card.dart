import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

/// Shared phone-chrome menu preview used by:
/// - Core Menu Foundation (`interactive: false`) — categories only
/// - Onboarding Menu Items (`interactive: true`) — categories → items + back
///
/// Size is owned here only: 340 × 680. Callers must Center this widget;
/// do not scale or re-declare dimensions.
class MobileMenuPreviewCard extends StatefulWidget {
  final String franchiseId;
  final int currentTabIndex;

  /// false = foundation (no navigation)
  /// true  = Step 3 (tap category → items, back in header)
  final bool interactive;

  const MobileMenuPreviewCard({
    super.key,
    required this.franchiseId,
    this.currentTabIndex = 0,
    this.interactive = false,
  });

  @override
  State<MobileMenuPreviewCard> createState() => _MobileMenuPreviewCardState();
}

class _MobileMenuPreviewCardState extends State<MobileMenuPreviewCard> {
  /// null = category grid; non-null = items for that category id
  String? _previewCategoryId;

  @override
  void didUpdateWidget(covariant MobileMenuPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Franchise change → reset navigation
    if (oldWidget.franchiseId != widget.franchiseId) {
      _previewCategoryId = null;
    }
  }

  String _resolveAppName(shared.FranchiseProvider fp) {
    final live = fp.currentAppName.trim();
    if (live.isNotEmpty && live != 'Franchise App') return live;

    final fromList = fp.viewableFranchises
        .where((f) => f.id == fp.franchiseId)
        .map((f) => f.name.trim())
        .where((n) => n.isNotEmpty)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    if (fromList != null) return fromList;

    final token = DesignTokens.currentAppName.trim();
    if (token.isNotEmpty && token != 'Franchise App') return token;

    return 'Menu';
  }

  Color get _primary => DesignTokens.primaryColor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final categoryProvider = context.watch<shared.CategoryProvider>();
    final menuProvider = context.watch<shared.MenuItemProvider>();

    final categories = categoryProvider.categories;
    final appName = _resolveAppName(franchiseProvider);

    final selectedCategory = _previewCategoryId == null
        ? null
        : categories.cast<shared.Category?>().firstWhere(
              (c) => c?.id == _previewCategoryId,
              orElse: () => null,
            );

    final itemsForCategory = _previewCategoryId == null
        ? const <shared.MenuItem>[]
        : menuProvider.menuItems
            .where((m) => m.categoryId == _previewCategoryId)
            .toList();

    final showBack = widget.interactive && _previewCategoryId != null;
    final headerTitle =
        showBack ? (selectedCategory?.name ?? 'Category') : appName;

    return Container(
      width: 340,
      height: 680,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.grey.shade800, width: 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Column(
          children: [
            // Status bar
            Container(
              height: 30,
              color: Colors.black,
              child: const Center(
                child: Text(
                  '9:41',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            // Branded header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _primary,
              child: Row(
                children: [
                  if (showBack)
                    InkWell(
                      onTap: () => setState(() => _previewCategoryId = null),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    )
                  else if ((franchiseProvider.currentLogoUrl ?? '').isNotEmpty)
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(franchiseProvider.currentLogoUrl!),
                      radius: 18,
                    )
                  else
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.local_pizza, color: _primary),
                    ),
                  if (!showBack) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      headerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 16),
                  const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Container(
                color: Colors.black,
                child: showBack
                    ? _buildItemsGrid(itemsForCategory)
                    : _buildCategoriesGrid(
                        context,
                        categories,
                        loc,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    List<shared.Category> categories,
    AppLocalizations loc,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                loc.previewEmptyState ?? 'Add categories to see live preview',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: widget.interactive
                  ? () => setState(() => _previewCategoryId = category.id)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_pizza, size: 48, color: _primary),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(List<shared.MenuItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No items in this category',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final imageUrl = (item.imageUrl ?? item.image ?? '').toString();
          final outOfStock =
              item.available == false || item.availability == false;

          return Opacity(
            opacity: outOfStock ? 0.45 : 1,
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.local_pizza,
                                    size: 40, color: _primary),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.local_pizza,
                                  size: 40, color: _primary),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      children: [
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
