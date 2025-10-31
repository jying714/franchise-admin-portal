import 'package:flutter/material.dart';
import 'package:shared_core/src/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart'; // <-- Add this import
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    final authUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.orderHistory,
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
      body: authUser == null
          ? Center(
              child: Text(
                localizations.notSignedIn,
                style: const TextStyle(
                  fontSize: DesignTokens.bodyFontSize,
                  color: DesignTokens.textColor,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.bodyFontWeight,
                ),
              ),
            )
          : StreamBuilder<List<order_model.Order>>(
              stream: firestoreService.getOrders(authUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      localizations.noPastOrders,
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        color: DesignTokens.textColor,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.bodyFontWeight,
                      ),
                    ),
                  );
                }
                final orders = snapshot.data!;
                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      localizations.noPastOrders,
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        color: DesignTokens.textColor,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.bodyFontWeight,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: DesignTokens.cardPadding,
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
                      color: DesignTokens.surfaceColor,
                      child: ExpansionTile(
                        title: Text(
                          localizations.orderNumberWithId(order.id),
                          style: const TextStyle(
                            fontSize: DesignTokens.bodyFontSize,
                            color: DesignTokens.textColor,
                            fontWeight: DesignTokens.titleFontWeight,
                            fontFamily: DesignTokens.fontFamily,
                          ),
                        ),
                        subtitle: Text(
                          localizations.orderDateAndTotal(
                            order.timestamp.toString().substring(0, 10),
                            order.total.toStringAsFixed(2),
                          ),
                          style: const TextStyle(
                            fontSize: DesignTokens.captionFontSize,
                            color: DesignTokens.secondaryTextColor,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.bodyFontWeight,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: DesignTokens.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${localizations.status}: ${order.status}',
                                  style: const TextStyle(
                                    color: DesignTokens.textColor,
                                    fontSize: DesignTokens.bodyFontSize,
                                    fontFamily: DesignTokens.fontFamily,
                                    fontWeight: DesignTokens.bodyFontWeight,
                                  ),
                                ),
                                const SizedBox(
                                    height: DesignTokens.gridSpacing / 2),
                                Text(
                                  localizations.items,
                                  style: const TextStyle(
                                    color: DesignTokens.textColor,
                                    fontSize: DesignTokens.bodyFontSize,
                                    fontFamily: DesignTokens.fontFamily,
                                    fontWeight: DesignTokens.bodyFontWeight,
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
                                            fallbackAsset:
                                                BrandingConfig.defaultPizzaIcon,
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
                                              style: const TextStyle(
                                                fontSize: DesignTokens
                                                    .captionFontSize,
                                                color: DesignTokens
                                                    .secondaryTextColor,
                                                fontFamily:
                                                    DesignTokens.fontFamily,
                                                fontWeight:
                                                    DesignTokens.bodyFontWeight,
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
                                  style: const TextStyle(
                                    color: DesignTokens.textColor,
                                    fontSize: DesignTokens.bodyFontSize,
                                    fontFamily: DesignTokens.fontFamily,
                                    fontWeight: DesignTokens.bodyFontWeight,
                                  ),
                                ),
                                if (order.address != null) ...[
                                  const SizedBox(
                                      height: DesignTokens.gridSpacing / 2),
                                  Text(
                                    '${localizations.address}: ${order.address!.street}, ${order.address!.city}',
                                    style: const TextStyle(
                                      fontSize: DesignTokens.captionFontSize,
                                      color: DesignTokens.secondaryTextColor,
                                      fontFamily: DesignTokens.fontFamily,
                                      fontWeight: DesignTokens.bodyFontWeight,
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
                                      return const SizedBox(); // Or loading indicator
                                    }

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                DesignTokens.primaryColor,
                                            foregroundColor:
                                                DesignTokens.foregroundColor,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      DesignTokens
                                                          .buttonRadius),
                                            ),
                                            elevation:
                                                DesignTokens.buttonElevation,
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    localizations
                                                        .reorderNotImplemented,
                                                    style: const TextStyle(
                                                      color: DesignTokens
                                                          .textColor,
                                                      fontFamily: DesignTokens
                                                          .fontFamily,
                                                      fontWeight: DesignTokens
                                                          .bodyFontWeight,
                                                    )),
                                                backgroundColor:
                                                    DesignTokens.surfaceColor,
                                                duration:
                                                    DesignTokens.toastDuration,
                                              ),
                                            );
                                          },
                                          child: Text(localizations.reorder),
                                        ),
                                        const SizedBox(width: 16),
                                        if (order.isFeedbackEligible &&
                                            !feedbackExists)
                                          ElevatedButton.icon(
                                            icon: const Icon(
                                                Icons.feedback_outlined),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  DesignTokens.secondaryColor,
                                              foregroundColor:
                                                  DesignTokens.foregroundColor,
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
                                              elevation:
                                                  DesignTokens.buttonElevation,
                                            ),
                                            onPressed: () async {
                                              await showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    FeedbackSubmissionDialog(
                                                  orderId: order.id,
                                                  userId: authUser.uid,
                                                  feedbackMode: FeedbackMode
                                                      .orderExperience,
                                                  onSubmitted: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(localizations
                                                            .feedbackThankYouBody),
                                                        backgroundColor:
                                                            DesignTokens
                                                                .surfaceColor,
                                                        duration: DesignTokens
                                                            .toastDuration,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            label: Text(
                                                localizations.leaveFeedback),
                                          ),
                                        if (order.isFeedbackEligible &&
                                            feedbackExists)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.feedback,
                                                  color: DesignTokens
                                                      .secondaryColor,
                                                  size: 18),
                                              const SizedBox(height: 4),
                                              Text(
                                                localizations
                                                    .feedbackAlreadySubmittedTitle,
                                                style: const TextStyle(
                                                  fontSize: DesignTokens
                                                      .captionFontSize,
                                                  color: DesignTokens
                                                      .secondaryTextColor,
                                                  fontFamily:
                                                      DesignTokens.fontFamily,
                                                  fontWeight: DesignTokens
                                                      .bodyFontWeight,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                localizations
                                                    .feedbackAlreadySubmittedSubtitle,
                                                style: const TextStyle(
                                                  fontSize: DesignTokens
                                                      .captionFontSize,
                                                  color: DesignTokens
                                                      .secondaryTextColor,
                                                  fontFamily:
                                                      DesignTokens.fontFamily,
                                                  fontWeight: DesignTokens
                                                      .bodyFontWeight,
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
  }
}
