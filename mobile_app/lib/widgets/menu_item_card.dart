import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/customization/customization_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

// P1 Batch 1: direct caller of customization_modal (mobile canonical, shared.FranchiseProvider + shared.UiConfig enforced)
// P1 Batch 3: menu_item_card + cross-cutting widgets (FranchiseProvider injection + public barrels enforced)

typedef AddToCartCallback = void Function(
  shared.MenuItem menuItem,
  Map<String, dynamic> customizations,
  int quantity,
  double totalPrice,
);

class MenuItemCard extends StatefulWidget {
  final shared.MenuItem menuItem;
  final AddToCartCallback? onAddToCart;
  final bool showDescription;
  final bool expanded;
  final EdgeInsets? margin;
  final bool?
      isFavorited; // Optional: parent (e.g. CategoryScreen) can provide via its own favorites stream for reactivity

  /// When true, omit the image column (no-image items). Parent places these
  /// below image cards while preserving stream / sort order within the band.
  final bool reduced;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    this.onAddToCart,
    this.showDescription = true,
    this.expanded = false,
    this.margin,
    this.isFavorited,
    this.reduced = false,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  int _quantity = 1;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  // Batch 3: FranchiseProvider injected for centrality + franchise/{franchiseId}/ scoping

  Widget _favoriteHeart(bool isFavorited, bool enabled, AppLocalizations loc) {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    return IconButton(
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color: isFavorited
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: enabled
          ? (isFavorited
              ? loc.removeFromFavoritesTooltip
              : loc.addToFavoritesTooltip)
          : loc.signInToFavoriteTooltip,
      onPressed: enabled
          ? () async {
              final franchiseProvider =
                  Provider.of<shared.FranchiseProvider>(context, listen: false);
              final franchiseId = franchiseProvider.currentFranchiseId;

              if (isFavorited) {
                await firestoreService.removeFavoriteMenuItemForUser(
                    _userId!, widget.menuItem.id,
                    franchiseId: franchiseId);
              } else {
                await firestoreService.addFavoriteMenuItemForUser(
                    _userId!, widget.menuItem.id,
                    franchiseId: franchiseId);
              }
              setState(() {});
            }
          : null,
    );
  }

