import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/features/tracking/tracking_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';
import 'package:franchise_mobile_app/core/services/notification_service.dart';

class ConfirmationScreen extends StatefulWidget {
  final String orderId;
  final String? userFcmToken;

  const ConfirmationScreen({
    super.key,
    required this.orderId,
    this.userFcmToken,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  late final NotificationService _notificationService;
  bool _notificationSent = false;
  bool _trackOrderEnabled = false;
  bool _feedbackDialogShown = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService.instance;
    _triggerPushNotification();
    _fetchTrackOrderToggle();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showFeedbackDialogIfEligible());
  }

  void _showFeedbackDialogIfEligible() async {
    if (_feedbackDialogShown) return;
    _feedbackDialogShown = true;

    final user = Provider.of<shared.User?>(context, listen: false);
    if (user == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FeedbackSubmissionDialog(
        orderId: widget.orderId,
        userId: user.id,
        feedbackMode: FeedbackMode.ordering,
        onSubmitted: () {},
      ),
    );
  }

  Future<void> _triggerPushNotification() async {
    if (widget.userFcmToken != null && !_notificationSent) {
      await _notificationService.sendNotification(
        widget.userFcmToken!,
        'Order Confirmed',
        'Your order #${widget.orderId} has been placed!',
      );
      setState(() => _notificationSent = true);
    }
  }

  Future<void> _fetchTrackOrderToggle() async {
    setState(
        () => _trackOrderEnabled = true); // Temporary until full FeatureConfig
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, provider, child) {
        if (!provider.hasValidFranchise) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: UiConfig.backgroundColor,
          appBar: FranchiseAppBar(
            title: localizations.orderConfirmed,
            showLogo: true,
            logoUrl: UiConfig.currentLogoUrl,
            logoAsset: shared.BrandingConfig.appBarLogoAsset,
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: UiConfig.defaultPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: UiConfig.secondaryColor,
                    size: 72,
                  ),
                  SizedBox(height: shared.DesignTokens.gridSpacing * 2),
                  Text(
                    localizations.thankYouForYourOrder ??
                        'Thank you for your order!',
                    style: TextStyle(
                      color: UiConfig.primaryColor,
                      fontSize: shared.DesignTokens.titleFontSize,
                      fontWeight: UiConfig.fontWeightBold,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: shared.DesignTokens.gridSpacing),
                  Text(
                    localizations.yourOrderIdIs ?? 'Your order ID is:',
                    style: TextStyle(
                      color: UiConfig.textColor,
                      fontSize: shared.DesignTokens.bodyFontSize,
                      fontFamily: shared.DesignTokens.fontFamily,
                      fontWeight: UiConfig.fontWeightMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.orderId,
                    style: TextStyle(
                      color: UiConfig.accentColor,
                      fontSize: shared.DesignTokens.bodyFontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                  SizedBox(height: shared.DesignTokens.gridSpacing * 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UiConfig.primaryColor,
                      foregroundColor: UiConfig.foregroundColorDark,
                      padding: UiConfig.defaultPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.buttonRadius),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(
                      localizations.returnToHome ?? 'Return to Home',
                      style: TextStyle(
                        fontSize: shared.DesignTokens.bodyFontSize,
                        fontFamily: shared.DesignTokens.fontFamily,
                        fontWeight: UiConfig.fontWeightMedium,
                      ),
                    ),
                  ),
                  if (_trackOrderEnabled) ...[
                    SizedBox(height: shared.DesignTokens.gridSpacing),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delivery_dining),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UiConfig.secondaryColor,
                        foregroundColor: UiConfig.foregroundColorDark,
                        padding: UiConfig.defaultPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              shared.DesignTokens.buttonRadius),
                        ),
                      ),
                      label: Text(
                        localizations.trackOrder,
                        style: TextStyle(
                          fontSize: shared.DesignTokens.bodyFontSize,
                          fontFamily: shared.DesignTokens.fontFamily,
                          fontWeight: UiConfig.fontWeightMedium,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TrackingScreen(orderId: widget.orderId),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
