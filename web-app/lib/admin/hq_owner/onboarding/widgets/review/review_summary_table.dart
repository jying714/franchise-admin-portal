import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // Phase 3 scoped fix
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/utils/onboarding_navigation_utils.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_review_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider_impl.dart';

class ReviewSummaryTable extends StatelessWidget {
  // Updated for 4-Step Onboarding
  static const List<String> _sectionOrder = [
    OnboardingSections.features,
    OnboardingSections.designBranding,
    OnboardingSections.coreMenuFoundation,
    OnboardingSections.menuItems,
    OnboardingSections.reviewPublish,
  ];

  const ReviewSummaryTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewProvider =
        Provider.of<OnboardingReviewProviderImpl>(context, listen: true);
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
    List<shared.OnboardingValidationIssue> issues,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Design & Branding is progress-key driven (no schema issues list).
    if (section == OnboardingSections.designBranding ||
        section == 'Design & Branding') {
      // Watch Impl (ChangeNotifier), not the abstract Proxy — so Save on Step 2 rebuilds Review.
      final brandingDone = Provider.of<OnboardingProgressProviderImpl>(context)
          .isStepComplete('onboarding_design_branding');
      final statusWidget = brandingDone
          ? _statusRow(
              Icons.check_circle_rounded, 'Complete', Colors.green[700]!,
              iconColor: Colors.green[600]!)
          : _statusRow(Icons.cancel_rounded, 'Incomplete', colorScheme.error);
      final issuesWidget = Text(
        brandingDone ? '0' : '1',
        style: TextStyle(
          color: brandingDone ? Colors.green[800] : colorScheme.error,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      );
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
        children: [sectionWidget, statusWidget, issuesWidget],
      );
    }

    final criticalCount = issues
        .where((e) =>
            e.isBlocking &&
            e.severity == shared.OnboardingIssueSeverity.critical)
        .length;
    final warningCount = issues
        .where((e) =>
            !e.isBlocking &&
            e.severity == shared.OnboardingIssueSeverity.warning)
        .length;

    final statusWidget =
        _buildStatusWidget(colorScheme, criticalCount, warningCount);
    final issuesWidget =
        _buildIssuesWidget(colorScheme, criticalCount, warningCount);

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
}
