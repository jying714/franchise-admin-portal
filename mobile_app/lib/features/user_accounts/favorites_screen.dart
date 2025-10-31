import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/models/favorite_order.dart';
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'dart:convert';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  String? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Compare customizations deeply (for favorite orders) ---
  bool sameCustomizations(
      List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    final aSorted = List.from(a.map((e) => jsonEncode(e)))..sort();
    final bSorted = List.from(b.map((e) => jsonEncode(e)))..sort();
    for (var i = 0; i < aSorted.length; i++) {
      if (aSorted[i] != bSorted[i]) return false;
    }
    return true;
  }

  Future<void> _reorderFavorite(FavoriteOrder favorite) async {
    if (_userId == null) return;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    order_model.Order? cart = await firestoreService.getCart(_userId!).first;
    cart ??= order_model.Order(
      id: _userId!,
      userId: _userId!,
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      deliveryFee: 0.0,
      discount: 0.0,
      total: 0.0,
      deliveryType: '',
      time: '',
      status: "cart",
      timestamp: DateTime.now(),
      estimatedTime: 0,
      timestamps: {},
      address: null,
    );

    for (final favItem in favorite.items) {
      final idx = cart.items.indexWhere((cartItem) =>
          cartItem.menuItemId == favItem.menuItemId &&
          sameCustomizations(
            [Map<String, dynamic>.from(cartItem.customizations)],
            [Map<String, dynamic>.from(favItem.customizations)],
          ));

      if (idx != -1) {
        final existing = cart.items[idx];
        cart.items[idx] =
            existing.copyWith(quantity: existing.quantity + favItem.quantity);
      } else {
        cart.items.add(favItem.copyWith());
      }
    }

    await firestoreService.updateCart(cart);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.addedToCartMessage,
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.favorites,
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
        body: Center(
          child: Text(
            localizations.mustSignInForFavorites,
            style: const TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
        ),
      );
    }

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.favorites,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.foregroundColor,
          labelColor: DesignTokens.foregroundColor,
          unselectedLabelColor: DesignTokens.secondaryTextColor,
          tabs: [
            Tab(
                text: localizations.menuItems,
                icon: const Icon(Icons.fastfood)),
            Tab(
                text: localizations.orders,
                icon: const Icon(Icons.receipt_long)),
          ],
        ),
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          FavoriteMenuItemsTab(userId: _userId!),
          FavoriteOrdersTab(userId: _userId!),
        ],
      ),
    );
  }
}

class FavoriteMenuItemsTab extends StatelessWidget {
  final String userId;
  const FavoriteMenuItemsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<MenuItem>>(
      stream: firestoreService.getFavoriteMenuItemsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              localizations.noFavoriteMenuItems,
              style: const TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: DesignTokens.textColor,
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.bodyFontWeight,
              ),
            ),
          );
        }
        return Padding(
          padding: DesignTokens.cardPadding,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: DesignTokens.cardElevation,
                margin: const EdgeInsets.symmetric(
                  vertical: DesignTokens.gridSpacing / 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
                color: DesignTokens.surfaceColor,
                child: ListTile(
                  leading: NetworkImageWidget(
                    imageUrl: item.image ?? '',
                    fallbackAsset: BrandingConfig.defaultPizzaIcon,
                    width: DesignTokens.menuItemImageWidth,
                    height: DesignTokens.menuItemImageHeight,
                    fit: BoxFit.cover,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.imageRadius),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: DesignTokens.textColor,
                      fontWeight: DesignTokens.titleFontWeight,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  subtitle: Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: DesignTokens.captionFontSize,
                      color: DesignTokens.secondaryTextColor,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.bodyFontWeight,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: DesignTokens.errorColor,
                    ),
                    tooltip: localizations.removeFromFavoritesTooltip,
                    onPressed: () async {
                      await firestoreService.removeFavoriteMenuItemForUser(
                          userId, item.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.removeFromFavoritesTooltip,
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
                    },
                  ),
                  onTap: () {
                    // Optionally: view details or add to cart
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class FavoriteOrdersTab extends StatelessWidget {
  final String userId;
  const FavoriteOrdersTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final parentState =
        context.findAncestorStateOfType<_FavoritesScreenState>();

    return StreamBuilder<List<FavoriteOrder>>(
      stream: firestoreService.getFavoriteOrdersForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Text(
              localizations.noFavoriteOrdersSaved,
              style: const TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: DesignTokens.textColor,
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.bodyFontWeight,
              ),
            ),
          );
        }
        return Padding(
          padding: DesignTokens.cardPadding,
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: DesignTokens.cardElevation,
                margin: const EdgeInsets.symmetric(
                  vertical: DesignTokens.gridSpacing / 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
                color: DesignTokens.surfaceColor,
                child: ListTile(
                  leading: const Icon(Icons.receipt_long,
                      color: DesignTokens.secondaryColor),
                  title: Text(
                    order.name,
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: DesignTokens.textColor,
                      fontWeight: DesignTokens.titleFontWeight,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  subtitle: Text(
                    localizations.favoriteOrderItems(
                      order.items.map((e) => e.name).join(', '),
                    ),
                    style: const TextStyle(
                      fontSize: DesignTokens.captionFontSize,
                      color: DesignTokens.secondaryTextColor,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.bodyFontWeight,
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.replay,
                          color: DesignTokens.primaryColor,
                        ),
                        tooltip: localizations.reorder,
                        onPressed: () {
                          parentState?._reorderFavorite(order);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: DesignTokens.errorColor,
                        ),
                        tooltip: localizations.remove,
                        onPressed: () async {
                          await firestoreService.removeFavoriteOrderForUser(
                              userId, order);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.removeFavorite,
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
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    parentState?._reorderFavorite(order);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}


