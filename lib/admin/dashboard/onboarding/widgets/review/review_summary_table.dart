import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/onboarding_validation_issue.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_review_provider.dart';

class ReviewSummaryTable extends StatelessWidget {
  static const Map<String, String> _sectionRoutes = {
    'Features': '/onboarding/feature_setup',
    'Ingredient Types': '/onboarding/ingredient-types',
    'Ingredients': '/onboarding/ingredients',
    'Categories': '/onboarding/categories',
    'Menu Items': '/onboarding/menu_items',
  };

  static const List<String> _sectionOrder = [
    'Features',
    'Ingredient Types',
    'Ingredients',
    'Categories',
    'Menu Items',
  ];

  const ReviewSummaryTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewProvider = Provider.of<OnboardingReviewProvider>(context);
    final issuesBySection = reviewProvider.allIssuesBySection;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onboarding Progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 21,
              color: colorScheme.primary,
              fontFamily: DesignTokens.fontFamily,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: DesignTokens.adminCardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2), // Section
                  1: FlexColumnWidth(1.1), // Status
                  2: FlexColumnWidth(1.0), // Issues
                  3: FlexColumnWidth(1.3), // Action
                },
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.16),
                    width: 1.1,
                  ),
                ),
                children: [
                  _buildHeaderRow(context),
                  ..._sectionOrder.map(
                    (section) => _buildSectionRow(
                      context,
                      section,
                      issuesBySection[section] ?? [],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    TextStyle thStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: colorScheme.primary.withOpacity(0.87),
      letterSpacing: 0.12,
      fontFamily: DesignTokens.fontFamily,
    );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 10),
          child: Text('Section', style: thStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11.0),
          child: Text('Status', style: thStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11.0),
          child: Text('Issues', style: thStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 10),
          child: Text('Action', style: thStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  TableRow _buildSectionRow(BuildContext context, String section,
      List<OnboardingValidationIssue> issues) {
    final colorScheme = Theme.of(context).colorScheme;

    final criticalCount = issues
        .where((e) =>
            e.isBlocking && e.severity == OnboardingIssueSeverity.critical)
        .length;
    final warningCount = issues
        .where((e) =>
            !e.isBlocking && e.severity == OnboardingIssueSeverity.warning)
        .length;

    Widget statusWidget;
    if (criticalCount > 0) {
      statusWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_rounded, color: colorScheme.error, size: 22),
          const SizedBox(width: 5),
          Text('Blocked',
              style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      );
    } else if (warningCount > 0) {
      statusWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: colorScheme.tertiary, size: 22),
          const SizedBox(width: 5),
          Text('Warning',
              style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      );
    } else {
      statusWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 22),
          const SizedBox(width: 5),
          Text('Complete',
              style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      );
    }

    Widget issuesWidget;
    if (criticalCount + warningCount == 0) {
      issuesWidget = Text('0',
          style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
              fontSize: 15),
          textAlign: TextAlign.center);
    } else {
      issuesWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (criticalCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Tooltip(
                message: '$criticalCount critical',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$criticalCount',
                    style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
            ),
          if (warningCount > 0)
            Tooltip(
              message: '$warningCount warning',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$warningCount',
                  style: TextStyle(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
        ],
      );
    }

    Widget actionWidget;
    // Deep link routing for "Fix Now" and "Review" actions:
    if (criticalCount > 0) {
      actionWidget = TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          // Find the first critical issue for this section
          final issue = issues.firstWhere(
            (e) =>
                e.isBlocking && e.severity == OnboardingIssueSeverity.critical,
            orElse: () => issues.first,
          );
          final args = <String, dynamic>{};
          if (issue.section == 'Features' && issue.itemId.isNotEmpty) {
            args['featureKey'] = issue.itemId;
          } else if (issue.section == 'Ingredient Types' &&
              issue.itemId.isNotEmpty) {
            args['ingredientTypeId'] = issue.itemId;
          } else if (issue.section == 'Ingredients' &&
              issue.itemId.isNotEmpty) {
            args['ingredientId'] = issue.itemId;
          } else if (issue.section == 'Categories' && issue.itemId.isNotEmpty) {
            args['categoryId'] = issue.itemId;
          } else if (issue.section == 'Menu Items' && issue.itemId.isNotEmpty) {
            args['menuItemId'] = issue.itemId;
          }
          Navigator.of(context).pushNamed(
            issue.fixRoute,
            arguments: args,
          );
        },
        icon: const Icon(Icons.build_circle_outlined, size: 20),
        label: const Text('Fix Now'),
      );
    } else if (warningCount > 0) {
      actionWidget = TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.tertiary,
        ),
        onPressed: () {
          final issue = issues.firstWhere(
            (e) =>
                !e.isBlocking && e.severity == OnboardingIssueSeverity.warning,
            orElse: () => issues.first,
          );
          final args = <String, dynamic>{};
          if (issue.section == 'Features' && issue.itemId.isNotEmpty) {
            args['featureKey'] = issue.itemId;
          } else if (issue.section == 'Ingredient Types' &&
              issue.itemId.isNotEmpty) {
            args['ingredientTypeId'] = issue.itemId;
          } else if (issue.section == 'Ingredients' &&
              issue.itemId.isNotEmpty) {
            args['ingredientId'] = issue.itemId;
          } else if (issue.section == 'Categories' && issue.itemId.isNotEmpty) {
            args['categoryId'] = issue.itemId;
          } else if (issue.section == 'Menu Items' && issue.itemId.isNotEmpty) {
            args['menuItemId'] = issue.itemId;
          }
          Navigator.of(context).pushNamed(
            issue.fixRoute,
            arguments: args,
          );
        },
        icon: const Icon(Icons.visibility_outlined, size: 20),
        label: const Text('Review'),
      );
    } else {
      actionWidget = Text(
        '—',
        style: TextStyle(color: colorScheme.outlineVariant, fontSize: 15),
        textAlign: TextAlign.center,
      );
    }

    Widget sectionWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 10),
      child: Text(
        section,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: colorScheme.onSurface.withOpacity(0.89),
          fontFamily: DesignTokens.fontFamily,
        ),
      ),
    );

    return TableRow(
      children: [
        sectionWidget,
        statusWidget,
        issuesWidget,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Center(child: actionWidget),
        ),
      ],
    );
  }
}
