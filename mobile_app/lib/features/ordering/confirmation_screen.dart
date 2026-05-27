import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/tracking/tracking_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';
import 'package:franchise_mobile_app/core/services/notification_service.dart';
import 'package:shared_core/src/core/config/design_tokens.dart';

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
    // Temporary until FeatureConfig is fully migrated in shared_core
    setState(() => _trackOrderEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: UiConfig.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.orderConfirmed,
          style: TextStyle(
            color: UiConfig.foregroundColorDark,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: UiConfig.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
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
              SizedBox(height: DesignTokens.gridSpacing * 2),
              Text(
                localizations.thankYouForYourOrder ??
                    'Thank you for your order!',
                style: TextStyle(
                  color: UiConfig.primaryColor,
                  fontSize: DesignTokens.titleFontSize,
                  fontWeight: UiConfig.fontWeightBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.gridSpacing),
              Text(
                localizations.yourOrderIdIs ?? 'Your order ID is:',
                style: TextStyle(
                  color: UiConfig.textColor,
                  fontSize: DesignTokens.bodyFontSize,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: UiConfig.fontWeightMedium,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.orderId,
                style: TextStyle(
                  color: UiConfig.accentColor,
                  fontSize: DesignTokens.bodyFontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.gridSpacing * 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UiConfig.primaryColor,
                  foregroundColor: UiConfig.foregroundColorDark,
                  padding: UiConfig.defaultPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(
                  localizations.returnToHome ?? 'Return to Home',
                  style: TextStyle(
                    fontSize: DesignTokens.bodyFontSize,
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: UiConfig.fontWeightMedium,
                  ),
                ),
              ),
              if (_trackOrderEnabled) ...[
                SizedBox(height: DesignTokens.gridSpacing),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delivery_dining),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UiConfig.secondaryColor,
                    foregroundColor: UiConfig.foregroundColorDark,
                    padding: UiConfig.defaultPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                    ),
                  ),
                  label: Text(
                    localizations.trackOrder,
                    style: TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: UiConfig.fontWeightMedium,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackingScreen(orderId: widget.orderId),
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
  }
}
