import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/customization/customization_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

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
  final String franchiseId;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    required this.franchiseId,
    this.onAddToCart,
    this.showDescription = true,
    this.expanded = false,
    this.margin,
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

  Widget _favoriteHeart(bool isFavorited, bool enabled, AppLocalizations loc) {
    return IconButton(
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color:
            isFavorited ? DesignTokens.accentColor : DesignTokens.hintTextColor,
      ),
      tooltip: enabled
          ? (isFavorited
              ? loc.removeFromFavoritesTooltip
              : loc.addToFavoritesTooltip)
          : loc.signInToFavoriteTooltip,
      onPressed: enabled
          ? () async {
              final firestoreService = Provider.of<shared.FirestoreService>(
                context,
                listen: false,
              );
              if (isFavorited) {
                await firestoreService.removeFavoriteMenuItem(
                  _userId!,
                  widget.franchiseId,
                  widget.menuItem.id,
                );
              } else {
                await firestoreService.addFavoriteMenuItem(
                  _userId!,
                  widget.franchiseId,
                  widget.menuItem.id,
                );
              }
              setState(() {});
            }
          : null,
    );
  }

  Future<void> _handleCustomizeAndAdd(AppLocalizations loc) async {
    final ingredientMetadata =
        Provider.of<Map<String, shared.IngredientMetadata>>(
      context,
      listen: false,
    );

    await showDialog(
      context: context,
      builder: (context) => CustomizationModal(
        menuItem: widget.menuItem,
        ingredientMetadata: ingredientMetadata,
        initialQuantity: _quantity,
        onConfirm: (customizations, quantity, totalPrice) {
          widget.onAddToCart?.call(
            widget.menuItem,
            customizations,
            quantity,
            totalPrice,
          );
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
      widget.menuItem,
      {},
      _quantity,
      widget.menuItem.price * _quantity,
    );
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }

    final isWide = MediaQuery.of(context).size.width > 600;

    final ingredientMetadata =
        Provider.of<Map<String, shared.IngredientMetadata>>(context);

    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(color: DesignTokens.cardBorderColor, width: 1),
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
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  child: widget.menuItem.image != null &&
                          widget.menuItem.image!.isNotEmpty
                      ? SizedBox(
                          width: DesignTokens.menuItemImageWidth,
                          height: DesignTokens.menuItemImageHeight,
                          child: Image.network(
                            widget.menuItem.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              BrandingConfig.defaultPizzaIcon,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Image.asset(
                          BrandingConfig.defaultPizzaIcon,
                          width: DesignTokens.menuItemImageWidth,
                          height: DesignTokens.menuItemImageHeight,
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      visualDensity: VisualDensity.compact,
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.bodyFontSize,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.menuItem.name,
                    style: TextStyle(
                      fontSize: DesignTokens.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${widget.menuItem.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textColor,
                    ),
                  ),
                  if (widget.showDescription &&
                      widget.menuItem.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        widget.menuItem.description,
                        style: TextStyle(
                          fontSize: DesignTokens.captionFontSize,
                          color: DesignTokens.secondaryTextColor,
                        ),
                        maxLines: widget.expanded ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hasCustomizations)
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.secondaryColor,
                                foregroundColor: DesignTokens.foregroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: DesignTokens.buttonElevation,
                              ),
                              onPressed: () => _handleCustomizeAndAdd(loc),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 4),
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
                      if (_hasCustomizations) const SizedBox(width: 8),
                      if (!_hasCustomizations)
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.primaryColor,
                                foregroundColor: DesignTokens.foregroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: DesignTokens.buttonElevation,
                              ),
                              onPressed: () => _handleAddToCart(loc),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 4),
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
                      if (_hasCustomizations) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.primaryColor,
                                foregroundColor: DesignTokens.foregroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: DesignTokens.buttonElevation,
                              ),
                              onPressed: () => _handleAddToCart(loc),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 4),
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
                          : StreamBuilder<List<String>>(
                              stream: Provider.of<shared.FirestoreService>(
                                context,
                                listen: false,
                              ).favoritesMenuItemIdsStream(
                                _userId!,
                                widget.franchiseId,
                              ),
                              builder: (context, idSnapshot) {
                                if (!idSnapshot.hasData) {
                                  return _favoriteHeart(false, false, loc);
                                }
                                final ids = idSnapshot.data!;
                                return _favoriteHeart(
                                  ids.contains(widget.menuItem.id),
                                  true,
                                  loc,
                                );
                              },
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
