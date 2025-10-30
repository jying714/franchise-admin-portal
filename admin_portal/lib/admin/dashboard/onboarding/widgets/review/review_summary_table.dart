import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/models/onboarding_validation_issue.dart';
import 'package:admin_portal/core/providers/onboarding_review_provider.dart';
import 'package:admin_portal/core/utils/onboarding_navigation_utils.dart';
import 'package:admin_portal/core/providers/ingredient_metadata_provider.dart';

class ReviewSummaryTable extends StatelessWidget {
  static const List<String> _sectionOrder = [
    OnboardingSections.features,
    OnboardingSections.ingredientTypes,
    OnboardingSections.ingredients,
    OnboardingSections.categories,
    OnboardingSections.menuItems,
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
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.0),
                3: FlexColumnWidth(1.3),
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
                    issuesBySection[section] ?? const [],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: colorScheme.primary.withOpacity(0.87),
      letterSpacing: 0.12,
      fontFamily: DesignTokens.fontFamily,
    );
    return TableRow(
      children: [
        _buildHeaderCell('Section', thStyle,
            align: TextAlign.left, padLeft: 10),
        _buildHeaderCell('Status', thStyle),
        _buildHeaderCell('Issues', thStyle),
        _buildHeaderCell('Action', thStyle),
      ],
    );
  }

  Widget _buildHeaderCell(String text, TextStyle style,
      {TextAlign align = TextAlign.center, double padLeft = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.0, horizontal: padLeft),
      child: Text(text, style: style, textAlign: align),
    );
  }

  TableRow _buildSectionRow(
    BuildContext context,
    String section,
    List<OnboardingValidationIssue> issues,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final criticalCount = issues
        .where((e) =>
            e.isBlocking && e.severity == OnboardingIssueSeverity.critical)
        .length;
    final warningCount = issues
        .where((e) =>
            !e.isBlocking && e.severity == OnboardingIssueSeverity.warning)
        .length;

    final statusWidget =
        _buildStatusWidget(colorScheme, criticalCount, warningCount);
    final issuesWidget =
        _buildIssuesWidget(colorScheme, criticalCount, warningCount);

    final actionWidget = _buildActionWidget(
        context, section, issues, criticalCount, warningCount, colorScheme);

    final sectionWidget = Padding(
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

  Widget _buildStatusWidget(
      ColorScheme colorScheme, int criticalCount, int warningCount) {
    if (criticalCount > 0) {
      return _statusRow(Icons.cancel_rounded, 'Blocked', colorScheme.error);
    } else if (warningCount > 0) {
      return _statusRow(
          Icons.warning_amber_rounded, 'Warning', colorScheme.tertiary);
    } else {
      return _statusRow(
          Icons.check_circle_rounded, 'Complete', Colors.green[700]!,
          iconColor: Colors.green[600]!);
    }
  }

  Widget _statusRow(IconData icon, String label, Color textColor,
      {Color? iconColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor ?? textColor, size: 22),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  Widget _buildIssuesWidget(
      ColorScheme colorScheme, int criticalCount, int warningCount) {
    if (criticalCount + warningCount == 0) {
      return Text('0',
          style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
              fontSize: 15),
          textAlign: TextAlign.center);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (criticalCount > 0)
          _issueBadge('$criticalCount', colorScheme.error.withOpacity(0.15),
              colorScheme.error,
              tooltip: '$criticalCount critical'),
        if (warningCount > 0)
          _issueBadge('$warningCount', colorScheme.tertiary.withOpacity(0.16),
              colorScheme.tertiary,
              tooltip: '$warningCount warning'),
      ],
    );
  }

  Widget _issueBadge(String text, Color bgColor, Color fgColor,
      {required String tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Text(text,
              style: TextStyle(
                  color: fgColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildActionWidget(
    BuildContext context,
    String section,
    List<OnboardingValidationIssue> issues,
    int criticalCount,
    int warningCount,
    ColorScheme colorScheme,
  ) {
    void _navigateToFix(OnboardingValidationIssue issue) async {
      debugPrint('──────────────────────────────────────────────');
      debugPrint('[ReviewSummaryTable] 🛠 Attempting navigation');
      debugPrint('  • Section (raw): "$section"');
      debugPrint('  • Issue.itemId: "${issue.itemId}"');
      debugPrint('  • Issue.itemLocator: "${issue.itemLocator}"');
      debugPrint('  • Issue.actionLabel: "${issue.actionLabel}"');
      debugPrint('  • Issue.affectedFields: ${issue.affectedFields}');
      debugPrint('──────────────────────────────────────────────');

      // 1) Normalize & resolve route
      final normalizedSection =
          OnboardingNavigationUtils.normalizeForRouting(section);
      debugPrint(
          '[ReviewSummaryTable] Normalized section → "$normalizedSection"');

      final route =
          OnboardingNavigationUtils.resolveRoute(normalizedSection, issue);
      debugPrint('[ReviewSummaryTable] Resolved route → "$route"');

      if (route.isEmpty) {
        debugPrint(
            '[ReviewSummaryTable][WARN] ❌ Route is empty — navigation aborted.');
        return;
      }

      // 2) Build args for downstream focus/highlight
      final args = OnboardingNavigationUtils.buildOnboardingNavArgs(
        section: normalizedSection,
        issue: issue,
      );
      debugPrint('[ReviewSummaryTable] Built nav args → $args');

      // 3) Pre-load prerequisites for sections that need them
      try {
        if (normalizedSection == 'onboardingIngredients') {
          debugPrint(
              '[ReviewSummaryTable] 📦 Checking prerequisites for Ingredients…');

          final typeProvider = context.read<IngredientTypeProvider>();
          final metaProvider = context.read<IngredientMetadataProvider>();

          // Prefer an already-bound franchiseId on either provider
          String fid = typeProvider.franchiseId;
          if (fid.isEmpty || fid == 'unknown') {
            fid = metaProvider.franchiseId;
          }
          debugPrint('    franchiseId detected: "$fid"');

          // Ingredient Types (must exist for Ingredients screen)
          final typesCount = typeProvider.ingredientTypes.length;
          debugPrint('    IngredientTypes count: $typesCount');
          if (typesCount == 0) {
            debugPrint('    ➤ Loading Ingredient Types…');
            await typeProvider.loadIngredientTypes(fid);
            debugPrint(
                '    ✔ Ingredient Types loaded. New count: ${typeProvider.ingredientTypes.length}');
          }

          // Ingredient Metadata (screen uses provider.isInitialized + list)
          debugPrint(
              '    IngredientMetadata isInitialized: ${metaProvider.isInitialized}');
          debugPrint(
              '    IngredientMetadata count: ${metaProvider.ingredients.length}');
          if (!metaProvider.isInitialized || metaProvider.ingredients.isEmpty) {
            debugPrint('    ➤ Loading Ingredient Metadata…');
            await metaProvider.load();
            debugPrint(
                '    ✔ Ingredient Metadata loaded. New count: ${metaProvider.ingredients.length}');
          }
        } else if (normalizedSection == 'onboardingIngredientTypes') {
          debugPrint(
              '[ReviewSummaryTable] 📦 Checking prerequisites for Ingredient Types…');

          final typeProvider = context.read<IngredientTypeProvider>();
          String fid = typeProvider.franchiseId;
          if (fid.isEmpty || fid == 'unknown') {
            // Fallback: try from IngredientMetadataProvider (has final franchiseId)
            final metaProvider = context.read<IngredientMetadataProvider>();
            fid = metaProvider.franchiseId;
          }
          debugPrint('    franchiseId detected: "$fid"');

          final typesCount = typeProvider.ingredientTypes.length;
          debugPrint('    IngredientTypes count: $typesCount');
          if (typesCount == 0) {
            debugPrint('    ➤ Loading Ingredient Types…');
            await typeProvider.loadIngredientTypes(fid);
            debugPrint(
                '    ✔ Ingredient Types loaded. New count: ${typeProvider.ingredientTypes.length}');
          }
        }
      } catch (e, st) {
        debugPrint(
            '[ReviewSummaryTable][ERROR] ⚠ Failed while preloading prerequisites.');
        debugPrint('    Exception: $e');
        debugPrint('    Stacktrace: $st');
        // Continue to navigate; downstream screen may still guard itself.
      }

      // 4) Navigate after this frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[ReviewSummaryTable] 🚀 Navigating to → "$route"');
        Navigator.of(context).pushNamed(route, arguments: args);
      });
    }

    if (criticalCount > 0) {
      final issue = issues.firstWhere(
        (e) => e.isBlocking && e.severity == OnboardingIssueSeverity.critical,
        orElse: () => issues.first,
      );
      return _actionButton(
        label: issue.actionLabel?.isNotEmpty == true
            ? issue.actionLabel!
            : 'Fix Now',
        icon: Icons.build_circle_outlined,
        color: colorScheme.primary,
        onPressed: () => _navigateToFix(issue),
      );
    } else if (warningCount > 0) {
      final issue = issues.firstWhere(
        (e) => !e.isBlocking && e.severity == OnboardingIssueSeverity.warning,
        orElse: () => issues.first,
      );
      return _actionButton(
        label: issue.actionLabel?.isNotEmpty == true
            ? issue.actionLabel!
            : 'Review',
        icon: Icons.visibility_outlined,
        color: colorScheme.tertiary,
        onPressed: () => _navigateToFix(issue),
      );
    }

    return Text('—',
        style: TextStyle(color: colorScheme.outlineVariant, fontSize: 15),
        textAlign: TextAlign.center);
  }

  Widget _actionButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
