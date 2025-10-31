import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../package:shared_core/src/core/models/onboarding_validation_issue.dart';
import '../package:shared_core/src/core/providers/onboarding_review_provider.dart';
import 'package:shared_core/src/core/utils/onboarding_navigation_utils.dart';

/// Displays an expandable issue detail panel for each onboarding section.
/// - Groups by severity (critical, warning, info)
/// - Supports direct navigation to item needing repair
/// - Fully theme and project integrated
class IssueDetailsExpansion extends StatefulWidget {
  /// The order and sections to show (should match summary table)
  final List<String> sectionOrder;

  const IssueDetailsExpansion({
    Key? key,
    this.sectionOrder = const [
      'Features',
      'Ingredient Types',
      'Ingredients',
      'Categories',
      'Menu Items',
    ],
  }) : super(key: key);

  @override
  State<IssueDetailsExpansion> createState() => _IssueDetailsExpansionState();
}

class _IssueDetailsExpansionState extends State<IssueDetailsExpansion> {
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(widget.sectionOrder.length, (_) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _logReviewState(context, at: 'initState');
    });
  }

  @override
  void didUpdateWidget(covariant IssueDetailsExpansion oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
        '[IssueDetailsExpansion][didUpdateWidget] oldSections=${oldWidget.sectionOrder} newSections=${widget.sectionOrder}');
    if (widget.sectionOrder.length != oldWidget.sectionOrder.length) {
      _expanded = List.generate(widget.sectionOrder.length, (_) => false);
      debugPrint(
          '[IssueDetailsExpansion][didUpdateWidget] Reset expanded to $_expanded');
      _logReviewState(context, at: 'didUpdateWidget:lengthChanged');
    } else {
      _logReviewState(context, at: 'didUpdateWidget');
    }
  }

  void _logReviewState(BuildContext context, {String at = ''}) {
    final reviewProvider =
        Provider.of<OnboardingReviewProvider>(context, listen: false);
    final issuesBySection = reviewProvider.allIssuesBySection;

    debugPrint('[IssueDetailsExpansion] $at '
        'sections=${widget.sectionOrder.length} '
        'expanded=${_expanded.length}:${_expanded} '
        'isPublishable=${reviewProvider.isPublishable} '
        'allIssuesKeys=${issuesBySection.keys.toList()}');

    for (final sec in widget.sectionOrder) {
      final list = issuesBySection[sec] ?? const <OnboardingValidationIssue>[];
      final crit = list
          .where((e) => e.severity == OnboardingIssueSeverity.critical)
          .length;
      final warn = list
          .where((e) => e.severity == OnboardingIssueSeverity.warning)
          .length;
      final info =
          list.where((e) => e.severity == OnboardingIssueSeverity.info).length;
      debugPrint('[IssueDetailsExpansion] $at section="$sec" '
          'total=${list.length} critical=$crit warning=$warn info=$info');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<OnboardingReviewProvider>(context);
    final issuesBySection = reviewProvider.allIssuesBySection;
    final colorScheme = Theme.of(context).colorScheme;

    _logReviewState(context, at: 'build:before');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 0),
      child: ExpansionPanelList(
        key: const ValueKey('IssueDetailsExpansionPanelList'),
        elevation: 1,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (idx, isOpen) {
          if (idx >= 0 && idx < _expanded.length) {
            setState(() => _expanded[idx] = !_expanded[idx]);
          } else {
            debugPrint(
                '[IssueDetailsExpansion][WARN] expansionCallback index out of range');
          }
        },
        animationDuration: const Duration(milliseconds: 200),
        children: [
          for (int i = 0; i < widget.sectionOrder.length; i++)
            _buildSectionPanel(
              context,
              widget.sectionOrder[i],
              issuesBySection[widget.sectionOrder[i]] ??
                  const <OnboardingValidationIssue>[],
              i,
              colorScheme,
            ),
        ],
      ),
    );
  }

  ExpansionPanel _buildSectionPanel(
    BuildContext context,
    String section,
    List<OnboardingValidationIssue> issues,
    int idx,
    ColorScheme colorScheme,
  ) {
    final criticals = issues
        .where((e) =>
            e.isBlocking && e.severity == OnboardingIssueSeverity.critical)
        .toList();
    final warnings = issues
        .where((e) =>
            !e.isBlocking && e.severity == OnboardingIssueSeverity.warning)
        .toList();
    final infos = issues
        .where((e) => e.severity == OnboardingIssueSeverity.info)
        .toList();

    return ExpansionPanel(
      canTapOnHeader: true,
      isExpanded: idx >= 0 && idx < _expanded.length && _expanded[idx],
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.92),
      headerBuilder: (context, isOpen) => ListTile(
        key: ValueKey('IssueDetailsHeader::$section'),
        dense: true,
        title: Text(
          section,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: colorScheme.primary,
            fontFamily: DesignTokens.fontFamily,
            letterSpacing: 0.1,
          ),
        ),
        subtitle: Row(
          children: [
            if (criticals.isNotEmpty)
              _buildSeverityCount(
                  Icons.cancel_rounded, colorScheme.error, criticals.length),
            if (warnings.isNotEmpty)
              _buildSeverityCount(Icons.warning_amber_rounded,
                  colorScheme.tertiary, warnings.length),
            if (infos.isNotEmpty)
              _buildSeverityCount(
                  Icons.info_outline, colorScheme.secondary, infos.length),
            if (criticals.isEmpty && warnings.isEmpty && infos.isEmpty)
              Text('No issues',
                  style: TextStyle(
                      color: Colors.green[700], fontWeight: FontWeight.w500)),
          ],
        ),
        onTap: () {
          if (idx >= 0 && idx < _expanded.length) {
            setState(() => _expanded[idx] = !_expanded[idx]);
          }
        },
      ),
      body: issues.isEmpty
          ? _buildNoIssuesBody(section)
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 20),
              child: Column(
                children: issues
                    .map((issue) =>
                        _buildIssueRow(context, section, issue, colorScheme))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildSeverityCount(IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 3),
          Text(
            '$count ${_severityLabel(icon)}${count > 1 ? 's' : ''}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _severityLabel(IconData icon) {
    if (icon == Icons.cancel_rounded) return 'critical';
    if (icon == Icons.warning_amber_rounded) return 'warning';
    return 'info';
  }

  Widget _buildNoIssuesBody(String section) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 28),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green[700], size: 22),
          const SizedBox(width: 9),
          Text(
            'No issues in $section.',
            style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
                fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueRow(
    BuildContext context,
    String section,
    OnboardingValidationIssue issue,
    ColorScheme colorScheme,
  ) {
    Color severityColor;
    IconData icon;
    switch (issue.severity) {
      case OnboardingIssueSeverity.critical:
        severityColor = colorScheme.error;
        icon = Icons.cancel_rounded;
        break;
      case OnboardingIssueSeverity.warning:
        severityColor = colorScheme.tertiary;
        icon = Icons.warning_amber_rounded;
        break;
      case OnboardingIssueSeverity.info:
      default:
        severityColor = colorScheme.secondary;
        icon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: severityColor.withOpacity(
              issue.severity == OnboardingIssueSeverity.critical ? 0.22 : 0.10),
          width: 1.2,
        ),
      ),
      color: colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.5, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: severityColor, size: 23),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.message,
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.7,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  if (issue.itemDisplayName.isNotEmpty ||
                      (issue.itemId.isNotEmpty &&
                          issue.itemDisplayName.isEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        issue.itemDisplayName.isNotEmpty
                            ? "Item: ${issue.itemDisplayName}"
                            : "ID: ${issue.itemId}",
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.65),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (issue.resolutionHint?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        issue.resolutionHint!,
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.64),
                          fontSize: 13.2,
                        ),
                      ),
                    ),
                  if (issue.affectedFields.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: issue.affectedFields
                            .map((f) => Chip(
                                  label: Text(f,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: colorScheme
                                              .onSecondaryContainer)),
                                  backgroundColor: colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.37),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            if (issue.actionLabel?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(left: 9.0, top: 2.0),
                child: TextButton.icon(
                  icon: Icon(Icons.open_in_new_rounded,
                      size: 18, color: severityColor),
                  label: Text(
                    issue.actionLabel!,
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.2,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  ),
                  onPressed: () {
                    debugPrint(
                        '[IssueDetailsExpansion] Attempting navigation...');
                    debugPrint('  Section (raw): "$section"');
                    debugPrint('  Issue.itemId: "${issue.itemId}"');
                    debugPrint('  Issue.itemLocator: "${issue.itemLocator}"');
                    debugPrint('  Issue.actionLabel: "${issue.actionLabel}"');
                    debugPrint(
                        '  Issue.affectedFields: ${issue.affectedFields}');

                    // âœ… Normalize section before navigation (fix)
                    final normalizedSection =
                        OnboardingNavigationUtils.normalizeForRouting(section);
                    debugPrint('  Normalized section: "$normalizedSection"');

                    final route = OnboardingNavigationUtils.resolveRoute(
                        normalizedSection, issue);
                    debugPrint('  Resolved route: "$route"');

                    if (route.isEmpty) {
                      debugPrint(
                          '[IssueDetailsExpansion][WARN] Route is empty â€” navigation aborted.');
                      return;
                    }

                    final args =
                        OnboardingNavigationUtils.buildOnboardingNavArgs(
                      section: normalizedSection,
                      issue: issue,
                    );
                    debugPrint('  Nav args: $args');

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushNamed(route, arguments: args);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


