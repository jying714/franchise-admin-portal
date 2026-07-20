import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
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

  Map<String, Map<String, shared.Customization>>
      _menuItemCustomizationObjectMap(
    List<shared.OrderItem> items,
    List<shared.MenuItem> menuItems,
  ) {
    final map = <String, Map<String, shared.Customization>>{};
    for (final item in items) {
      final menu = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => shared.MenuItem(
          id: item.menuItemId,
          category: '',
          categoryId: '',
          name: '',
          price: 0,
          description: '',
          customizationGroups: [],
          customizations: [],
          taxCategory: '',
          available: true,
          availability: true,
        ),
      );
      final customObjMap = <String, shared.Customization>{};
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
    List<shared.OrderItem> items,
    List<shared.MenuItem> menuItems,
  ) {
    final ids = <String>{};
    for (final item in items) {
      final menu = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => shared.MenuItem(
          id: item.menuItemId,
          category: '',
          categoryId: '',
          name: '',
          price: 0,
          description: '',
          customizationGroups: [],
          customizations: [],
          taxCategory: '',
          available: true,
          availability: true,
        ),
      );
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
      if (item.customizations != null &&
          item.customizations['selectedAddOns'] != null) {
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
    List<shared.OrderItem> items,
    List<shared.MenuItem> menuItems,
    List<shared.IngredientMetadata> ingredientMetadatas,
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
    Map<String, shared.Customization> customObjMap,
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
                fontWeight: shared.UiConfig.fontWeightNormal,
                color: shared.UiConfig.secondaryTextColor,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ));
            optionWidgets.add(const TextSpan(text: ', '));
          }
          if (optionWidgets.isNotEmpty) optionWidgets.removeLast();
          rows.add(RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$displayName: ',
                  style: TextStyle(
                    fontWeight: shared.UiConfig.fontWeightBold,
                    color: shared.UiConfig.secondaryTextColor,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                ...optionWidgets,
              ],
            ),
          ));
        } else if (selection is bool && selection) {
          final upcharge = (custom?.price ?? 0) > 0
              ? ' (+${loc.currencyFormat(custom!.price)})'
              : '';
          rows.add(Text(
            '$displayName$upcharge',
            style: TextStyle(
              fontSize: shared.DesignTokens.captionFontSize,
              color: shared.UiConfig.secondaryTextColor,
              fontWeight: shared.UiConfig.fontWeightMedium,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ));
        }
      });
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: rows);
    } else if (customizations is List) {
      final joined = customizations.join(', ');
      return Text(
        joined.substring(0, min(50, joined.length)),
        style: TextStyle(
          fontSize: shared.DesignTokens.captionFontSize,
          color: shared.UiConfig.secondaryTextColor,
          fontWeight: shared.UiConfig.fontWeightMedium,
          fontFamily: shared.DesignTokens.fontFamily,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: FranchiseAppBar(
        title: loc.cart,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
      ),
      backgroundColor: shared.UiConfig.backgroundColor,
      body: Consumer<shared.FranchiseProvider>(
        builder: (context, provider, child) {
          final user = FirebaseAuth.instance.currentUser;

          if (!provider.hasValidFranchise) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return Center(
              child: Text(
                loc.mustSignInForCart,
                style: TextStyle(
                  fontSize: shared.DesignTokens.bodyFontSize,
                  color: shared.UiConfig.textColor,
                  fontFamily: shared.DesignTokens.fontFamily,
                  fontWeight: shared.UiConfig.fontWeightMedium,
                ),
              ),
            );
          }

          return StreamBuilder<shared.Order?>(
            key: retryKey,
            stream: firestoreService.getCart(
              user.uid,
              franchiseId: provider.currentFranchiseId,
            ),
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
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          color: shared.UiConfig.errorColor,
                          fontFamily: shared.DesignTokens.fontFamily,
                          fontWeight: shared.UiConfig.fontWeightMedium,
                        ),
                      ),
                      const SizedBox(
                          height: shared.DesignTokens.gridSpacing * 2),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: shared.UiConfig.primaryColor,
                          foregroundColor: shared.UiConfig.foregroundColorDark,
                          padding: shared.UiConfig.defaultPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                shared.DesignTokens.buttonRadius),
                          ),
                        ),
                        onPressed: () => setState(() => retryKey = UniqueKey()),
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

              return StreamBuilder<List<shared.MenuItem>>(
                stream: firestoreService.getMenuItemsByIds(
                  provider.currentFranchiseId,
                  cart.items.map((i) => i.menuItemId).toList(),
                ),
                builder: (context, menuSnapshot) {
                  final menuItems = menuSnapshot.data ?? [];
                  final objMap =
                      _menuItemCustomizationObjectMap(cart.items, menuItems);

                  return FutureBuilder<List<shared.IngredientMetadata>>(
                    future: firestoreService
                        .getAllIngredientMetadata(provider.currentFranchiseId),
                    builder: (context, ingredientSnapshot) {
                      final ingredientMetadatas = ingredientSnapshot.data ?? [];
                      final allAllergens = _allAllergensInCart(
                          cart.items, menuItems, ingredientMetadatas);
                      final showAllergenWarning = allAllergens.isNotEmpty;

                      return AnimatedSwitcher(
                        duration: Duration(
                            milliseconds:
                                shared.DesignTokens.animationDurationMs),
                        child: Column(
                          children: [
                            if (showAllergenWarning)
                              Container(
                                width: double.infinity,
                                margin: shared.UiConfig.defaultPadding,
                                padding: shared.UiConfig.defaultPadding,
                                decoration: BoxDecoration(
                                  color: shared.UiConfig.errorColor
                                      .withOpacity(0.11),
                                  borderRadius: BorderRadius.circular(
                                      shared.DesignTokens.cardRadius),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: shared.UiConfig.errorColor,
                                        size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${loc.warning}: ${loc.itemsInCartCouldContain}\n${allAllergens.join(", ")}',
                                        style: TextStyle(
                                          color: shared.UiConfig.errorColor,
                                          fontWeight:
                                              shared.UiConfig.fontWeightBold,
                                          fontFamily:
                                              shared.DesignTokens.fontFamily,
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

  // buildEmptyState and buildCartContent remain unchanged (kept for brevity)
  Widget buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            loc.yourCartIsEmpty,
            style: TextStyle(
              fontSize: shared.DesignTokens.bodyFontSize,
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing * 2),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: shared.UiConfig.secondaryColor,
              foregroundColor: shared.UiConfig.foregroundColorDark,
              padding: shared.UiConfig.defaultPadding,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(shared.DesignTokens.buttonRadius)),
              elevation: shared.DesignTokens.buttonElevation,
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
    shared.Order cart,
    shared.FirestoreService firestoreService,
    AppLocalizations loc,
    Map<String, Map<String, shared.Customization>> objMap,
  ) {
    Future<void> updateCart(shared.Order updatedCart) async {
      await firestoreService.updateCart(updatedCart);
    }

    void removeItem(int index) async {
      final updatedItems = List<shared.OrderItem>.from(cart.items)
        ..removeAt(index);
      final updatedCart = cart.copyWith(items: updatedItems);
      await updateCart(updatedCart);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.itemRemovedFromCart,
            style: TextStyle(
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
          backgroundColor: shared.UiConfig.surfaceColor,
          duration:
              const Duration(seconds: shared.DesignTokens.toastDurationSeconds),
        ),
      );
    }

    void clearCart() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            loc.clearCart,
            style: TextStyle(
              fontWeight: shared.UiConfig.fontWeightBold,
              color: shared.UiConfig.primaryColor,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          content: Text(
            loc.clearCartConfirmation,
            style: TextStyle(
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: shared.UiConfig.disabledTextColor,
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
                      style: TextStyle(
                        color: shared.UiConfig.errorColor,
                        fontFamily: shared.DesignTokens.fontFamily,
                        fontWeight: shared.UiConfig.fontWeightMedium,
                      ),
                    ),
                    backgroundColor: shared.UiConfig.surfaceColor,
                    duration: const Duration(
                        seconds: shared.DesignTokens.toastDurationSeconds),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: shared.UiConfig.primaryColor,
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
            padding: shared.UiConfig.defaultPadding,
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              final customMap = objMap[item.menuItemId] ?? {};
              return Card(
                elevation: shared.DesignTokens.cardElevation,
                margin: const EdgeInsets.symmetric(
                    vertical: shared.DesignTokens.gridSpacing / 2),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(shared.DesignTokens.cardRadius),
                ),
                color: shared.UiConfig.surfaceColor,
                child: ListTile(
                  leading: NetworkImageWidget(
                    imageUrl: item.image ?? '',
                    fallbackAsset: shared.UiConfig
                        .defaultPizzaIcon, // Updated via shared.UiConfig
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    borderRadius:
                        BorderRadius.circular(shared.DesignTokens.imageRadius),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.bodyFontSize,
                      color: shared.UiConfig.textColor,
                      fontFamily: shared.DesignTokens.fontFamily,
                      fontWeight: shared.UiConfig.fontWeightMedium,
                    ),
                  ),
                  subtitle:
                      renderCustomizations(item.customizations, customMap, loc),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          color: shared.UiConfig.textColor,
                          fontWeight: shared.UiConfig.fontWeightMedium,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: shared.UiConfig.errorColor,
                          size: shared.DesignTokens.iconSize,
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
          padding: shared.UiConfig.defaultPadding.copyWith(
            bottom: shared.UiConfig.defaultPadding.bottom +
                32, // extra padding for S25 system navigation bar
          ),
          child: Column(
            children: [
              Text(
                '${loc.total}: \$${cart.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: shared.DesignTokens.titleFontSize,
                  fontWeight: shared.UiConfig.fontWeightBold,
                  color: shared.UiConfig.textColor,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(height: shared.DesignTokens.gridSpacing),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shared.UiConfig.secondaryColor,
                        foregroundColor: shared.UiConfig.foregroundColorDark,
                        padding: shared.UiConfig.defaultPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              shared.DesignTokens.buttonRadius),
                        ),
                        elevation: shared.DesignTokens.buttonElevation,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.addMoreItems),
                    ),
                  ),
                  const SizedBox(width: shared.DesignTokens.gridSpacing),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shared.UiConfig.disabledTextColor,
                        foregroundColor: shared.UiConfig.foregroundColorDark,
                        padding: shared.UiConfig.defaultPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              shared.DesignTokens.buttonRadius),
                        ),
                        elevation: shared.DesignTokens.buttonElevation,
                      ),
                      onPressed: clearCart,
                      child: Text(loc.clearCart),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: shared.DesignTokens.gridSpacing),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: shared.UiConfig.primaryColor,
                  foregroundColor: shared.UiConfig.foregroundColorDark,
                  padding: shared.UiConfig.defaultPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(shared.DesignTokens.buttonRadius),
                  ),
                  elevation: shared.DesignTokens.buttonElevation,
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
