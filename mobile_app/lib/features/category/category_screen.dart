import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/src/core/config/app_config.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/services/analytics_service.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:franchise_mobile_app/features/ordering/cart_screen.dart';
import 'package:franchise_mobile_app/widgets/menu_item_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/header/cart_icon_badge.dart'; // For cart badge, if you wish to use it
import 'package:franchise_mobile_app/widgets/header/profile_icon_button.dart';
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/widgets/loading_shimmer_widget.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
import 'package:franchise_mobile_app/widgets/filter_dropdown.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId; // Firestore document ID for the category
  final String categoryName; // Human-friendly display name

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
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
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

  /// Handles adding to cart (receives all selected customizations as Map<String, dynamic>)
  void _handleAddToCart(
      MenuItem item,
      Map<String, dynamic> selectedCustomizations,
      int quantity,
      double totalPrice) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.logInToOrder)),
      );
      return;
    }

    var cart = await firestoreService.getCart(user.uid).first;
    cart ??= order_model.Order(
      id: user.uid,
      userId: user.uid,
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      deliveryFee: 0.0,
      discount: 0.0,
      total: 0.0,
      deliveryType: 'pickup',
      time: '',
      status: "cart",
      timestamp: DateTime.now(),
      estimatedTime: 0,
      timestamps: {},
      address: null,
    );

    // -- Match on item id, price, AND selected customizations for cart grouping --
    final existingIndex = cart.items.indexWhere((cartItem) =>
        cartItem.menuItemId == item.id &&
        cartItem.price == totalPrice / quantity && // match effective unit price
        _customizationsMatch(cartItem.customizations, selectedCustomizations));

    if (existingIndex != -1) {
      cart.items[existingIndex] = cart.items[existingIndex].copyWith(
        quantity: cart.items[existingIndex].quantity + quantity,
      );
    } else {
      cart.items.add(order_model.OrderItem(
        menuItemId: item.id,
        name: item.name,
        price: totalPrice / quantity,
        quantity: quantity,
        customizations: selectedCustomizations,
        image: item.image,
      ));
    }

    await firestoreService.updateCart(cart);
    analytics.logMenuItemAddedToCart(item.id, widget.categoryName, quantity);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.addedToCartMessage),
        duration: AppConfig.toastDuration,
      ),
    );
  }

  /// Compare two customizations (for cart grouping)
  bool _customizationsMatch(dynamic a, dynamic b) {
    // You may want to implement a robust comparison depending on structure
    return a.toString() == b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    _sortOptions = _sortOptions.isNotEmpty
        ? _sortOptions
        : [loc.sortByPopularity, loc.sortByPrice, loc.sortByName];
    _sortBy = _sortBy.isNotEmpty ? _sortBy : _sortOptions.first;

    // Choose Firestore orderBy field if any sort is selected (except popularity which is stubbed)
    String? orderByField;
    if (_sortBy == loc.sortByPrice) orderByField = 'price';
    if (_sortBy == loc.sortByName) orderByField = 'name';

    // print('[DEBUG] CategoryScreen loading category: ${widget.categoryName}');
    // print('[DEBUG] Loading categoryId: ${widget.categoryId}');

    return Scaffold(
      appBar: FranchiseAppBar(
        title: widget.categoryName,
        actions: [
          ProfileIconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: loc.profile, // Ensure this exists in your localization
          ),
          CartIconBadge(
            cartItemCountStream: Provider.of<FirestoreService>(context,
                    listen: false)
                .getCartItemCountStream(FirebaseAuth.instance.currentUser?.uid),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            tooltip: loc.cartTooltip,
          ),
          const SizedBox(width: 10), // Spacing between icons
        ],
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: StreamBuilder<List<MenuItem>>(
        stream: firestoreService.getMenuItemsByCategory(
          widget.categoryId,
          sortBy: orderByField,
        ),
        builder: (context, snapshot) {
          // print(
          //     '[DEBUG] Stream event: hasData=${snapshot.hasData}, data=${snapshot.data}, error=${snapshot.error}');
          // print('[DEBUG] StreamBuilder snapshot data: ${snapshot.data}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }

          if (snapshot.hasError) {
            return EmptyStateWidget(
              title: loc.menuLoadError,
              iconData: Icons.error_outline,
              // You can add message: "Something went wrong." if desired
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return EmptyStateWidget(
              title: loc.emptyStateMessage,
              imageAsset:
                  null, // Will use default or set a specific image if you prefer
            );
          }

          return Column(
            children: [
              // --- Sort Dropdown ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                child: ListView.builder(
                  padding: DesignTokens.gridPadding,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MenuItemCard(
                      menuItem: item,
                      showDescription: true,
                      expanded: true,
                      onAddToCart: (
                        menuItem,
                        selectedCustomizations,
                        quantity,
                        totalPrice,
                      ) {
                        _handleAddToCart(menuItem, selectedCustomizations,
                            quantity, totalPrice);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
