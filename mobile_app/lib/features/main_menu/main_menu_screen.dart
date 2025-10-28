// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart' as material hide Banner, BannerLocation;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doughboys_pizzeria_final/widgets/header/cart_icon_badge.dart';
import 'package:doughboys_pizzeria_final/config/app_config.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/services/analytics_service.dart';
import 'package:doughboys_pizzeria_final/core/models/banner.dart';
import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:doughboys_pizzeria_final/core/models/order.dart' as order_model;
import 'package:doughboys_pizzeria_final/core/models/category.dart';
import 'package:doughboys_pizzeria_final/features/category/category_screen.dart';
import 'package:doughboys_pizzeria_final/features/ordering/cart_screen.dart';
import 'package:doughboys_pizzeria_final/features/user_accounts/profile_screen.dart';
import 'package:doughboys_pizzeria_final/features/menu/item_screen.dart';
import 'package:doughboys_pizzeria_final/widgets/header/franchise_app_bar.dart';
import 'package:doughboys_pizzeria_final/widgets/network_image_widget.dart';
import 'package:doughboys_pizzeria_final/widgets/header/profile_icon_button.dart';
import 'package:doughboys_pizzeria_final/widgets/banner/banner_carousel.dart';
import 'package:doughboys_pizzeria_final/widgets/banner/banner_action_handler.dart';
import 'package:doughboys_pizzeria_final/widgets/categories/category_grid.dart';
import 'package:doughboys_pizzeria_final/widgets/empty_state_widget.dart';
import 'package:doughboys_pizzeria_final/widgets/loading_shimmer_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainMenuScreen extends material.StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  material.Widget build(material.BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: DesignTokens.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:
            Platform.isIOS ? Brightness.dark : Brightness.light,
      ),
    );

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final analyticsService =
        Provider.of<AnalyticsService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final loc = AppLocalizations.of(context)!;

    final cartItemCountStream = firestoreService
        .getCart(userId)
        .map((order) => order?.items.length ?? 0);

    return material.Scaffold(
      appBar: FranchiseAppBar(
        title: 'Menu Categories',
        centerTitle: true,
        actions: [
          ProfileIconButton(
            tooltip: loc.profile,
            onPressed: () => material.Navigator.push(
              context,
              material.MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          CartIconBadge(
            cartItemCountStream: cartItemCountStream,
            tooltip: loc.cart,
            onPressed: () => material.Navigator.push(
              context,
              material.MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const material.SizedBox(width: DesignTokens.gridSpacing),
        ],
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: material.SafeArea(
        child: material.Column(
          children: [
            // --- Banner Section ---
            material.StreamBuilder<List<Banner>>(
              stream: firestoreService.getBanners(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    material.ConnectionState.waiting) {
                  return const LoadingShimmerWidget(
                    itemCount: 1,
                    cardHeight: 180,
                    cardWidth: double.infinity,
                  );
                }
                if (snapshot.hasError) {
                  return EmptyStateWidget(
                    title: loc.promotionsLoadError,
                    message: loc.tryAgainLater,
                    imageAsset: BrandingConfig.bannerPlaceholder,
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyStateWidget(
                    title: loc.checkBackSoon,
                    message: loc.noPromotionsAvailable,
                    imageAsset: BrandingConfig.bannerPlaceholder,
                  );
                }
                final banners = snapshot.data!.where((b) => b.active).toList();
                if (banners.isEmpty) {
                  return EmptyStateWidget(
                    title: loc.checkBackSoon,
                    message: loc.noPromotionsAvailable,
                    imageAsset: BrandingConfig.bannerPlaceholder,
                  );
                }
                return BannerCarousel(
                  banners: banners,
                  onBannerTap: (banner) {
                    BannerActionHandler.handle(
                      context,
                      banner,
                      analyticsService: analyticsService,
                      loc: loc,
                    );
                  },
                );
              },
            ),
            // --- Category Grid Section ---
            material.Expanded(
              child: material.StreamBuilder<List<Category>>(
                stream: firestoreService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      material.ConnectionState.waiting) {
                    return const LoadingShimmerWidget(
                      itemCount: 6,
                      cardHeight: 160,
                      cardWidth: double.infinity,
                    );
                  }
                  if (snapshot.hasError) {
                    return EmptyStateWidget(
                      title: loc.menuLoadError,
                      message: loc.tryAgainLater,
                      imageAsset: BrandingConfig.defaultCategoryIcon,
                    );
                  }
                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return EmptyStateWidget(
                      title: loc.noCategoriesAvailable,
                      message: loc.checkBackSoon,
                      imageAsset: BrandingConfig.defaultCategoryIcon,
                    );
                  }
                  return CategoryGrid(
                    categories: categories,
                    onCategoryTap: (category) {
                      analyticsService.logCategoryTap(category.name);
                      material.Navigator.push(
                        context,
                        material.MaterialPageRoute(
                          builder: (_) => CategoryScreen(
                            categoryId: category.id,
                            categoryName: category.name,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
