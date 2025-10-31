import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/models/customization.dart';
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'package:franchise_mobile_app/features/ordering/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Key retryKey = UniqueKey();

  Map<String, Map<String, Customization>> _menuItemCustomizationObjectMap(
      List<order_model.OrderItem> items, List<MenuItem> menuItems) {
    final map = <String, Map<String, Customization>>{};
    for (final item in items) {
      final menu = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => MenuItem(
          id: item.menuItemId,
          category: '',
          categoryId: '',
          name: '',
          price: 0,
          description: '',
          customizationGroups: [],
          customizations: [],
          taxCategory: '',
          availability: true,
        ),
      );
      final customObjMap = <String, Customization>{};
      for (final group in menu.customizations) {
        customObjMap[group.id] = group;
        if (group.isGroup && group.options != null) {
          for (final option in group.options!) {
            customObjMap[option.id] = option;
          }
        }
      }
      map[item.menuItemId] = customObjMap;
    }
    return map;
  }

  Set<String> _allIngredientIdsInCart(
    List<order_model.OrderItem> items,
    List<MenuItem> menuItems,
  ) {
    final ids = <String>{};
    for (final item in items) {
      final menu = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => MenuItem(
          id: item.menuItemId,
          category: '',
          categoryId: '',
          name: '',
          price: 0,
          description: '',
          customizationGroups: [],
          customizations: [],
          taxCategory: '',
          availability: true,
        ),
      );
      // Included Ingredients
      if (menu.includedIngredients != null) {
        for (final ing in menu.includedIngredients!) {
          final ingId = ing['ingredientId'] ?? ing['id'];
          final removed = item.customizations['removedIncluded'] != null &&
              (item.customizations['removedIncluded'] as List).contains(ingId);
          if (!removed && ingId != null && ingId.isNotEmpty) {
            ids.add(ingId);
          }
        }
      }
      // Customization Groups
      if (item.customizations != null) {
        item.customizations.forEach((key, val) {
          if (val is List) {
            for (final sel in val) {
              if (sel is Map && sel.containsKey('id')) {
                final selId = sel['id'];
                if (selId != null && selId is String && selId.isNotEmpty) {
                  ids.add(selId);
                }
              } else if (sel is String) {
                ids.add(sel);
              }
            }
          }
        });
      }
      // Add-ons
      if (item.customizations['selectedAddOns'] != null) {
        for (final selId in (item.customizations['selectedAddOns'] as List)) {
          if (selId != null && selId is String && selId.isNotEmpty) {
            ids.add(selId);
          }
        }
      }
    }
    return ids;
  }

  List<String> _allAllergensInCart(
    List<order_model.OrderItem> items,
    List<MenuItem> menuItems,
    List<IngredientMetadata> ingredientMetadatas,
  ) {
    final allergenSet = <String>{};
    final allIngIds = _allIngredientIdsInCart(items, menuItems);
    final metaMap = {for (final m in ingredientMetadatas) m.id: m};
    for (final ingId in allIngIds) {
      final meta = metaMap[ingId];
      if (meta != null && meta.allergens.isNotEmpty) {
        allergenSet.addAll(meta.allergens);
      }
    }
    return allergenSet.toList()..sort();
  }

  Widget renderCustomizations(
    dynamic customizations,
    Map<String, Customization> customObjMap,
    AppLocalizations loc,
  ) {
    if (customizations == null ||
        (customizations is List && customizations.isEmpty)) {
      return const SizedBox.shrink();
    }
    if (customizations is Map<String, dynamic>) {
      List<Widget> rows = [];
      customizations.forEach((groupOrOptionId, selection) {
        final custom = customObjMap[groupOrOptionId];
        final displayName = custom?.name ?? groupOrOptionId.toString();

        if (custom != null &&
            custom.isGroup &&
            selection is List &&
            selection.isNotEmpty) {
          final optionWidgets = <InlineSpan>[];
          for (final opt in selection) {
            final optId = opt is Map ? opt['id'] : opt;
            final option = customObjMap[optId];
            if (option == null) continue;
            String details = '';
            if (opt is Map) {
              if (opt['portion'] != null && opt['portion'] != 'whole') {
                String portionLabel = opt['portion'] == 'left'
                    ? loc.leftSide
                    : opt['portion'] == 'right'
                        ? loc.rightSide
                        : opt['portion'].toString();
                details += ' ($portionLabel)';
              }
              if ((opt['extra'] ?? false) == true) details += ' (${loc.extra})';
              if ((opt['double'] ?? false) == true)
                details += ' (${loc.doubleTopping})';
              if ((opt['quantity'] ?? 1) > 1) details += ' x${opt['quantity']}';
            }
            final upcharge = option.price > 0
                ? ' (+${loc.currencyFormat(option.price)})'
                : '';
            optionWidgets.add(TextSpan(
                text: '${option.name}$details$upcharge',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: DesignTokens.secondaryTextColor,
                  fontFamily: DesignTokens.fontFamily,
                )));
            optionWidgets.add(const TextSpan(text: ', '));
          }
          if (optionWidgets.isNotEmpty) optionWidgets.removeLast();
          rows.add(
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$displayName: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.secondaryTextColor,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  ...optionWidgets,
                ],
              ),
            ),
          );
        } else if (selection is bool && selection) {
          final upcharge = (custom?.price ?? 0) > 0
              ? ' (+${loc.currencyFormat(custom!.price)})'
              : '';
          rows.add(
            Text(
              '$displayName$upcharge',
              style: const TextStyle(
                fontSize: DesignTokens.captionFontSize,
                color: DesignTokens.secondaryTextColor,
                fontWeight: DesignTokens.bodyFontWeight,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          );
        }
      });
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    } else if (customizations is List) {
      final joined = customizations.join(', ');
      return Text(
        joined.substring(0, min(50, joined.length)),
        style: const TextStyle(
          fontSize: DesignTokens.captionFontSize,
          color: DesignTokens.secondaryTextColor,
          fontWeight: DesignTokens.bodyFontWeight,
          fontFamily: DesignTokens.fontFamily,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.cart,
          style: const TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: DesignTokens.foregroundColor,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: user == null
          ? Center(
              child: Text(
                loc.mustSignInForCart,
                style: const TextStyle(
                  fontSize: DesignTokens.bodyFontSize,
                  color: DesignTokens.textColor,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.bodyFontWeight,
                ),
              ),
            )
          : StreamBuilder<order_model.Order?>(
              key: retryKey,
              stream: firestoreService.getCart(user.uid),
              builder: (context, cartSnapshot) {
                if (cartSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (cartSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${loc.errorLoadingCart}\n${cartSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            color: DesignTokens.errorTextColor,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.bodyFontWeight,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.gridSpacing * 2),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryColor,
                            foregroundColor: DesignTokens.foregroundColor,
                            padding: DesignTokens.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.buttonRadius),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              retryKey = UniqueKey();
                            });
                          },
                          child: Text(loc.retry),
                        ),
                      ],
                    ),
                  );
                }
                final cart = cartSnapshot.data;
                if (cart == null || cart.items.isEmpty) {
                  return buildEmptyState(context, loc);
                }
                return StreamBuilder<List<MenuItem>>(
                  stream: firestoreService.getMenuItemsByIds(
                      cart.items.map((i) => i.menuItemId).toList()),
                  builder: (context, menuSnapshot) {
                    final menuItems = menuSnapshot.data ?? [];
                    final objMap =
                        _menuItemCustomizationObjectMap(cart.items, menuItems);

                    return StreamBuilder<List<MenuItem>>(
                      stream: firestoreService.getMenuItemsByIds(
                          cart.items.map((i) => i.menuItemId).toList()),
                      builder: (context, menuSnapshot) {
                        final menuItems = menuSnapshot.data ?? [];
                        final objMap = _menuItemCustomizationObjectMap(
                            cart.items, menuItems);

                        return FutureBuilder<List<IngredientMetadata>>(
                          future: firestoreService.getAllIngredientMetadata(),
                          builder: (context, ingredientSnapshot) {
                            final ingredientMetadatas =
                                ingredientSnapshot.data ?? [];
                            final allAllergens = _allAllergensInCart(
                                cart.items, menuItems, ingredientMetadatas);
                            final showAllergenWarning = allAllergens.isNotEmpty;

                            return AnimatedSwitcher(
                              duration: DesignTokens.animationDuration,
                              child: Column(
                                children: [
                                  if (showAllergenWarning)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          top: 16,
                                          bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: DesignTokens.errorBgColor
                                            .withOpacity(0.11),
                                        borderRadius: BorderRadius.circular(
                                            DesignTokens.cardRadius),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                              Icons.warning_amber_rounded,
                                              color: DesignTokens.errorColor,
                                              size: 28),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${loc.warning}: ${loc.itemsInCartCouldContain}\n'
                                              '${allAllergens.join(", ")}',
                                              style: TextStyle(
                                                color: DesignTokens.errorColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily:
                                                    DesignTokens.fontFamily,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: buildCartContent(
                                      context,
                                      cart,
                                      firestoreService,
                                      loc,
                                      objMap,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            loc.yourCartIsEmpty,
            style: const TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          const SizedBox(height: DesignTokens.gridSpacing * 2),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.secondaryColor,
              foregroundColor: DesignTokens.foregroundColor,
              padding: DesignTokens.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              elevation: DesignTokens.buttonElevation,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(loc.startShopping),
          ),
        ],
      ),
    );
  }

  Widget buildCartContent(
    BuildContext context,
    order_model.Order cart,
    FirestoreService firestoreService,
    AppLocalizations loc,
    Map<String, Map<String, Customization>> objMap,
  ) {
    Future<void> updateCart(order_model.Order updatedCart) async {
      await firestoreService.updateCart(updatedCart);
    }

    void removeItem(int index) async {
      final updatedItems = List<order_model.OrderItem>.from(cart.items)
        ..removeAt(index);
      final updatedCart = cart.copyWith(items: updatedItems);
      await updateCart(updatedCart);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.itemRemovedFromCart,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          backgroundColor: DesignTokens.surfaceColor,
          duration: DesignTokens.toastDuration,
        ),
      );
    }

    void clearCart() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            loc.clearCart,
            style: const TextStyle(
              fontWeight: DesignTokens.titleFontWeight,
              color: DesignTokens.primaryColor,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          content: Text(
            loc.clearCartConfirmation,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.disabledTextColor,
              ),
              child: Text(loc.no),
            ),
            TextButton(
              onPressed: () async {
                await firestoreService.updateCart(cart.copyWith(items: []));
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      loc.cartCleared,
                      style: const TextStyle(
                        color: DesignTokens.errorTextColor,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.bodyFontWeight,
                      ),
                    ),
                    backgroundColor: DesignTokens.surfaceColor,
                    duration: DesignTokens.toastDuration,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primaryColor,
              ),
              child: Text(loc.yes),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('filled'),
      children: [
        Expanded(
          child: ListView.builder(
            padding: DesignTokens.gridPadding,
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              final customMap = objMap[item.menuItemId] ?? {};
              return Card(
                elevation: DesignTokens.cardElevation,
                margin: const EdgeInsets.symmetric(
                    vertical: DesignTokens.gridSpacing / 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
                color: DesignTokens.surfaceColor,
                child: ListTile(
                  leading: NetworkImageWidget(
                    imageUrl: item.image ?? '',
                    fallbackAsset: BrandingConfig.defaultPizzaIcon,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.imageRadius),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: DesignTokens.textColor,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.bodyFontWeight,
                    ),
                  ),
                  subtitle:
                      renderCustomizations(item.customizations, customMap, loc),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: DesignTokens.bodyFontSize,
                          color: DesignTokens.textColor,
                          fontWeight: DesignTokens.bodyFontWeight,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: DesignTokens.errorColor,
                          size: DesignTokens.iconSize,
                        ),
                        onPressed: () => removeItem(index),
                        tooltip: loc.removeItem,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: DesignTokens.gridPadding,
          child: Column(
            children: [
              Text(
                '${loc.total}: \$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: DesignTokens.titleFontSize,
                  fontWeight: DesignTokens.titleFontWeight,
                  color: DesignTokens.textColor,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(height: DesignTokens.gridSpacing),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.secondaryColor,
                        foregroundColor: DesignTokens.foregroundColor,
                        padding: DesignTokens.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                        elevation: DesignTokens.buttonElevation,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.addMoreItems),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.gridSpacing),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.disabledTextColor,
                        foregroundColor: DesignTokens.foregroundColor,
                        padding: DesignTokens.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                        elevation: DesignTokens.buttonElevation,
                      ),
                      onPressed: clearCart,
                      child: Text(loc.clearCart),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.gridSpacing),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                  foregroundColor: DesignTokens.foregroundColor,
                  padding: DesignTokens.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  elevation: DesignTokens.buttonElevation,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckoutScreen(),
                    ),
                  );
                },
                child: Text(loc.proceedToCheckout),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


