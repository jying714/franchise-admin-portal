import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/features/ordering/cart_screen.dart';
import 'package:franchise_mobile_app/widgets/menu_item_card.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/header/cart_icon_badge.dart';
import 'package:franchise_mobile_app/widgets/header/profile_icon_button.dart';
// Batch 2: header/ widgets updated for FranchiseProvider + UiConfig
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/widgets/loading_shimmer_widget.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
import 'package:franchise_mobile_app/widgets/filter_dropdown.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _sortBy = '';
  List<String> _sortOptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics =
          Provider.of<shared.AnalyticsService>(context, listen: false);
      analytics.logCategoryViewed(widget.categoryName);
      final loc = AppLocalizations.of(context)!;
      setState(() {
        _sortOptions = [
          loc.sortByPopularity,
          loc.sortByPrice,
          loc.sortByName,
        ];
        _sortBy = _sortOptions.first;
      });
    });
  }

  void _handleAddToCart(
      shared.MenuItem item,
      Map<String, dynamic> selectedCustomizations,
      int quantity,
      double totalPrice) async {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final analytics =
        Provider.of<shared.AnalyticsService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.logInToOrder,
              style: TextStyle(
                color: shared.UiConfig.textColor,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
            backgroundColor: shared.UiConfig.surfaceColor,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: loc.signIn,
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    final franchiseId = franchiseProvider.currentFranchiseId;
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Franchise not selected. Please try again.",
              style: TextStyle(color: shared.UiConfig.textColor),
            ),
            backgroundColor: shared.UiConfig.surfaceColor,
            duration:
                Duration(seconds: shared.DesignTokens.toastDurationSeconds),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await firestoreService.addToCart(
        userId: user.uid,
        franchiseId: franchiseId,
        menuItem: item,
        customizations: [], // TODO: Convert selectedCustomizations properly later
        quantity: quantity,
        price: totalPrice / quantity,
      );

      analytics.logMenuItemAddedToCart(item.id, widget.categoryName, quantity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.addedToCartMessage,
              style: TextStyle(
                color: shared.UiConfig.textColor,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
            backgroundColor: shared.UiConfig.surfaceColor,
            duration:
                Duration(seconds: shared.DesignTokens.toastDurationSeconds),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to add to cart",
              style: TextStyle(color: shared.UiConfig.textColor),
            ),
            backgroundColor: shared.UiConfig.surfaceColor,
            duration:
                Duration(seconds: shared.DesignTokens.toastDurationSeconds),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: FranchiseAppBar(
        title: widget.categoryName,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        actions: [
          ProfileIconButton(
            onPressed: () {
              if (FirebaseAuth.instance.currentUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: loc.profile,
          ),
          CartIconBadge(
            tooltip: loc.cartTooltip,
            onPressed: () {
              if (FirebaseAuth.instance.currentUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      backgroundColor: shared.UiConfig.backgroundColor,
      body: SafeArea(
        bottom: true,
        child: Consumer<shared.FranchiseProvider>(
          builder: (context, provider, child) {
            if (!provider.hasValidFranchise) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<List<shared.MenuItem>>(
              stream:
                  Provider.of<shared.FirestoreService>(context, listen: false)
                      .getMenuItemsByCategory(
                widget.categoryId,
                franchiseId: provider.currentFranchiseId,
                sortBy: _sortBy == loc.sortByPrice
                    ? 'price'
                    : _sortBy == loc.sortByName
                        ? 'name'
                        : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingShimmerWidget();
                }

                if (snapshot.hasError) {
                  return EmptyStateWidget(
                    title: "Error Loading Menu Items",
                    message: "Please try again later.",
                    imageAsset: shared.BrandingConfig.defaultCategoryIcon,
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return EmptyStateWidget(
                    title: loc.emptyStateMessage,
                    message: "No menu items found for this category.",
                    imageAsset: shared.BrandingConfig.defaultCategoryIcon,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilterDropdown<String>(
                            label: loc.sortBy,
                            options: _sortOptions,
                            value: _sortBy,
                            onChanged: (val) {
                              if (val != null) setState(() => _sortBy = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          bool hasImage(shared.MenuItem item) =>
                              item.image != null &&
                              item.image!.trim().isNotEmpty;

                          // Preserve stream order (popularity / price / name) within each band.
                          final withImage =
                              items.where(hasImage).toList(growable: false);
                          final reduced = items
                              .where((item) => !hasImage(item))
                              .toList(growable: false);
                          final ordered = <shared.MenuItem>[
                            ...withImage,
                            ...reduced,
                          ];

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: ordered.length,
                            itemBuilder: (context, index) {
                              final item = ordered[index];
                              final isReduced = !hasImage(item);
                              return MenuItemCard(
                                menuItem: item,
                                showDescription: true,
                                expanded: true,
                                reduced: isReduced,
                                isFavorited: null,
                                onAddToCart: (
                                  menuItem,
                                  selectedCustomizations,
                                  quantity,
                                  totalPrice,
                                ) {
                                  _handleAddToCart(
                                    menuItem,
                                    selectedCustomizations,
                                    quantity,
                                    totalPrice,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ), // SafeArea close
    );
  }
}
