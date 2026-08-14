import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/features/ordering/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/widgets/customization/customization_modal.dart';

class _CartLineSheetModel {
  _CartLineSheetModel({
    required this.workingItem,
    required this.workingItems,
  }) : qty = workingItem.quantity;

  shared.OrderItem workingItem;
  List<shared.OrderItem> workingItems;
  int qty;
  bool busy = false;
}

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
    ColorScheme scheme, {
    Map<String, String> ingredientNames = const {},
  }) {
    String nameOf(String id) =>
        ingredientNames[id] ?? customObjMap[id]?.name ?? id;

    Widget modRow(String label, List<String> values) {
      if (values.isEmpty) return const SizedBox.shrink();
      final shown = values.take(6).toList();
      final extra = values.length - shown.length;
      final valueText =
          extra > 0 ? '${shown.join(', ')} +$extra more' : shown.join(', ');
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(
                  fontSize: shared.DesignTokens.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              TextSpan(
                text: valueText,
                style: TextStyle(
                  fontSize: shared.DesignTokens.captionFontSize,
                  fontWeight: shared.UiConfig.fontWeightMedium,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (customizations == null ||
        (customizations is List && customizations.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (customizations is Map) {
      final map = Map<String, dynamic>.from(customizations);
      final rows = <Widget>[];

      final size = map['size']?.toString();
      if (size != null && size.isNotEmpty) {
        rows.add(modRow('Size', [size]));
      }

      final structural = <String>[];
      for (final key in ['cook', 'crust', 'cut', 'Cook', 'Crust', 'Cut']) {
        final v = map[key]?.toString();
        if (v == null || v.isEmpty) continue;
        final pretty = key[0].toUpperCase() + key.substring(1).toLowerCase();
        structural.add('$pretty ${nameOf(v)}');
      }
      if (structural.isNotEmpty) {
        rows.add(modRow('Details', structural));
      }

      final current = map['currentIngredients'];
      if (current is List && current.isNotEmpty) {
        final opts = map['ingredientOptions'];
        final parts = <String>[];
        for (final raw in current) {
          final id = raw.toString();
          if (id.isEmpty) continue;
          var label = nameOf(id);
          if (opts is Map && opts[id] is Map) {
            final o = Map<String, dynamic>.from(opts[id] as Map);
            if (o['double'] == true) label = 'Dbl $label';
            final p = o['portion']?.toString();
            if (p == 'left') label = '$label (L)';
            if (p == 'right') label = '$label (R)';
          }
          parts.add(label);
        }
        if (parts.isNotEmpty) {
          rows.add(modRow('Toppings', parts));
        }
      }

      final cheeses = map['cheeses'];
      if (cheeses is List && cheeses.isNotEmpty) {
        final cheeseOpts = map['cheeseOptions'];
        final parts = <String>[];
        for (final raw in cheeses) {
          final id = raw.toString();
          var label = nameOf(id);
          if (cheeseOpts is Map && cheeseOpts[id] is Map) {
            final o = Map<String, dynamic>.from(cheeseOpts[id] as Map);
            if (o['double'] == true) label = 'Dbl $label';
            final p = o['portion']?.toString();
            if (p == 'left') label = '$label (L)';
            if (p == 'right') label = '$label (R)';
          }
          parts.add(label);
        }
        if (parts.isNotEmpty) {
          rows.add(modRow('Cheese', parts));
        }
      }

      final sauce = map['sauce'];
      if (sauce is List && sauce.isNotEmpty) {
        final parts = <String>[];
        for (final s in sauce) {
          if (s is! Map) continue;
          final id = s['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          var label = nameOf(id);
          final p = s['portion']?.toString();
          if (p == 'left') label = '$label (L)';
          if (p == 'right') label = '$label (R)';
          final amt = s['amount']?.toString();
          if (amt != null && amt != 'regular') label = '$label · $amt';
          parts.add(label);
        }
        if (parts.isNotEmpty) {
          rows.add(modRow('Sauce', parts));
        }
      }

      final sauces = map['sauces'];
      if (sauces is Map && sauces.isNotEmpty) {
        final parts = sauces.entries
            .where((e) => (e.value is num) && (e.value as num) > 0)
            .map((e) {
          final n = e.value as num;
          final name = nameOf(e.key.toString());
          return n > 1 ? '$name ×${n.toInt()}' : name;
        }).toList();
        if (parts.isNotEmpty) {
          rows.add(modRow('Sauces', parts));
        }
      }

      final dressings = map['dressings'];
      if (dressings is Map && dressings.isNotEmpty) {
        final parts = dressings.entries
            .where((e) => (e.value is num) && (e.value as num) > 0)
            .map((e) {
          final n = e.value as num;
          final name = nameOf(e.key.toString());
          return n > 1 ? '$name ×${n.toInt()}' : name;
        }).toList();
        if (parts.isNotEmpty) {
          rows.add(modRow('Dressings', parts));
        }
      }

      final addOns = map['selectedAddOns'];
      if (addOns is List && addOns.isNotEmpty) {
        final parts = addOns.map((e) => nameOf(e.toString())).toList();
        if (parts.isNotEmpty) {
          rows.add(modRow('Extras', parts));
        }
      }

      final dips = map['dippedSplits'];
      if (dips is List && dips.isNotEmpty) {
        final parts = dips
            .map((e) => e.toString())
            .where((id) => id.isNotEmpty && id != 'plain')
            .map(nameOf)
            .toList();
        if (parts.isNotEmpty) {
          rows.add(modRow('Toss', parts));
        }
      }

      final cups = map['sideDipCups'];
      if (cups is Map && cups.isNotEmpty) {
        final parts = cups.entries
            .where((e) => (e.value is num) && (e.value as num) > 0)
            .map((e) {
          final n = (e.value as num).toInt();
          final name = nameOf(e.key.toString());
          return n > 1 ? '$name ×$n' : name;
        }).toList();
        if (parts.isNotEmpty) {
          rows.add(modRow('Dips', parts));
        }
      }

      if (rows.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        );
      }

      // Legacy group/option map fallback
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
                final portionLabel = opt['portion'] == 'left'
                    ? loc.leftSide
                    : opt['portion'] == 'right'
                        ? loc.rightSide
                        : opt['portion'].toString();
                details += ' ($portionLabel)';
              }
              if ((opt['extra'] ?? false) == true) details += ' (${loc.extra})';
              if ((opt['double'] ?? false) == true) {
                details += ' (${loc.doubleTopping})';
              }
              if ((opt['quantity'] ?? 1) > 1) {
                details += ' x${opt['quantity']}';
              }
            }
            final upcharge = option.price > 0
                ? ' (+${loc.currencyFormat(option.price)})'
                : '';
            optionWidgets.add(TextSpan(
              text: '${option.name}$details$upcharge',
              style: TextStyle(
                fontWeight: shared.UiConfig.fontWeightNormal,
                color: scheme.onSurfaceVariant,
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
                    color: scheme.onSurfaceVariant,
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
              color: scheme.onSurfaceVariant,
              fontWeight: shared.UiConfig.fontWeightMedium,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ));
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
        style: TextStyle(
          fontSize: shared.DesignTokens.captionFontSize,
          color: scheme.onSurfaceVariant,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<shared.FranchiseProvider>(
        builder: (context, provider, child) {
          final user = FirebaseAuth.instance.currentUser;

          if (!provider.hasValidFranchise) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            final scheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.mustSignInForCart,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: shared.DesignTokens.bodyFontSize,
                        color: scheme.onSurface,
                        fontFamily: shared.DesignTokens.fontFamily,
                        fontWeight: shared.UiConfig.fontWeightMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      },
                      child: Text(loc.signIn),
                    ),
                  ],
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
                          color: Theme.of(context).colorScheme.error,
                          fontFamily: shared.DesignTokens.fontFamily,
                          fontWeight: shared.UiConfig.fontWeightMedium,
                        ),
                      ),
                      const SizedBox(
                          height: shared.DesignTokens.gridSpacing * 2),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(
                                      shared.DesignTokens.cardRadius),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${loc.warning}: ${loc.itemsInCartCouldContain}\n${allAllergens.join(", ")}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
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
                                ingredientMetadatas,
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
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing * 2),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
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

  Future<void> _showCartItemSheet({
    required BuildContext context,
    required shared.OrderItem item,
    required int index,
    required shared.Order cart,
    required shared.FirestoreService firestoreService,
    required Map<String, String> ingredientNames,
    required Map<String, shared.Customization> customMap,
    required AppLocalizations loc,
    required ColorScheme scheme,
  }) async {
    final sheetModel = _CartLineSheetModel(
      workingItem: item,
      workingItems: List<shared.OrderItem>.from(cart.items),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
            child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                MediaQuery.of(sheetContext).padding.bottom +
                16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> persistQuantity(int next) async {
                if (next < 1 || sheetModel.busy) return;
                sheetModel.busy = true;
                try {
                  sheetModel.workingItem =
                      sheetModel.workingItem.copyWith(quantity: next);
                  sheetModel.workingItems =
                      List<shared.OrderItem>.from(sheetModel.workingItems);
                  sheetModel.workingItems[index] = sheetModel.workingItem;
                  sheetModel.qty = next;
                  final newSubtotal = sheetModel.workingItems.fold<double>(
                    0,
                    (sum, i) => sum + i.price * i.quantity,
                  );
                  await firestoreService.updateCart(
                    cart.copyWith(
                      items: sheetModel.workingItems,
                      subtotal: newSubtotal,
                      total: newSubtotal +
                          cart.tax +
                          cart.deliveryFee -
                          (cart.discount ?? 0.0),
                    ),
                  );
                  if (context.mounted) {
                    setSheetState(() {});
                  }
                } finally {
                  sheetModel.busy = false;
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NetworkImageWidget(
                        imageUrl: item.image ?? '',
                        fallbackAsset: shared.UiConfig.defaultPizzaIcon,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.imageRadius),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: shared.DesignTokens.titleFontSize,
                                fontWeight: shared.UiConfig.fontWeightBold,
                                color: scheme.onSurface,
                                fontFamily: shared.DesignTokens.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${(sheetModel.workingItem.price * sheetModel.qty).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: shared.DesignTokens.bodyFontSize,
                                fontWeight: shared.UiConfig.fontWeightMedium,
                                color: scheme.onSurface,
                                fontFamily: shared.DesignTokens.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your selections',
                    style: TextStyle(
                      fontSize: shared.DesignTokens.bodyFontSize,
                      fontWeight: shared.UiConfig.fontWeightBold,
                      color: scheme.onSurface,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Full detail: reuse renderer without truncation pressure
                  renderCustomizations(
                    item.customizations,
                    customMap,
                    loc,
                    scheme,
                    ingredientNames: ingredientNames,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight: shared.UiConfig.fontWeightMedium,
                          color: scheme.onSurface,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: sheetModel.qty > 1
                            ? () => persistQuantity(sheetModel.qty - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '${sheetModel.qty}',
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          fontWeight: shared.UiConfig.fontWeightBold,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                      IconButton(
                        onPressed: () => persistQuantity(sheetModel.qty + 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            final menu = await firestoreService.getMenuItemById(
                              item.menuItemId,
                              franchiseId: cart.storeId,
                            );
                            if (menu == null || !context.mounted) return;

                            await showDialog<void>(
                              context: context,
                              builder: (ctx) => CustomizationModal(
                                menuItem: menu,
                                ingredientMetadata: null,
                                initialQuantity: item.quantity,
                                initialCustomizations:
                                    Map<String, dynamic>.from(
                                  item.customizations,
                                ),
                                onConfirm: (customizations, quantity,
                                    totalPrice) async {
                                  final updatedItems =
                                      List<shared.OrderItem>.from(cart.items);
                                  updatedItems[index] = item.copyWith(
                                    quantity: quantity,
                                    price: totalPrice / quantity,
                                    customizations: Map<String, dynamic>.from(
                                        customizations),
                                  );
                                  final newSubtotal = updatedItems.fold<double>(
                                    0,
                                    (sum, i) => sum + i.price * i.quantity,
                                  );
                                  await firestoreService.updateCart(
                                    cart.copyWith(
                                      items: updatedItems,
                                      subtotal: newSubtotal,
                                      total: newSubtotal +
                                          cart.tax +
                                          cart.deliveryFee -
                                          (cart.discount ?? 0.0),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            side: BorderSide(color: scheme.error),
                          ),
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            final updatedItems = List<shared.OrderItem>.from(
                                sheetModel.workingItems)
                              ..removeAt(index);
                            final newSubtotal = updatedItems.fold<double>(
                              0,
                              (sum, i) => sum + i.price * i.quantity,
                            );
                            await firestoreService.updateCart(
                              cart.copyWith(
                                items: updatedItems,
                                subtotal: newSubtotal,
                                total: newSubtotal +
                                    cart.tax +
                                    cart.deliveryFee -
                                    (cart.discount ?? 0.0),
                              ),
                            );
                          },
                          child: Text(loc.removeItem),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ));
      },
    );
  }

  Widget buildCartContent(
    BuildContext context,
    shared.Order cart,
    shared.FirestoreService firestoreService,
    AppLocalizations loc,
    Map<String, Map<String, shared.Customization>> objMap,
    List<shared.IngredientMetadata> ingredientMetadatas,
  ) {
    final scheme = Theme.of(context).colorScheme;

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
              color: scheme.onSurface,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
          backgroundColor: scheme.surface,
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
              color: scheme.onSurface,
              fontFamily: shared.DesignTokens.fontFamily,
            ),
          ),
          content: Text(
            loc.clearCartConfirmation,
            style: TextStyle(
              color: scheme.onSurface,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
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
                        color: scheme.error,
                        fontFamily: shared.DesignTokens.fontFamily,
                        fontWeight: shared.UiConfig.fontWeightMedium,
                      ),
                    ),
                    backgroundColor: scheme.surface,
                    duration: const Duration(
                        seconds: shared.DesignTokens.toastDurationSeconds),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
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
              final ingredientNames = {
                for (final m in ingredientMetadatas) m.id: m.name,
              };
              return Card(
                elevation: shared.DesignTokens.cardElevation,
                margin: const EdgeInsets.symmetric(
                    vertical: shared.DesignTokens.gridSpacing / 2),
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(shared.DesignTokens.cardRadius),
                  side: BorderSide(color: scheme.outline),
                ),
                child: ListTile(
                  onTap: () => _showCartItemSheet(
                    context: context,
                    item: item,
                    index: index,
                    cart: cart,
                    firestoreService: firestoreService,
                    ingredientNames: ingredientNames,
                    customMap: customMap,
                    loc: loc,
                    scheme: scheme,
                  ),
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
                    item.quantity > 1
                        ? '${item.name}  ×${item.quantity}'
                        : item.name,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.bodyFontSize,
                      color: scheme.onSurface,
                      fontFamily: shared.DesignTokens.fontFamily,
                      fontWeight: shared.UiConfig.fontWeightMedium,
                    ),
                  ),
                  subtitle: renderCustomizations(
                    item.customizations,
                    customMap,
                    loc,
                    scheme,
                    ingredientNames: {
                      for (final m in ingredientMetadatas) m.id: m.name,
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          color: scheme.onSurface,
                          fontWeight: shared.UiConfig.fontWeightMedium,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: scheme.error,
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
                  color: scheme.onSurface,
                  fontFamily: shared.DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(height: shared.DesignTokens.gridSpacing),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.outline),
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
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
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
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: shared.UiConfig.defaultPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(shared.DesignTokens.buttonRadius),
                  ),
                  elevation: shared.DesignTokens.buttonElevation,
                ),
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignInScreen(),
                      ),
                    );
                    return;
                  }
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
