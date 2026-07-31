import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/core/services/offline_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

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

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final offlineService = Provider.of<OfflineService>(context, listen: false);

    final auth = FirebaseAuth.instance;
    final userId = _anonymous ? '' : (auth.currentUser?.uid ?? '');

    final String feedbackId = const Uuid().v4();
    final feedback = shared.FeedbackEntry(
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
      await firestoreService.submitOrderFeedback(
        orderId: widget.orderId,
        userId: userId,
        feedback: feedback.toFirestore(),
        franchiseId: franchiseId,
      );

      offlineService.removeQueuedFeedback(feedbackId);

      if (!mounted) return;
      _showSuccessDialog(loc);
    } catch (e) {
      offlineService.queueFeedback(feedback);
      if (!mounted) return;
      _showOfflineDialog(loc);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(AppLocalizations loc) {
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
          ),
        ],
      ),
    );
  }

  void _showOfflineDialog(AppLocalizations loc) {
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: FranchiseAppBar(
        title: loc.feedbackScreenTitle,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
      ),
      backgroundColor: shared.UiConfig.backgroundColorDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: shared.UiConfig.defaultPadding,
            child: Card(
              color: shared.UiConfig.surfaceColorDark,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.cardRadius),
              ),
              elevation: shared.DesignTokens.cardElevation,
              child: Padding(
                padding: shared.UiConfig.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      shared.UiConfig.currentLogoUrl ??
                          shared.UiConfig.logoMain,
                      height: 56,
                      errorBuilder: (_, __, ___) => Image.asset(
                        shared.UiConfig.defaultPizzaIcon,
                        height: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.feedbackPromptTitle,
                      style: TextStyle(
                        fontSize: shared.DesignTokens.titleFontSize,
                        fontWeight: shared.UiConfig.fontWeightBold,
                        fontFamily: shared.DesignTokens.fontFamily,
                        color: shared.UiConfig.textColorDark,
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
                                selectedColor:
                                    shared.UiConfig.successColor.withAlpha(51),
                                backgroundColor:
                                    shared.UiConfig.surfaceColorDark,
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
                              shared.DesignTokens.formFieldRadius),
                        ),
                        counterStyle: TextStyle(
                          fontSize: shared.DesignTokens.captionFontSize,
                          color: shared.UiConfig.hintTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _anonymous,
                          onChanged: (val) =>
                              setState(() => _anonymous = val ?? false),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          loc.feedbackSubmitAnonymous,
                          style:
                              TextStyle(color: shared.UiConfig.textColorDark),
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: shared.UiConfig.fontWeightBold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: shared.UiConfig.defaultPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              shared.DesignTokens.buttonRadius),
                        ),
                        elevation: shared.DesignTokens.buttonElevation,
                      ),
                      child: _loading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: shared.UiConfig.onPrimaryColor,
                              ),
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

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _StarRating({
    super.key,
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
            color: starFilled
                ? shared.UiConfig.successColor
                : shared.UiConfig.hintTextColor,
            size: 32,
          ),
          tooltip: loc.feedbackStarTooltip(i + 1),
        );
      }),
    );
  }
}
