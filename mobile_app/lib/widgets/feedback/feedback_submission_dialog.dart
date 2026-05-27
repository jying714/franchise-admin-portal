import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/loading_shimmer_widget.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:shared_core/src/core/config/design_tokens.dart';

enum FeedbackMode { ordering, orderExperience }

class FeedbackSubmissionDialog extends StatefulWidget {
  final String orderId;
  final String userId;
  final FeedbackMode feedbackMode;
  final VoidCallback? onSubmitted;

  const FeedbackSubmissionDialog({
    super.key,
    required this.orderId,
    required this.userId,
    this.feedbackMode = FeedbackMode.orderExperience,
    this.onSubmitted,
  });

  @override
  State<FeedbackSubmissionDialog> createState() =>
      _FeedbackSubmissionDialogState();
}

class _FeedbackSubmissionDialogState extends State<FeedbackSubmissionDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _anonymous = false;
  bool _isSubmitting = false;
  String? _errorText;
  final Map<String, int> _categoryRatings = {};
  static const int _maxCommentLength = 500;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<String> _getFeedbackCategories(AppLocalizations loc) {
    if (widget.feedbackMode == FeedbackMode.ordering) {
      return [
        loc.categoryEaseOfUse,
        loc.categoryCheckoutProcess,
        loc.categoryFindingItems,
        loc.categoryPaymentOptions,
      ];
    } else {
      return [
        loc.categoryFoodQuality,
        loc.categoryService,
        loc.categoryDeliverySpeed,
        loc.categoryOrderAccuracy,
      ];
    }
  }

  bool get _canSubmit => _rating > 0 && !_isSubmitting;

  void _submit(BuildContext context) async {
    setState(() => _isSubmitting = true);
    final loc = AppLocalizations.of(context)!;

    try {
      final List<Map<String, dynamic>> categoryRatingsList =
          _categoryRatings.entries
              .where((e) => e.value != null)
              .map((e) => {
                    'category': e.key,
                    'score': e.value,
                  })
              .toList();

      final entry = shared.FeedbackEntry(
        id: UniqueKey().toString(),
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        categories: categoryRatingsList
            .map((e) => "${e['category']}:${e['score']}")
            .toList(),
        timestamp: DateTime.now(),
        userId: widget.userId,
        anonymous: _anonymous,
        orderId: widget.orderId,
        feedbackMode: widget.feedbackMode.toString().split('.').last,
      );

      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);

      await firestoreService.submitOrderFeedback(
        userId: widget.userId,
        orderId: widget.orderId,
        feedback: entry
            .toFirestore(), // ← FIXED: convert model to Map<String, dynamic>
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => const _FeedbackThankYouDialog(),
      );
      Navigator.of(context).pop();
      widget.onSubmitted?.call();
    } catch (e) {
      setState(() {
        _errorText = loc.unknownError;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final categories = _getFeedbackCategories(loc);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.feedbackMode == FeedbackMode.ordering
                      ? loc.orderingFeedbackPromptTitle
                      : loc.feedbackPromptTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.feedbackMode == FeedbackMode.ordering) ...[
                  Text(
                    loc.orderingFeedbackInstructions ??
                        "Your feedback helps us improve the ordering experience.",
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 10),
                Center(
                  child: _StarRatingSelector(
                    rating: _rating,
                    onChanged: (value) => setState(() {
                      _rating = value;
                      _errorText = null;
                    }),
                    tooltip: null,
                    color: UiConfig.primaryColor,
                  ),
                ),
                if (_rating == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      loc.ratingRequiredError,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: UiConfig.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  loc.categoriesTitle,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _CategoryRatingSelector(
                        category: cat,
                        value: _categoryRatings[cat],
                        onChanged: (val) {
                          setState(() {
                            if (val == null) {
                              _categoryRatings.remove(cat);
                            } else {
                              _categoryRatings[cat] = val;
                            }
                          });
                        },
                      ),
                    )),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  maxLength: _maxCommentLength,
                  minLines: 1,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: loc.feedbackCommentsLabel,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.inputBorderRadius),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {
                      if (_errorText != null) _errorText = null;
                    });
                  },
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _anonymous,
                      onChanged: (val) =>
                          setState(() => _anonymous = val ?? false),
                    ),
                    Expanded(
                      child: Text(
                        loc.feedbackSubmitAnonymous,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: UiConfig.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UiConfig.primaryColor,
                      foregroundColor: UiConfig.foregroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesignTokens.buttonBorderRadius),
                      ),
                    ),
                    onPressed: _canSubmit ? () => _submit(context) : null,
                    child: _isSubmitting
                        ? const LoadingShimmerWidget()
                        : Text(loc.feedbackSubmitButton),
                  ),
                ),
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(loc.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRatingSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final String? tooltip;
  final Color? color;

  const _StarRatingSelector({
    super.key,
    required this.rating,
    required this.onChanged,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final stars = List<Widget>.generate(5, (i) {
      final selected = i < rating;
      return IconButton(
        icon: Icon(
          selected ? Icons.star : Icons.star_border,
          color: selected ? color ?? Colors.amber : Colors.grey[400],
          size: 32,
        ),
        tooltip: tooltip,
        onPressed: () => onChanged(i + 1),
        splashRadius: 20,
      );
    });

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stars,
        ),
      ),
    );
  }
}

class _CategoryRatingSelector extends StatelessWidget {
  final String category;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _CategoryRatingSelector({
    super.key,
    required this.category,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<bool> isSelected = List.generate(5, (i) => value == (i + 1));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        ToggleButtons(
          borderRadius: BorderRadius.circular(6),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          isSelected: isSelected,
          onPressed: (idx) {
            if (value == idx + 1) {
              onChanged(null);
            } else {
              onChanged(idx + 1);
            }
          },
          fillColor: UiConfig.primaryColor,
          selectedColor: UiConfig.foregroundColor,
          color: theme.textTheme.bodyMedium?.color,
          borderColor: UiConfig.primaryColor.withOpacity(0.3),
          selectedBorderColor: UiConfig.primaryColor,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '${i + 1}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackThankYouDialog extends StatelessWidget {
  const _FeedbackThankYouDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: UiConfig.primaryColor, size: 56),
            const SizedBox(height: 18),
            Text(
              loc.feedbackThankYouTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              loc.feedbackThankYouBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UiConfig.primaryColor,
                  foregroundColor: UiConfig.foregroundColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.feedbackBackToMenu),
              ),
            )
          ],
        ),
      ),
    );
  }
}
