import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:shared_core/shared_core.dart' show BrandingConfig;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';
import 'package:franchise_mobile_app/widgets/status_chip.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, child) {
        if (!franchiseProvider.hasValidFranchise) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authUser = authService.currentUser;

        return Scaffold(
          appBar: FranchiseAppBar(
            title: localizations.orderHistory,
            showLogo: true,
            logoUrl: shared.UiConfig.currentLogoUrl,
            logoAsset: shared.BrandingConfig.appBarLogoAsset,
            centerTitle: true,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            bottom: true,
            child: authUser == null
                ? Center(
                    child: Text(
                      localizations.notSignedIn,
                      style: TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: shared.UiConfig.fontWeightNormal,
                      ),
                    ),
                  )
                : StreamBuilder<List<shared.Order>>(
                    stream: firestoreService.getOrders(
                      userId: authUser.id,
                      franchiseId: franchiseProvider.currentFranchiseId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            localizations.loyaltyErrorLoading,
                            style: TextStyle(
                              fontSize: DesignTokens.bodyFontSize,
                              color: Theme.of(context).colorScheme.error,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: shared.UiConfig.fontWeightNormal,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            localizations.noPastOrders,
                            style: TextStyle(
                              fontSize: DesignTokens.bodyFontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: shared.UiConfig.fontWeightNormal,
                            ),
                          ),
                        );
                      }
                      final orders = snapshot.data!;
                      return ListView.builder(
                        padding: shared.UiConfig.defaultScreenPadding,
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final scheme = Theme.of(context).colorScheme;
                          return Card(
                            elevation: DesignTokens.cardElevation,
                            margin: const EdgeInsets.symmetric(
                              vertical: DesignTokens.gridSpacing / 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.cardRadius),
                              side: BorderSide(color: scheme.outline),
                            ),
                            color: scheme.surface,
                            child: ExpansionTile(
                              title: Text(
                                localizations.orderNumberWithId(order.id),
                                style: TextStyle(
                                  fontSize: DesignTokens.bodyFontSize,
                                  color: scheme.onSurface,
                                  fontWeight: shared.UiConfig.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                              ),
                              subtitle: Text(
                                localizations.orderDateAndTotal(
                                  DateFormat.yMMMd().format(order.timestamp),
                                  shared.UiConfig.currencyFormat(order.total),
                                ),
                                style: TextStyle(
                                  fontSize: DesignTokens.captionFontSize,
                                  color: scheme.onSurfaceVariant,
                                  fontFamily: DesignTokens.fontFamily,
                                  fontWeight: shared.UiConfig.fontWeightNormal,
                                ),
                              ),
                              trailing: StatusChip(status: order.status),
                              children: [
                                Padding(
                                  padding: shared.UiConfig.cardPadding,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      StatusChip(
                                          status: order.status, useIcon: true),
                                      const SizedBox(
                                          height: DesignTokens.gridSpacing / 2),
                                      Text(
                                        localizations.items,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontSize: DesignTokens.bodyFontSize,
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight:
                                              shared.UiConfig.fontWeightBold,
                                        ),
                                      ),
                                      ...order.items.map((item) => Padding(
                                            padding: const EdgeInsets.only(
                                              top: DesignTokens.gridSpacing / 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                NetworkImageWidget(
                                                  imageUrl: item.image ?? '',
                                                  fallbackAsset: BrandingConfig
                                                      .defaultPizzaIcon,
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.cover,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    '- ${item.name} x${item.quantity} (\$${item.price.toStringAsFixed(2)})',
                                                    style: TextStyle(
                                                      fontSize: DesignTokens
                                                          .captionFontSize,
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontFamily: DesignTokens
                                                          .fontFamily,
                                                      fontWeight: shared
                                                          .UiConfig
                                                          .fontWeightNormal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                      const SizedBox(
                                          height: DesignTokens.gridSpacing / 2),
                                      Text(
                                        '${localizations.deliveryType}: ${order.deliveryType}',
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontSize: DesignTokens.bodyFontSize,
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight:
                                              shared.UiConfig.fontWeightNormal,
                                        ),
                                      ),
                                      if (order.address != null) ...[
                                        const SizedBox(
                                            height:
                                                DesignTokens.gridSpacing / 2),
                                        Text(
                                          '${localizations.address}: ${order.address!.street}, ${order.address!.city}',
                                          style: TextStyle(
                                            fontSize:
                                                DesignTokens.captionFontSize,
                                            color: scheme.onSurfaceVariant,
                                            fontFamily: DesignTokens.fontFamily,
                                            fontWeight: shared
                                                .UiConfig.fontWeightNormal,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(
                                          height: DesignTokens.gridSpacing),
                                      FutureBuilder<bool>(
                                        future: firestoreService
                                            .hasOrderFeedback(order.id,
                                                franchiseId: franchiseProvider
                                                    .currentFranchiseId),
                                        builder: (context, snapshot) {
                                          final feedbackExists =
                                              snapshot.data == true;
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox();
                                          }

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      scheme.primary,
                                                  foregroundColor:
                                                      scheme.onPrimary,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            DesignTokens
                                                                .buttonRadius),
                                                  ),
                                                  elevation: DesignTokens
                                                      .buttonElevation,
                                                ),
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(localizations
                                                          .reorderNotImplemented),
                                                      backgroundColor:
                                                          scheme.surface,
                                                      duration: Duration(
                                                          seconds: DesignTokens
                                                              .toastDurationSeconds),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                },
                                                child:
                                                    Text(localizations.reorder),
                                              ),
                                              const SizedBox(width: 16),
                                              if (order.isFeedbackEligible &&
                                                  !feedbackExists)
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                      Icons.feedback_outlined),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        scheme.surface,
                                                    foregroundColor:
                                                        scheme.primary,
                                                    side: BorderSide(
                                                        color: scheme.outline),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius: BorderRadius
                                                          .circular(DesignTokens
                                                              .buttonRadius),
                                                    ),
                                                    elevation: DesignTokens
                                                        .buttonElevation,
                                                  ),
                                                  onPressed: () async {
                                                    final fid =
                                                        franchiseProvider
                                                            .currentFranchiseId;
                                                    await showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          FeedbackSubmissionDialog(
                                                        orderId: order.id,
                                                        userId: authUser.id,
                                                        feedbackMode:
                                                            FeedbackMode
                                                                .orderExperience,
                                                        franchiseId:
                                                            fid != 'unknown'
                                                                ? fid
                                                                : null,
                                                        onSubmitted: () {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  localizations
                                                                      .feedbackThankYouBody),
                                                              backgroundColor:
                                                                  shared
                                                                      .UiConfig
                                                                      .surfaceColor,
                                                              duration: Duration(
                                                                  seconds:
                                                                      DesignTokens
                                                                          .toastDurationSeconds),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  label: Text(localizations
                                                      .leaveFeedback),
                                                ),
                                              if (order.isFeedbackEligible &&
                                                  feedbackExists)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.feedback,
                                                        color: scheme.primary,
                                                        size: 18),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      localizations
                                                          .feedbackAlreadySubmittedTitle,
                                                      style: TextStyle(
                                                        fontSize: DesignTokens
                                                            .captionFontSize,
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontFamily: DesignTokens
                                                            .fontFamily,
                                                        fontWeight: shared
                                                            .UiConfig
                                                            .fontWeightNormal,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    Text(
                                                      localizations
                                                          .feedbackAlreadySubmittedSubtitle,
                                                      style: TextStyle(
                                                        fontSize: DesignTokens
                                                            .captionFontSize,
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontFamily: DesignTokens
                                                            .fontFamily,
                                                        fontWeight: shared
                                                            .UiConfig
                                                            .fontWeightNormal,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
