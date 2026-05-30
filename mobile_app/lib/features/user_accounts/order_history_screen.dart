import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:shared_core/shared_core.dart' show BrandingConfig;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';

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
          appBar: AppBar(
            title: Text(
              localizations.orderHistory,
              style: TextStyle(
                fontSize: DesignTokens.titleFontSize,
                color: UiConfig.foregroundColorDark,
                fontWeight: UiConfig.fontWeightBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            backgroundColor: UiConfig.primaryColor,
            centerTitle: true,
            elevation: 0,
            iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
          ),
          backgroundColor: UiConfig.backgroundColorDark,
          body: authUser == null
              ? Center(
                  child: Text(
                    localizations.notSignedIn,
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: UiConfig.textColorDark,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: UiConfig.fontWeightNormal,
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
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.noPastOrders,
                          style: TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            color: UiConfig.textColorDark,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: UiConfig.fontWeightNormal,
                          ),
                        ),
                      );
                    }
                    final orders = snapshot.data!;
                    return ListView.builder(
                      padding: UiConfig.defaultScreenPadding,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          elevation: DesignTokens.cardElevation,
                          margin: const EdgeInsets.symmetric(
                            vertical: DesignTokens.gridSpacing / 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.cardRadius),
                          ),
                          color: UiConfig.surfaceColor,
                          child: ExpansionTile(
                            title: Text(
                              localizations.orderNumberWithId(order.id),
                              style: TextStyle(
                                fontSize: DesignTokens.bodyFontSize,
                                color: UiConfig.textColorDark,
                                fontWeight: UiConfig.fontWeightBold,
                                fontFamily: DesignTokens.fontFamily,
                              ),
                            ),
                            subtitle: Text(
                              localizations.orderDateAndTotal(
                                order.timestamp.toString().substring(0, 10),
                                order.total.toStringAsFixed(2),
                              ),
                              style: TextStyle(
                                fontSize: DesignTokens.captionFontSize,
                                color: UiConfig.secondaryTextColor,
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: UiConfig.fontWeightNormal,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: UiConfig.cardPadding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${localizations.status}: ${order.status}',
                                      style: TextStyle(
                                        color: UiConfig.textColorDark,
                                        fontSize: DesignTokens.bodyFontSize,
                                        fontFamily: DesignTokens.fontFamily,
                                        fontWeight: UiConfig.fontWeightNormal,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: DesignTokens.gridSpacing / 2),
                                    Text(
                                      localizations.items,
                                      style: TextStyle(
                                        color: UiConfig.textColorDark,
                                        fontSize: DesignTokens.bodyFontSize,
                                        fontFamily: DesignTokens.fontFamily,
                                        fontWeight: UiConfig.fontWeightBold,
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
                                                    color: UiConfig
                                                        .secondaryTextColor,
                                                    fontFamily:
                                                        DesignTokens.fontFamily,
                                                    fontWeight: UiConfig
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
                                        color: UiConfig.textColorDark,
                                        fontSize: DesignTokens.bodyFontSize,
                                        fontFamily: DesignTokens.fontFamily,
                                        fontWeight: UiConfig.fontWeightNormal,
                                      ),
                                    ),
                                    if (order.address != null) ...[
                                      const SizedBox(
                                          height: DesignTokens.gridSpacing / 2),
                                      Text(
                                        '${localizations.address}: ${order.address!.street}, ${order.address!.city}',
                                        style: TextStyle(
                                          fontSize:
                                              DesignTokens.captionFontSize,
                                          color: UiConfig.secondaryTextColor,
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight: UiConfig.fontWeightNormal,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(
                                        height: DesignTokens.gridSpacing),
                                    FutureBuilder<bool>(
                                      future: firestoreService
                                          .hasOrderFeedback(order.id),
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
                                                    UiConfig.primaryColor,
                                                foregroundColor: UiConfig
                                                    .foregroundColorDark,
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                        UiConfig.surfaceColor,
                                                    duration: const Duration(
                                                        seconds: DesignTokens
                                                            .toastDurationSeconds),
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
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      UiConfig.secondaryColor,
                                                  foregroundColor: UiConfig
                                                      .foregroundColorDark,
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
                                                onPressed: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        FeedbackSubmissionDialog(
                                                      orderId: order.id,
                                                      userId: authUser.id,
                                                      feedbackMode: FeedbackMode
                                                          .orderExperience,
                                                      onSubmitted: () {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                localizations
                                                                    .feedbackThankYouBody),
                                                            backgroundColor:
                                                                UiConfig
                                                                    .surfaceColor,
                                                            duration: const Duration(
                                                                seconds:
                                                                    DesignTokens
                                                                        .toastDurationSeconds),
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
                                                      color: UiConfig
                                                          .secondaryColor,
                                                      size: 18),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    localizations
                                                        .feedbackAlreadySubmittedTitle,
                                                    style: TextStyle(
                                                      fontSize: DesignTokens
                                                          .captionFontSize,
                                                      color: UiConfig
                                                          .secondaryTextColor,
                                                      fontFamily: DesignTokens
                                                          .fontFamily,
                                                      fontWeight: UiConfig
                                                          .fontWeightNormal,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    localizations
                                                        .feedbackAlreadySubmittedSubtitle,
                                                    style: TextStyle(
                                                      fontSize: DesignTokens
                                                          .captionFontSize,
                                                      color: UiConfig
                                                          .secondaryTextColor,
                                                      fontFamily: DesignTokens
                                                          .fontFamily,
                                                      fontWeight: UiConfig
                                                          .fontWeightNormal,
                                                    ),
                                                    textAlign: TextAlign.center,
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
        );
      },
    );
  }
}
