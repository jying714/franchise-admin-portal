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

  // App bar icons/title on brand primary (matches mobile onPrimary usage).
  Color get _onPrimary => Colors.white;

  // Light scaffold body — not a DesignTokens member; visual parity only.
  Color get _surface => const Color(0xFFF7F7F7);

  String _itemImageUrl(shared.MenuItem item) {
    final raw = item.image?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return item.imageUrl.trim();
  }

  String _categoryImageUrl(shared.Category category) {
    final raw = category.image?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final categoryProvider = context.watch<shared.CategoryProvider>();
    final menuProvider = context.watch<shared.MenuItemProvider>();

    final categories = categoryProvider.categories;
    final appName = _resolveAppName(franchiseProvider);
    final logoUrl = franchiseProvider.currentLogoUrl;

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
            // Status bar (device chrome only)
            Container(
              height: 28,
              color: Colors.black,
              child: const Center(
                child: Text(
                  '9:41',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            // App bar — matches signed-in mobile FranchiseAppBar shape
            Material(
              color: _primary,
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      if (showBack)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: Icon(Icons.arrow_back, color: _onPrimary),
                          onPressed: () =>
                              setState(() => _previewCategoryId = null),
                        )
                      else if (logoUrl != null && logoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              logoUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.storefront,
                                color: _onPrimary,
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.storefront,
                              color: _onPrimary, size: 28),
                        ),
                      Expanded(
                        child: Text(
                          headerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Signed-in chrome (visual only)
                      if (!showBack) ...[
                        Icon(Icons.storefront_outlined,
                            color: _onPrimary, size: 22),
                        const SizedBox(width: 10),
                        Icon(Icons.person_outline, color: _onPrimary, size: 22),
                        const SizedBox(width: 10),
                        Icon(Icons.shopping_cart_outlined,
                            color: _onPrimary, size: 22),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Body — light surface like mobile scaffold
            Expanded(
              child: ColoredBox(
                color: _surface,
                child: showBack
                    ? _buildItemsGrid(itemsForCategory)
                    : _buildCategoriesGrid(context, categories, loc),
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
              Icon(Icons.restaurant_menu,
                  size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 16),
              Text(
                loc.previewEmptyState ?? 'Add categories to see live preview',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final imageUrl = _categoryImageUrl(category);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.interactive
                ? () => setState(() => _previewCategoryId = category.id)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        key: ValueKey(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.restaurant_menu,
                              size: 40, color: _primary),
                        ),
                      )
                    else
                      ColoredBox(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.restaurant_menu,
                            size: 40, color: _primary),
                      ),
                    // Bottom gradient for title readability (mobile CategoryCard)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
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
      },
    );
  }

  Widget _buildItemsGrid(List<shared.MenuItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No items in this category',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrl = _itemImageUrl(item);
        final outOfStock =
            item.available == false || item.availability == false;

        return Opacity(
          opacity: outOfStock ? 0.45 : 1,
          child: Card(
            elevation: 2,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _primary.withOpacity(0.35), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          key: ValueKey(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.broken_image_outlined,
                                size: 36, color: Colors.grey.shade500),
                          ),
                        )
                      : ColoredBox(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.restaurant_menu,
                              size: 40, color: _primary),
                        ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
