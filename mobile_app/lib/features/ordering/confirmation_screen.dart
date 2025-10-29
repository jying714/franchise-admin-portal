// ignore: unused_import
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/feature_config.dart';
import 'package:franchise_mobile_app/core/services/notification_service.dart';
import 'package:franchise_mobile_app/features/tracking/tracking_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/feedback/feedback_submission_dialog.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/core/models/user.dart';

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
    // Show feedback dialog after first build
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showFeedbackDialogIfEligible());
  }

  void _showFeedbackDialogIfEligible() async {
    if (_feedbackDialogShown) return;
    _feedbackDialogShown = true;

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // You'd fetch order from Firestore or Provider and check hasFeedback here:
    // final order = await Provider.of<OrderService>(context, listen: false).getOrder(widget.orderId);
    // if (order.hasFeedback) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FeedbackSubmissionDialog(
        orderId: widget.orderId,
        userId: user.id,
        feedbackMode:
            FeedbackMode.ordering, // <-- Specify ordering feedback mode
        onSubmitted: () {
          // Optional: Do something after feedback is submitted
        },
      ),
    );
  }

  Future<void> _triggerPushNotification() async {
    if (widget.userFcmToken != null && !_notificationSent) {
      await _notificationService.sendNotification(
        widget.userFcmToken!,
        'Order Confirmed', // Kept for push only, not visible in UI.
        'Your order #${widget.orderId} has been placed!',
      );
      setState(() => _notificationSent = true);
    }
  }

  Future<void> _fetchTrackOrderToggle() async {
    final toggles = await FeatureConfig.instance
        .load()
        .then((_) => FeatureConfig.instance.asMap);
    setState(() {
      _trackOrderEnabled = toggles['statusEnabled'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.orderConfirmed,
          style: const TextStyle(
            color: DesignTokens.foregroundColor,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
      ),
      body: Center(
        child: Padding(
          padding: DesignTokens.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: DesignTokens.secondaryColor,
                size: 72,
              ),
              const SizedBox(height: DesignTokens.gridSpacing * 2),
              Text(
                localizations.thankYouForYourOrder ??
                    'Thank you for your order!',
                style: const TextStyle(
                  color: DesignTokens.primaryColor,
                  fontSize: DesignTokens.titleFontSize,
                  fontWeight: DesignTokens.titleFontWeight,
                  fontFamily: DesignTokens.fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.gridSpacing),
              Text(
                localizations.yourOrderIdIs ?? 'Your order ID is:',
                style: const TextStyle(
                  color: DesignTokens.textColor,
                  fontSize: DesignTokens.bodyFontSize,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.bodyFontWeight,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.orderId,
                style: const TextStyle(
                  color: DesignTokens.accentColor,
                  fontSize: DesignTokens.bodyFontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              const SizedBox(height: DesignTokens.gridSpacing * 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                  foregroundColor: DesignTokens.foregroundColor,
                  padding: DesignTokens.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: Text(
                  localizations.returnToHome ?? 'Return to Home',
                  style: const TextStyle(
                    fontSize: DesignTokens.bodyFontSize,
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.bodyFontWeight,
                  ),
                ),
              ),
              if (_trackOrderEnabled) ...[
                const SizedBox(height: DesignTokens.gridSpacing),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delivery_dining),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.secondaryColor,
                    foregroundColor: DesignTokens.foregroundColor,
                    padding: DesignTokens.buttonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                    ),
                  ),
                  label: Text(
                    localizations.trackOrder,
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.bodyFontWeight,
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
