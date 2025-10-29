// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/feedback_entry.dart' as model;
import 'package:franchise_mobile_app/core/services/offline_service.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeedbackScreen extends StatefulWidget {
  final String orderId;

  const FeedbackScreen({super.key, required this.orderId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedCategories = {};
  bool _anonymous = false;
  bool _loading = false;
  String? _error;

  late List<String> _categories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    // Use localized categories from ARB
    _categories = [
      loc.categoryFoodQuality,
      loc.categoryDeliverySpeed,
      loc.categoryService,
      loc.categoryOrderAccuracy,
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final loc = AppLocalizations.of(context)!;
    if (_rating == 0) {
      setState(() => _error = loc.ratingRequiredError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final userId =
        _anonymous ? '' : (firestoreService.auth.currentUser?.uid ?? '');

    final String feedbackId = const Uuid().v4();
    final feedback = model.FeedbackEntry(
      id: feedbackId,
      rating: _rating,
      comment: _commentController.text.trim(),
      categories: _selectedCategories.toList(),
      timestamp: DateTime.now(),
      userId: userId,
      anonymous: _anonymous,
      orderId: widget.orderId,
    );

    try {
      final offlineService =
          Provider.of<OfflineService>(context, listen: false);
      await firestoreService.submitOrderFeedback(
        orderId: widget.orderId,
        userId: userId,
        feedback: feedback,
      );
      offlineService.removeQueuedFeedback(feedbackId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(loc.feedbackThankYouTitle),
          content: Text(loc.feedbackThankYouBody),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(loc.feedbackBackToMenu),
            )
          ],
        ),
      );
    } catch (e) {
      final offlineService =
          Provider.of<OfflineService>(context, listen: false);
      offlineService.queueFeedback(feedback);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(loc.feedbackOfflineTitle),
          content: Text(loc.feedbackOfflineBody),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(loc.feedbackBackToMenu),
            )
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.feedbackScreenTitle,
          style: TextStyle(
            color: DesignTokens.foregroundColor,
            fontSize: DesignTokens.titleFontSize,
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.titleFontWeight,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: DesignTokens.cardPadding,
            child: Card(
              color: DesignTokens.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              elevation: DesignTokens.cardElevation,
              child: Padding(
                padding: DesignTokens.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      BrandingConfig.logoMain,
                      height: 56,
                      errorBuilder: (_, __, ___) => Image.asset(
                          BrandingConfig.fallbackAppIcon,
                          height: 56),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.feedbackPromptTitle,
                      style: TextStyle(
                        fontSize: DesignTokens.titleFontSize,
                        fontWeight: DesignTokens.titleFontWeight,
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _StarRating(
                      rating: _rating,
                      onRatingChanged: (r) => setState(() => _rating = r),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      children: _categories
                          .map((cat) => FilterChip(
                                label: Text(cat),
                                selected: _selectedCategories.contains(cat),
                                onSelected: (sel) {
                                  setState(() {
                                    sel
                                        ? _selectedCategories.add(cat)
                                        : _selectedCategories.remove(cat);
                                  });
                                },
                                selectedColor: DesignTokens.successColor
                                    .withAlpha((0.2 * 255).toInt()),
                                backgroundColor: DesignTokens.surfaceColor,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _commentController,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: loc.feedbackCommentsLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.formFieldRadius),
                        ),
                        counterStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _anonymous,
                          onChanged: (val) =>
                              setState(() => _anonymous = val ?? false),
                        ),
                        Text(loc.feedbackSubmitAnonymous),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: DesignTokens.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                        foregroundColor: DesignTokens.foregroundColor,
                        padding: DesignTokens.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                        elevation: DesignTokens.buttonElevation,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(loc.feedbackSubmitButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modular Star Rating Widget (accessible & reusable)
class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _StarRating({
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starFilled = i < rating;
        return IconButton(
          onPressed: () => onRatingChanged(i + 1),
          icon: Icon(
            starFilled ? Icons.star : Icons.star_border,
            color: starFilled ? DesignTokens.successColor : Colors.grey,
            size: 32,
          ),
          tooltip: loc.feedbackStarTooltip(i + 1),
        );
      }),
    );
  }
}
