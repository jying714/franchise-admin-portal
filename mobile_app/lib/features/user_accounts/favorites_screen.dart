import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:shared_core/src/core/models/favorite_order.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
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
            color: shared.UiConfig.textColor,
            fontFamily: shared.DesignTokens.fontFamily,
            fontWeight: shared.UiConfig.normal,
          ),
        ),
        backgroundColor: shared.UiConfig.surfaceColor,
        duration: Duration(seconds: shared.DesignTokens.toastDurationSeconds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_userId == null) {
      return Scaffold(
        appBar: FranchiseAppBar(
          title: localizations.favorites,
          showLogo: false,
          centerTitle: true,
          elevation: 0,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Text(
              localizations.mustSignInForFavorites,
              style: TextStyle(
                fontSize: shared.DesignTokens.bodyFontSize,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: shared.DesignTokens.fontFamily,
                fontWeight: shared.UiConfig.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: FranchiseAppBar(
        title: localizations.favorites,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            FavoriteMenuItemsTab(userId: _userId!),
            FavoriteOrdersTab(userId: _userId!),
          ],
        ),
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

    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, child) {
        final firestoreService =
            Provider.of<shared.FirestoreService>(context, listen: false);
        final franchiseId = franchiseProvider.currentFranchiseId;
        final fid = franchiseId != 'unknown' ? franchiseId : null;

        return StreamBuilder<List<shared.MenuItem>>(
          stream: firestoreService.getFavoriteMenuItemsForUser(userId,
              franchiseId: fid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  localizations.loyaltyErrorLoading, // reuse generic error
                  style: TextStyle(
                    fontSize: shared.DesignTokens.bodyFontSize,
                    color: Theme.of(context).colorScheme.error,
                    fontFamily: shared.DesignTokens.fontFamily,
                    fontWeight: shared.UiConfig.normal,
                  ),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return EmptyStateWidget(
                title: localizations.noFavoriteMenuItems,
                message: 'Items you favorite will appear here.',
                iconData: Icons.favorite_border,
              );
            }
            return Padding(
              padding: shared.UiConfig.cardPadding,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final scheme = Theme.of(context).colorScheme;
                  return Card(
                    elevation: shared.DesignTokens.cardElevation,
                    margin: const EdgeInsets.symmetric(
                      vertical: shared.DesignTokens.gridSpacing / 2,
                    ),
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(shared.DesignTokens.cardRadius),
                      side: BorderSide(color: scheme.outline),
                    ),
                    child: ListTile(
                      leading: NetworkImageWidget(
                        imageUrl: item.image ?? '',
                        fallbackAsset: shared.BrandingConfig.defaultPizzaIcon,
                        width: shared.DesignTokens.menuItemImageWidth,
                        height: shared.DesignTokens.menuItemImageHeight,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.imageRadius),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          color: scheme.onSurface,
                          fontWeight: shared.UiConfig.bold,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                      subtitle: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: shared.DesignTokens.captionFontSize,
                          color: scheme.onSurfaceVariant,
                          fontFamily: shared.DesignTokens.fontFamily,
                          fontWeight: shared.UiConfig.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: scheme.error,
                        ),
                        tooltip: localizations.removeFromFavoritesTooltip,
                        onPressed: () async {
                          await firestoreService.removeFavoriteMenuItemForUser(
                              userId, item.id,
                              franchiseId: fid);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.removeFromFavoritesTooltip,
                                style: TextStyle(
                                  color: shared.UiConfig.textColor,
                                  fontFamily: shared.DesignTokens.fontFamily,
                                  fontWeight: shared.UiConfig.normal,
                                ),
                              ),
                              backgroundColor: shared.UiConfig.surfaceColor,
                              duration: Duration(
                                  seconds:
                                      shared.DesignTokens.toastDurationSeconds),
                              behavior: SnackBarBehavior.floating,
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
    final parentState =
        context.findAncestorStateOfType<_FavoritesScreenState>();

    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, child) {
        final firestoreService =
            Provider.of<shared.FirestoreService>(context, listen: false);
        final franchiseId = franchiseProvider.currentFranchiseId;
        final fid = franchiseId != 'unknown' ? franchiseId : null;

        return StreamBuilder<List<shared.Order>>(
          stream: firestoreService.getFavoriteOrdersForUser(userId,
              franchiseId: fid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  localizations.loyaltyErrorLoading,
                  style: TextStyle(
                    fontSize: shared.DesignTokens.bodyFontSize,
                    color: Theme.of(context).colorScheme.error,
                    fontFamily: shared.DesignTokens.fontFamily,
                    fontWeight: shared.UiConfig.normal,
                  ),
                ),
              );
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return EmptyStateWidget(
                title: localizations.noFavoriteOrdersSaved,
                message:
                    'Favorite orders will appear here for quick reordering.',
                iconData: Icons.receipt_long,
              );
            }
            return Padding(
              padding: shared.UiConfig.cardPadding,
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final scheme = Theme.of(context).colorScheme;
                  return Card(
                    elevation: shared.DesignTokens.cardElevation,
                    margin: const EdgeInsets.symmetric(
                      vertical: shared.DesignTokens.gridSpacing / 2,
                    ),
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(shared.DesignTokens.cardRadius),
                      side: BorderSide(color: scheme.outline),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.receipt_long, color: scheme.primary),
                      title: Text(
                        order.userName ?? 'Order',
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          color: scheme.onSurface,
                          fontWeight: shared.UiConfig.bold,
                          fontFamily: shared.DesignTokens.fontFamily,
                        ),
                      ),
                      subtitle: Text(
                        localizations.favoriteOrderItems(
                          order.items.map((e) => e.name).join(', '),
                        ),
                        style: TextStyle(
                          fontSize: shared.DesignTokens.captionFontSize,
                          color: scheme.onSurfaceVariant,
                          fontFamily: shared.DesignTokens.fontFamily,
                          fontWeight: shared.UiConfig.normal,
                        ),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.replay,
                              color: scheme.primary,
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
                              color: scheme.error,
                            ),
                            tooltip: localizations.remove,
                            onPressed: () async {
                              await firestoreService.removeFavoriteOrderForUser(
                                  userId, order.id,
                                  franchiseId: fid);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localizations.removeFavorite,
                                    style: TextStyle(
                                      color: shared.UiConfig.textColor,
                                      fontFamily:
                                          shared.DesignTokens.fontFamily,
                                      fontWeight: shared.UiConfig.normal,
                                    ),
                                  ),
                                  backgroundColor: shared.UiConfig.surfaceColor,
                                  duration: Duration(
                                      seconds: shared
                                          .DesignTokens.toastDurationSeconds),
                                  behavior: SnackBarBehavior.floating,
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
      },
    );
  }
}
