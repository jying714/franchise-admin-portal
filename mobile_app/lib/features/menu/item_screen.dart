import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/ordering/cart_screen.dart';
import 'package:franchise_mobile_app/widgets/customization/customization_modal.dart';
import 'package:franchise_mobile_app/widgets/favorite_button.dart';
import 'package:franchise_mobile_app/widgets/dietary_allergen_chips_row.dart';
import 'package:franchise_mobile_app/widgets/menu_item_image.dart';
import 'package:franchise_mobile_app/widgets/included_ingredients_preview.dart';
import 'package:franchise_mobile_app/widgets/quantity_stepper.dart';
import 'package:franchise_mobile_app/widgets/customize_and_add_to_cart_button.dart';
import 'package:franchise_mobile_app/widgets/add_to_cart_button.dart';
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/header/profile_icon_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/config/branding_config.dart';
import 'package:shared_core/src/core/config/design_tokens.dart';
import 'package:shared_core/src/core/models/menu_item.dart';
import 'package:shared_core/src/core/config/app_config.dart';

class ItemScreen extends StatefulWidget {
  final String itemId;
  final MenuItem menuItem;

  const ItemScreen({super.key, required this.itemId, required this.menuItem});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  String? _userId;
  int _quantity = 1;
  bool _isProcessing = false;

  // --- Delivery Options ---
  final double _deliveryFee = 0.0;
  final double _discount = 0.0;
  final String _deliveryType = "pickup"; // 'pickup' or 'delivery'
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
    //print("[DEBUG] ItemScreen menuItem: ${widget.menuItem.toMap()}");
  }

  bool get _hasCustomizations {
    final mi = widget.menuItem;
    return (mi.includedIngredients?.isNotEmpty ?? false) ||
        (mi.customizationGroups?.isNotEmpty ?? false) ||
        (mi.optionalAddOns?.isNotEmpty ?? false);
  }

  void _addToCart(
    MenuItem item,
    Map<String, dynamic> customizations,
    int quantity,
    double totalPrice,
    AppLocalizations loc,
  ) async {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;

    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a franchise location to order.'),
          duration: AppConfig.toastDuration,
        ),
      );
      setState(() => _isProcessing = false);
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
      // Convert customizations map to List<Customization> as expected by service
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
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.addedToCartMessage),
          duration: AppConfig.toastDuration,
        ),
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
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final ingredientMetadata =
        Provider.of<Map<String, shared.IngredientMetadata>>(context,
            listen: false);
    final loc = AppLocalizations.of(context)!;
    //print("[DEBUG] ItemScreen menuItem: ${widget.menuItem.toMap()}");
    return Scaffold(
      appBar: FranchiseAppBar(
        title: widget.menuItem.name,
        centerTitle: true, // or false if you prefer
        showLogo: BrandingConfig.showLogoInAppBar,
        logoAsset: BrandingConfig.appBarLogoAsset,
        logoHeight: 40,
        actions: [
          ProfileIconButton(
            tooltip: loc.profile,
            iconColor: UiConfig.foregroundColorDark,
            iconSize: DesignTokens.iconSize,
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            // Cart
            icon: Icon(
              Icons.shopping_cart,
              size: DesignTokens.iconSize,
              color: UiConfig.foregroundColorDark,
            ),
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
      body: SingleChildScrollView(
        padding: UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ITEM IMAGE
            Center(
              child: MenuItemImage(
                imageUrl: widget.menuItem.image,
                width: DesignTokens.menuItemImageWidth,
                height: DesignTokens.menuItemImageHeight,
              ),
            ),
            const SizedBox(height: DesignTokens.gridSpacing),
            // ITEM NAME
            Text(
              widget.menuItem.name,
              style: TextStyle(
                fontSize: DesignTokens.titleFontSize,
                fontWeight: UiConfig.fontWeightBold,
                color: UiConfig.textColor,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            // PRICE (base price, full total is in modal)
            Text(
              '\$${widget.menuItem.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: UiConfig.textColor,
                fontWeight: UiConfig.fontWeightMedium,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: DesignTokens.gridSpacing),
            // DESCRIPTION
            Text(
              widget.menuItem.description,
              style: TextStyle(
                fontSize: DesignTokens.captionFontSize,
                color: UiConfig.secondaryTextColor,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: DesignTokens.gridSpacing * 2),

            // DIETARY TAGS & ALLERGENS
            DietaryAllergenChipsRow(
              dietaryTags: widget.menuItem.dietaryTags,
              allergens: widget.menuItem.allergens,
            ),

            // QUANTITY SELECTOR (for non-customized items only)
            if (!_hasCustomizations)
              QuantityStepper(
                value: _quantity,
                onIncrement: () => setState(() => _quantity++),
                onDecrement: () => setState(() => _quantity--),
                min: 1,
                fontSize: DesignTokens.bodyFontSize,
                iconSize: DesignTokens.iconSize,
              ),
            const SizedBox(height: DesignTokens.gridSpacing),

            // INCLUDED INGREDIENTS (Preview)
            IncludedIngredientsPreview(
              includedIngredients: widget.menuItem.includedIngredients,
            ),

            // BUTTON ROW
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text("Item not found.")),
                                    );
                                    return;
                                  }
                                  await showDialog(
                                    context: context,
                                    builder: (context) => CustomizationModal(
                                      menuItem: latestMenuItem,
                                      ingredientMetadata: ingredientMetadata,
                                      initialQuantity: 1,
                                      onConfirm: (customizations, quantity,
                                          totalPrice) {
                                        final analyticsReadyCustomizations = {
                                          'toppings':
                                              (customizations['toppings']
                                                          as List<dynamic>? ??
                                                      <dynamic>[])
                                                  .map((e) => e.toString())
                                                  .toList(),
                                          'addOns': (customizations['addOns']
                                                      as List<dynamic>? ??
                                                  <dynamic>[])
                                              .map((e) =>
                                                  e is Map<String, dynamic>
                                                      ? e
                                                      : {
                                                          'name': e.toString(),
                                                          'price': 0.0
                                                        })
                                              .toList(),
                                          'comboSignature': customizations[
                                                  'comboSignature'] ??
                                              _generateComboSignature(
                                                  customizations),
                                          ...customizations, // keep all other original fields too
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
                                      'comboSignature':
                                          '', // Optional: generate signature for combos
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

            const SizedBox(height: DesignTokens.gridSpacing),
          ],
        ),
      ),
    );
  }
}
