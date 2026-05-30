import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/src/core/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/core/models/favorite_order.dart';
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
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;

    final cartStream = firestoreService.getCart(_userId!,
        franchiseId: franchiseId != 'unknown' ? franchiseId : null);
    final cartSnapshot = await cartStream.first;
    var cart = cartSnapshot ??
        shared.Order(
          id: _userId!,
          userId: _userId!,
          storeId: franchiseId,
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
        cart.items[idx] = existing.copyWith(
            quantity: (existing.quantity + favItem.quantity).toInt());
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
          style: TextStyle(
            color: UiConfig.textColor,
            fontFamily: DesignTokens.fontFamily,
            fontWeight: UiConfig.normal,
          ),
        ),
        backgroundColor: UiConfig.surfaceColor,
        duration: Duration(seconds: DesignTokens.toastDurationSeconds),
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
            style: TextStyle(
              fontSize: DesignTokens.titleFontSize,
              color: UiConfig.foregroundColor,
              fontWeight: UiConfig.bold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          backgroundColor: UiConfig.primaryColor,
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: UiConfig.foregroundColor),
        ),
        backgroundColor: UiConfig.backgroundColor,
        body: Center(
          child: Text(
            localizations.mustSignInForFavorites,
            style: TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: UiConfig.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: UiConfig.normal,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.favorites,
          style: TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: UiConfig.foregroundColor,
            fontWeight: UiConfig.bold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: UiConfig.foregroundColor,
          labelColor: UiConfig.foregroundColor,
          unselectedLabelColor: UiConfig.secondaryTextColor,
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
      backgroundColor: UiConfig.backgroundColor,
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
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;

    return StreamBuilder<List<shared.MenuItem>>(
      stream: firestoreService.getFavoriteMenuItemsForUser(userId,
          franchiseId: franchiseId != 'unknown' ? franchiseId : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              localizations.noFavoriteMenuItems,
              style: TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: UiConfig.textColor,
                fontFamily: DesignTokens.fontFamily,
                fontWeight: UiConfig.normal,
              ),
            ),
          );
        }
        return Padding(
          padding: UiConfig.cardPadding,
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
                color: UiConfig.surfaceColor,
                child: ListTile(
                  leading: NetworkImageWidget(
                    imageUrl: item.image ?? '',
                    fallbackAsset: shared.BrandingConfig.defaultPizzaIcon,
                    width: DesignTokens.menuItemImageWidth,
                    height: DesignTokens.menuItemImageHeight,
                    fit: BoxFit.cover,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.imageRadius),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: UiConfig.textColor,
                      fontWeight: UiConfig.bold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  subtitle: Text(
                    item.description,
                    style: TextStyle(
                      fontSize: DesignTokens.captionFontSize,
                      color: UiConfig.secondaryTextColor,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: UiConfig.normal,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: UiConfig.errorColor,
                    ),
                    tooltip: localizations.removeFromFavoritesTooltip,
                    onPressed: () async {
                      await firestoreService.removeFavoriteMenuItemForUser(
                          userId, item.id,
                          franchiseId:
                              franchiseId != 'unknown' ? franchiseId : null);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.removeFromFavoritesTooltip,
                            style: TextStyle(
                              color: UiConfig.textColor,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: UiConfig.normal,
                            ),
                          ),
                          backgroundColor: UiConfig.surfaceColor,
                          duration: Duration(
                              seconds: DesignTokens.toastDurationSeconds),
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
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final parentState =
        context.findAncestorStateOfType<_FavoritesScreenState>();

    return StreamBuilder<List<shared.Order>>(
      stream: firestoreService.getFavoriteOrdersForUser(userId,
          franchiseId: franchiseId != 'unknown' ? franchiseId : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Text(
              localizations.noFavoriteOrdersSaved,
              style: TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                color: UiConfig.textColor,
                fontFamily: DesignTokens.fontFamily,
                fontWeight: UiConfig.normal,
              ),
            ),
          );
        }
        return Padding(
          padding: UiConfig.cardPadding,
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
                color: UiConfig.surfaceColor,
                child: ListTile(
                  leading:
                      Icon(Icons.receipt_long, color: UiConfig.secondaryColor),
                  title: Text(
                    order.userName ?? 'Order',
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: UiConfig.textColor,
                      fontWeight: UiConfig.bold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  subtitle: Text(
                    localizations.favoriteOrderItems(
                      order.items.map((e) => e.name).join(', '),
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.captionFontSize,
                      color: UiConfig.secondaryTextColor,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: UiConfig.normal,
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.replay,
                          color: UiConfig.primaryColor,
                        ),
                        tooltip: localizations.reorder,
                        onPressed: () {
                          parentState?._reorderFavorite(FavoriteOrder(
                            id: order.id,
                            name: order.userName ?? '',
                            items: order.items,
                            timestamp: order.timestamp,
                          ));
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: UiConfig.errorColor,
                        ),
                        tooltip: localizations.remove,
                        onPressed: () async {
                          await firestoreService.removeFavoriteOrderForUser(
                              userId, order.id,
                              franchiseId: franchiseId != 'unknown'
                                  ? franchiseId
                                  : null);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.removeFavorite,
                                style: TextStyle(
                                  color: UiConfig.textColor,
                                  fontFamily: DesignTokens.fontFamily,
                                  fontWeight: UiConfig.normal,
                                ),
                              ),
                              backgroundColor: UiConfig.surfaceColor,
                              duration: Duration(
                                  seconds: DesignTokens.toastDurationSeconds),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    parentState?._reorderFavorite(FavoriteOrder(
                      id: order.id,
                      name: order.userName ?? '',
                      items: order.items,
                      timestamp: order.timestamp,
                    ));
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
