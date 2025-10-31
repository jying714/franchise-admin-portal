// lib/widgets/menu_item_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import '../../../packages/shared_core/lib/src/core/models/menu_item.dart';
import '../../../packages/shared_core/lib/src/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/widgets/customization/customization_modal.dart';
import '../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef AddToCartCallback = void Function(
  MenuItem menuItem,
  Map<String, dynamic> customizations,
  int quantity,
  double totalPrice,
);

class MenuItemCard extends StatefulWidget {
  final MenuItem menuItem;
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
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
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
    // Get ingredientMetadata from Provider (required for CustomizationModal)
    final ingredientMetadata =
        Provider.of<Map<String, IngredientMetadata>>(context, listen: false);

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
      (widget.menuItem.optionalAddOns?.isNotEmpty ?? false);

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
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final isWide = MediaQuery.of(context).size.width > 600;

    // *** PULL INGREDIENT METADATA HERE ***
    final ingredientMetadata =
        Provider.of<Map<String, IngredientMetadata>>(context);

    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: const BorderSide(color: DesignTokens.cardBorderColor, width: 1),
      ),
      child: Padding(
        padding: isWide
            ? const EdgeInsets.all(20)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ITEM IMAGE + QUANTITY ---
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
                // Quantity Selector under Image
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
                      style: const TextStyle(
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
            // --- DETAILS + ACTIONS ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME
                  Text(
                    widget.menuItem.name,
                    style: const TextStyle(
                      fontSize: DesignTokens.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // PRICE
                  Text(
                    '\$${widget.menuItem.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textColor,
                    ),
                  ),
                  // DESCRIPTION
                  if (widget.showDescription &&
                      widget.menuItem.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        widget.menuItem.description,
                        style: const TextStyle(
                          fontSize: DesignTokens.captionFontSize,
                          color: DesignTokens.secondaryTextColor,
                        ),
                        maxLines: widget.expanded ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // --- BUTTONS & HEART ROW ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customize button
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
                      // Plain add to cart if NO customizations
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
                      // Heart/favorite
                      _userId == null
                          ? _favoriteHeart(false, false, loc)
                          : StreamBuilder<List<String>>(
                              stream:
                                  firestoreService.favoritesMenuItemIdsStream(
                                      _userId!, widget.franchiseId),
                              builder: (context, idSnapshot) {
                                if (!idSnapshot.hasData)
                                  return _favoriteHeart(false, false, loc);
                                final ids = idSnapshot.data!;
                                return StreamBuilder<List<MenuItem>>(
                                  stream: firestoreService.getMenuItemsByIds(
                                      widget.franchiseId, ids),
                                  builder: (context, itemSnapshot) {
                                    if (itemSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _favoriteHeart(false, false, loc);
                                    }
                                    if (itemSnapshot.hasError) {
                                      return _favoriteHeart(false, true, loc);
                                    }
                                    final isFavorited = itemSnapshot.data?.any(
                                          (mi) => mi.id == widget.menuItem.id,
                                        ) ??
                                        false;
                                    return _favoriteHeart(
                                        isFavorited, true, loc);
                                  },
                                );
                              },
                            )
                    ],
                  ),
                  // -- EXAMPLE: Show allergen tags from metadata (optional) --
                  if (_hasCustomizations &&
                      widget.menuItem.includedIngredients != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 6,
                        children: widget.menuItem.includedIngredients!
                            .map((ingredientId) {
                          final meta = ingredientMetadata[ingredientId];
                          if (meta == null || meta.allergens.isEmpty)
                            return const SizedBox();
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
          ],
        ),
      ),
    );
  }
}
