import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/ordering/cart_screen.dart';
import 'package:franchise_mobile_app/widgets/customization/customization_modal.dart';
import 'package:franchise_mobile_app/widgets/favorite_button.dart';
// P1 Batch 1 cross-ref updated: uses updated customization_modal with FranchiseProvider scoping
import 'package:franchise_mobile_app/widgets/dietary_allergen_chips_row.dart';
import 'package:franchise_mobile_app/widgets/menu_item_image.dart';
import 'package:franchise_mobile_app/widgets/included_ingredients_preview.dart';
import 'package:franchise_mobile_app/widgets/quantity_stepper.dart';
import 'package:franchise_mobile_app/widgets/customize_and_add_to_cart_button.dart';
import 'package:franchise_mobile_app/widgets/add_to_cart_button.dart';
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/header/profile_icon_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ItemScreen extends StatefulWidget {
  final String itemId;
  final shared.MenuItem menuItem;

  const ItemScreen({
    super.key,
    required this.itemId,
    required this.menuItem,
  });

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  String? _userId;
  int _quantity = 1;
  bool _isProcessing = false;

  final double _deliveryFee = 0.0;
  final double _discount = 0.0;
  final String _deliveryType = "pickup";
  String _time = "";
  final int _estimatedTime = 30;

  String _generateComboSignature(Map<String, dynamic> customizations) {
    final toppings =
        (customizations['toppings'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final addOns = (customizations['addOns'] as List<dynamic>? ?? <dynamic>[])
        .map((e) =>
            e is Map && e['name'] != null ? e['name'].toString() : e.toString())
        .toList();
    final all = [...toppings, ...addOns]..sort();
    return all.join('|');
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    _time = DateTime.now().toIso8601String().substring(0, 16);
  }

  bool get _hasCustomizations {
    final mi = widget.menuItem;
    return (mi.includedIngredients?.isNotEmpty ?? false) ||
        (mi.customizationGroups?.isNotEmpty ?? false) ||
        (mi.optionalAddOns?.isNotEmpty ?? false);
  }

  void _addToCart(
    shared.MenuItem item,
    Map<String, dynamic> customizations,
    int quantity,
    double totalPrice,
    AppLocalizations loc,
  ) async {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;

    if (franchiseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a franchise location to order.')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.signInToOrderMessage)),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final List<shared.Customization> customizationList =
          (customizations['groups'] as List<dynamic>? ?? [])
              .map((e) =>
                  shared.Customization.fromMap(e as Map<String, dynamic>))
              .toList();

      await firestoreService.addToCart(
        userId: _userId!,
        franchiseId: franchiseId,
        menuItem: item,
        customizations: customizationList,
        quantity: quantity,
        price: totalPrice,
        specialInstructions: customizations['specialInstructions'] as String?,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.addedToCartMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cartAddError)),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: FranchiseAppBar(
        title: widget.menuItem.name,
        centerTitle: true,
        showLogo: shared.BrandingConfig.showLogoInAppBar,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        logoHeight: 40,
        actions: [
          ProfileIconButton(
            tooltip: loc.profile,
            iconColor: UiConfig.foregroundColorDark,
            iconSize: shared.DesignTokens.iconSize,
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart,
                size: shared.DesignTokens.iconSize,
                color: UiConfig.foregroundColorDark),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            tooltip: loc.cartTooltip,
          ),
          FavoriteButton(itemId: widget.itemId, userId: _userId),
        ],
        backgroundColor: UiConfig.primaryColor,
        foregroundColor: UiConfig.foregroundColorDark,
        elevation: 0,
      ),
      backgroundColor: UiConfig.backgroundColor,
      body: Consumer<shared.FranchiseProvider>(
        builder: (context, provider, child) {
          if (!provider.hasValidFranchise) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: UiConfig.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ITEM IMAGE
                Center(
                  child: MenuItemImage(
                    imageUrl: widget.menuItem.image,
                    width: shared.DesignTokens.menuItemImageWidth,
                    height: shared.DesignTokens.menuItemImageHeight,
                  ),
                ),
                const SizedBox(height: shared.DesignTokens.gridSpacing),

                // ITEM NAME + PRICE
                Text(
                  widget.menuItem.name,
                  style: TextStyle(
                    fontSize: shared.DesignTokens.titleFontSize,
                    fontWeight: UiConfig.fontWeightBold,
                    color: UiConfig.textColor,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                Text(
                  '\$${widget.menuItem.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: shared.DesignTokens.bodyFontSize,
                    color: UiConfig.textColor,
                    fontWeight: UiConfig.fontWeightMedium,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                const SizedBox(height: shared.DesignTokens.gridSpacing),

                // DESCRIPTION
                Text(
                  widget.menuItem.description,
                  style: TextStyle(
                    fontSize: shared.DesignTokens.captionFontSize,
                    color: UiConfig.secondaryTextColor,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                const SizedBox(height: shared.DesignTokens.gridSpacing * 2),

                // DIETARY + ALLERGENS
                DietaryAllergenChipsRow(
                  dietaryTags: widget.menuItem.dietaryTags,
                  allergens: widget.menuItem.allergens,
                ),

                // QUANTITY (for non-custom items)
                if (!_hasCustomizations)
                  QuantityStepper(
                    value: _quantity,
                    onIncrement: () => setState(() => _quantity++),
                    onDecrement: () => setState(() => _quantity--),
                    min: 1,
                    fontSize: shared.DesignTokens.bodyFontSize,
                    iconSize: shared.DesignTokens.iconSize,
                  ),
                const SizedBox(height: shared.DesignTokens.gridSpacing),

                // INCLUDED INGREDIENTS
                IncludedIngredientsPreview(
                  includedIngredients: widget.menuItem.includedIngredients,
                ),

                const SizedBox(height: shared.DesignTokens.gridSpacing * 2),

                // ADD / CUSTOMIZE BUTTON
                Row(
                  children: [
                    Expanded(
                      child: _hasCustomizations
                          ? CustomizeAndAddToCartButton(
                              isProcessing: _isProcessing,
                              label: loc.customizeAndAddToCart,
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      final latestMenuItem = await Provider.of<
                                          shared.FirestoreService>(
                                        context,
                                        listen: false,
                                      ).getMenuItemById(widget.itemId);

                                      if (latestMenuItem == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text("Item not found.")),
                                        );
                                        return;
                                      }

                                      await showDialog(
                                        context: context,
                                        builder: (context) =>
                                            CustomizationModal(
                                          menuItem: latestMenuItem,
                                          ingredientMetadata: const {}, // Pass real data if available
                                          initialQuantity: 1,
                                          onConfirm: (customizations, quantity,
                                              totalPrice) {
                                            final analyticsReadyCustomizations =
                                                {
                                              'toppings': (customizations[
                                                              'toppings']
                                                          as List<dynamic>? ??
                                                      [])
                                                  .map((e) => e.toString())
                                                  .toList(),
                                              'addOns': (customizations[
                                                              'addOns']
                                                          as List<dynamic>? ??
                                                      [])
                                                  .map((e) =>
                                                      e is Map<String, dynamic>
                                                          ? e
                                                          : {
                                                              'name':
                                                                  e.toString()
                                                            })
                                                  .toList(),
                                              'comboSignature': customizations[
                                                      'comboSignature'] ??
                                                  _generateComboSignature(
                                                      customizations),
                                              ...customizations,
                                            };

                                            _addToCart(
                                              latestMenuItem,
                                              analyticsReadyCustomizations,
                                              quantity,
                                              totalPrice,
                                              loc,
                                            );
                                          },
                                        ),
                                      );
                                    },
                            )
                          : AddToCartButton(
                              isProcessing: _isProcessing,
                              label: loc.addToCart,
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      _addToCart(
                                        widget.menuItem,
                                        {
                                          'toppings': <String>[],
                                          'addOns': <Map<String, dynamic>>[],
                                          'comboSignature': '',
                                        },
                                        _quantity,
                                        widget.menuItem.price * _quantity,
                                        loc,
                                      );
                                    },
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: shared.DesignTokens.gridSpacing),
              ],
            ),
          );
        },
      ),
    );
  }
}
