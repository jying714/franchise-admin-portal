import 'dart:io';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/widgets/header/cart_icon_badge.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/features/category/category_screen.dart';
import 'package:franchise_mobile_app/features/ordering/cart_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/profile_screen.dart';
import 'package:franchise_mobile_app/features/ordering/qr_scan_screen.dart'; // P2 QR foundations
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/header/profile_icon_button.dart';
import 'package:franchise_mobile_app/widgets/banner/banner_carousel.dart';
import 'package:franchise_mobile_app/widgets/banner/banner_action_handler.dart';
// P1 Batch 1 cross-ref updated: banner/ widgets now use shared.FranchiseProvider + shared.UiConfig (no src/)
// P1 Batch 2: header/ + categories/ updated (FranchiseProvider injection + shared.UiConfig)
import 'package:franchise_mobile_app/widgets/categories/category_grid.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
import 'package:franchise_mobile_app/widgets/loading_shimmer_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainMenuScreen extends material.StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  material.Widget build(material.BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: shared.UiConfig.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:
            Platform.isIOS ? Brightness.dark : Brightness.light,
      ),
    );

    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final analyticsService =
        Provider.of<shared.AnalyticsService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return material.Scaffold(
      appBar: FranchiseAppBar(
        title:
            "Doughboys Pizzeria", // Will be dynamic via Consumer below if needed
        centerTitle: true,
        actions: [
          ProfileIconButton(
            tooltip: loc.profile,
            onPressed: () => material.Navigator.push(
              context,
              material.MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          // P2 QR foundations: scanner entry point in app bar
          material.IconButton(
            icon: const material.Icon(material.Icons.qr_code_scanner),
            tooltip: 'Scan Franchise QR',
            onPressed: () => material.Navigator.push(
              context,
              material.MaterialPageRoute(builder: (_) => const QrScanScreen()),
            ),
          ),
          const CartIconBadge(
            tooltip: 'Cart',
            onPressed: null, // Will be overridden in Consumer
          ),
          const material.SizedBox(width: shared.DesignTokens.gridSpacing),
        ],
      ),
      backgroundColor: shared.UiConfig.backgroundColor,
      body: material.SafeArea(
        child: Consumer<shared.FranchiseProvider>(
          builder: (context, provider, child) {
            if (!provider.hasValidFranchise) {
              return const material.Center(
                  child: material.CircularProgressIndicator());
            }

            final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

            // Override the CartIconBadge onPressed with proper context
            final updatedActions = [
              ProfileIconButton(
                tooltip: loc.profile,
                onPressed: () => material.Navigator.push(
                  context,
                  material.MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                ),
              ),
              // P2 QR button (duplicated for CartIconBadge override context)
              material.IconButton(
                icon: const material.Icon(material.Icons.qr_code_scanner),
                tooltip: 'Scan Franchise QR',
                onPressed: () => material.Navigator.push(
                  context,
                  material.MaterialPageRoute(
                      builder: (_) => const QrScanScreen()),
                ),
              ),
              CartIconBadge(
                tooltip: loc.cart,
                onPressed: () => material.Navigator.push(
                  context,
                  material.MaterialPageRoute(
                      builder: (_) => const CartScreen()),
                ),
              ),
              const material.SizedBox(width: shared.DesignTokens.gridSpacing),
            ];

            return material.Column(
              children: [
                // Banner
                material.StreamBuilder<List<shared.Banner>>(
                  stream: firestoreService.getBanners(
                      franchiseId: provider.currentFranchiseId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        material.ConnectionState.waiting) {
                      return const LoadingShimmerWidget(
                          itemCount: 1, cardHeight: 180);
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return EmptyStateWidget(
                        title: loc.checkBackSoon,
                        message: loc.noPromotionsAvailable,
                        imageAsset: shared.BrandingConfig.bannerPlaceholder,
                      );
                    }
                    final banners =
                        (snapshot.data ?? []).where((b) => b.active).toList();
                    return BannerCarousel(
                      banners: banners,
                      onBannerTap: (banner) => BannerActionHandler.handle(
                        context,
                        banner,
                        analyticsService:
                            analyticsService as shared.AnalyticsService?,
                        loc: loc,
                      ),
                    );
                  },
                ),

                // Categories
                material.Expanded(
                  child: material.StreamBuilder<List<shared.Category>>(
                    stream: firestoreService
                        .getCategories(provider.currentFranchiseId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          material.ConnectionState.waiting) {
                        return const LoadingShimmerWidget(
                            itemCount: 6, cardHeight: 160);
                      }
                      final categories = snapshot.data ?? [];
                      if (categories.isEmpty) {
                        return EmptyStateWidget(
                          title: loc.noCategoriesAvailable,
                          message: loc.checkBackSoon,
                          imageAsset: shared.BrandingConfig.defaultCategoryIcon,
                        );
                      }
                      return CategoryGrid(
                        categories: categories,
                        onCategoryTap: (category) {
                          analyticsService.logCategoryTap(
                            franchiseId: provider.currentFranchiseId,
                            categoryId: category.id,
                            categoryName: category.name,
                          );
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
            );
          },
        ),
      ),
    );
  }
}
