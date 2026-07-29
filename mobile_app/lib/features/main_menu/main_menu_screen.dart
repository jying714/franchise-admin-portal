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
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';

class MainMenuScreen extends material.StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  material.State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends material.State<MainMenuScreen> {
  bool _orderExperiencePromptChecked = false;

  @override
  void initState() {
    super.initState();
    material.WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPendingOrderExperienceFeedback();
    });
  }

  Future<void> _maybeShowPendingOrderExperienceFeedback() async {
    if (_orderExperiencePromptChecked || !mounted) return;
    _orderExperiencePromptChecked = true;

    try {
      final storage = AppLocalStorage();
      final raw =
          await storage.getStringAsync('pending_order_experience_feedback');
      if (raw == null || raw.isEmpty) return;

      final parts = raw.split('|');
      if (parts.length < 3) {
        await storage.remove('pending_order_experience_feedback');
        return;
      }
      final orderId = parts[0];
      final userId = parts[1];
      final due = DateTime.tryParse(parts[2]);
      if (due == null) {
        await storage.remove('pending_order_experience_feedback');
        return;
      }
      if (DateTime.now().isBefore(due)) return;

      final user = Provider.of<shared.User?>(context, listen: false);
      if (user == null || user.id != userId) return;

      if (!mounted) return;
      await material.showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => FeedbackSubmissionDialog(
          orderId: orderId,
          userId: userId,
          feedbackMode: FeedbackMode.orderExperience,
          onSubmitted: () async {
            await AppLocalStorage().remove('pending_order_experience_feedback');
          },
        ),
      );
      // Dismiss without submit still clears so it does not loop every open.
      await AppLocalStorage().remove('pending_order_experience_feedback');
    } catch (_) {
      // Non-fatal
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    final scheme = material.Theme.of(context).colorScheme;
    final statusIconsLight = scheme.primary.computeLuminance() < 0.55;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: scheme.primary,
        statusBarIconBrightness:
            statusIconsLight ? Brightness.light : Brightness.dark,
        statusBarBrightness: Platform.isIOS
            ? (statusIconsLight ? Brightness.dark : Brightness.light)
            : (statusIconsLight ? Brightness.light : Brightness.dark),
      ),
    );

    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final analyticsService =
        Provider.of<shared.AnalyticsService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, provider, child) {
        final franchiseTitle = provider.currentAppName;

        return material.Scaffold(
          appBar: FranchiseAppBar(
            title: franchiseTitle,
            centerTitle: true,
            actions: [
              ProfileIconButton(
                tooltip: loc.profile,
                onPressed: () => material.Navigator.push(
                  context,
                  material.MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                ),
              ),
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
            ],
          ),
          backgroundColor: scheme.surface,
          body: material.SafeArea(
            child: !provider.hasValidFranchise
                ? const material.Center(
                    child: material.CircularProgressIndicator())
                : material.Column(
                    children: [
                      // Promo banner — collapse completely when none / all inactive
                      material.StreamBuilder<List<shared.Banner>>(
                        stream: firestoreService.getBanners(
                            franchiseId: provider.currentFranchiseId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              material.ConnectionState.waiting) {
                            return const material.SizedBox.shrink();
                          }
                          final banners = (snapshot.data ?? [])
                              .where((b) => b.active)
                              .toList();
                          if (banners.isEmpty) {
                            return const material.SizedBox.shrink();
                          }
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
                                imageAsset:
                                    shared.BrandingConfig.defaultCategoryIcon,
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
                  ),
          ),
        );
      },
    );
  }
}