  Future<void> _handleCustomizeAndAdd(AppLocalizations loc) async {
    final ingredientMetadata =
        Provider.of<Map<String, shared.IngredientMetadata>>(context,
            listen: false);

    await showDialog(
      context: context,
      builder: (context) => CustomizationModal(
        menuItem: widget.menuItem,
        ingredientMetadata: ingredientMetadata,
        initialQuantity: _quantity,
        onConfirm: (customizations, quantity, totalPrice) {
          widget.onAddToCart
              ?.call(widget.menuItem, customizations, quantity, totalPrice);
          setState(() => _quantity = 1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.addedToCartMessage)),
          );
        },
      ),
    );
  }

  void _handleAddToCart(AppLocalizations loc) {
    widget.onAddToCart?.call(
        widget.menuItem, {}, _quantity, widget.menuItem.price * _quantity);
    setState(() => _quantity = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.addedToCartMessage)),
    );
  }

  bool get _hasCustomizations =>
      (widget.menuItem.includedIngredients?.isNotEmpty ?? false) ||
      (widget.menuItem.customizationGroups?.isNotEmpty ?? false) ||
      (widget.menuItem.optionalAddOns?.isNotEmpty ?? false) ||
      (widget.menuItem.modifierGroups?.isNotEmpty ?? false) ||
      (widget.menuItem.sizes?.isNotEmpty ?? false);

  /// Base price 0 (or sizes without a usable base) must not plain-add at $0.
  bool get _requiresCustomizeForPrice {
    if (widget.menuItem.price > 0) return false;
    final sizes = widget.menuItem.sizes;
    if (sizes != null && sizes.isNotEmpty) return true;
    final sp = widget.menuItem.sizePrices;
    if (sp != null && sp.isNotEmpty) return true;
    return widget.menuItem.price <= 0;
  }

  bool get _showPlainAddToCart =>
      !_hasCustomizations && !_requiresCustomizeForPrice;

  bool get _showCustomizeOnly =>
      _hasCustomizations || _requiresCustomizeForPrice;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final isWide = MediaQuery.of(context).size.width > 600;

    final ingredientMetadata =
        Provider.of<Map<String, shared.IngredientMetadata>>(context);

    final Widget actionsRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showCustomizeOnly)
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.surface,
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: shared.DesignTokens.buttonElevation,
                ),
                onPressed: () => _handleCustomizeAndAdd(loc),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      loc.customize,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_showCustomizeOnly && _showPlainAddToCart) const SizedBox(width: 8),
        if (_showPlainAddToCart)
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: shared.DesignTokens.buttonElevation,
                ),
                onPressed: () => _handleAddToCart(loc),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      loc.addToCart,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_hasCustomizations && !_requiresCustomizeForPrice) ...[
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: shared.DesignTokens.buttonElevation,
                ),
                onPressed: () => _handleAddToCart(loc),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      loc.addToCart,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        _userId == null
            ? _favoriteHeart(false, false, loc)
            : StreamBuilder<List<shared.MenuItem>>(
                stream: firestoreService.getFavoriteMenuItemsForUser(
                  _userId!,
                  franchiseId: Provider.of<shared.FranchiseProvider>(context,
                          listen: false)
                      .currentFranchiseId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _favoriteHeart(false, false, loc);
                  }
                  if (snapshot.hasError) {
                    return _favoriteHeart(false, true, loc);
                  }
                  final isFavorited =
                      snapshot.data?.any((mi) => mi.id == widget.menuItem.id) ??
                          false;
                  return _favoriteHeart(isFavorited, true, loc);
                },
              ),
      ],
    );

    final Widget quantityStepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: scheme.onSurface),
          visualDensity: VisualDensity.compact,
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
        ),
        Text(
          '$_quantity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: shared.DesignTokens.bodyFontSize,
            color: scheme.onSurface,
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: scheme.primary),
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _quantity++),
        ),
      ],
    );

    final Widget detailsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.menuItem.name,
          style: shared.UiConfig.titleStyle.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '\$${widget.menuItem.price.toStringAsFixed(2)}',
          style: shared.UiConfig.bodyStyle.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.showDescription && widget.menuItem.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              widget.menuItem.description,
              style: shared.UiConfig.captionStyle.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: widget.expanded ? 4 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 10),
        actionsRow,
        if (_hasCustomizations && widget.menuItem.includedIngredients != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 6,
              children:
                  widget.menuItem.includedIngredients!.map((ingredientId) {
                final meta = ingredientMetadata[ingredientId];
                if (meta == null || meta.allergens.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Chip(
                  label: Text(meta.allergens.join(', ')),
                  backgroundColor: Colors.orange.shade100,
                );
              }).toList(),
            ),
          ),
      ],
    );

    if (widget.reduced) {
      return Card(
        margin: widget.margin ??
            const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        elevation: 1,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + quantity on one row (keeps card short)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.menuItem.name,
                      style: shared.UiConfig.titleStyle.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  quantityStepper,
                ],
              ),
              Text(
                '\$${widget.menuItem.price.toStringAsFixed(2)}',
                style: shared.UiConfig.bodyStyle.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.showDescription &&
                  widget.menuItem.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    widget.menuItem.description,
                    style: shared.UiConfig.captionStyle.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 6),
              // Customize / Add / heart under title row
              actionsRow,
              if (_hasCustomizations &&
                  widget.menuItem.includedIngredients != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Wrap(
                    spacing: 6,
                    children: widget.menuItem.includedIngredients!
                        .map((ingredientId) {
                      final meta = ingredientMetadata[ingredientId];
                      if (meta == null || meta.allergens.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Chip(
                        label: Text(meta.allergens.join(', ')),
                        backgroundColor: Colors.orange.shade100,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      elevation: 2,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        side: BorderSide(color: scheme.outline, width: 1),
      ),
      child: Padding(
        padding: isWide
            ? const EdgeInsets.all(20)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(shared.DesignTokens.cardRadius),
                  child: widget.menuItem.image != null &&
                          widget.menuItem.image!.isNotEmpty
                      ? Image.network(
                          widget.menuItem.image!,
                          width: shared.DesignTokens.menuItemImageWidth,
                          height: shared.DesignTokens.menuItemImageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            shared.BrandingConfig.defaultPizzaIcon,
                            width: shared.DesignTokens.menuItemImageWidth,
                            height: shared.DesignTokens.menuItemImageHeight,
                          ),
                        )
                      : Image.asset(
                          shared.BrandingConfig.defaultPizzaIcon,
                          width: shared.DesignTokens.menuItemImageWidth,
                          height: shared.DesignTokens.menuItemImageHeight,
                        ),
                ),
                const SizedBox(height: 8),
                quantityStepper,
              ],
            ),
            const SizedBox(width: 14),
            Expanded(child: detailsColumn),
          ],
        ),
      ),
    );
  }
}
