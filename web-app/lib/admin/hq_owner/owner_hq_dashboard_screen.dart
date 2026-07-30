import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_switcher_dropdown.dart';
import 'package:franchise_admin_portal/widgets/dashboard/franchise_picker_dropdown.dart';
import 'package:franchise_admin_portal/widgets/financials/franchise_financial_kpi_card.dart';
import 'package:franchise_admin_portal/widgets/financials/cash_flow_forecast_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/alerts_card.dart';
import 'package:franchise_admin_portal/widgets/profile/user_avatar_menu.dart';
import 'package:franchise_admin_portal/widgets/header/settings_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/help_icon_button.dart';
import 'package:franchise_admin_portal/widgets/header/notifications_icon_button.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/design_branding_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/screens/hq_onboarding_shell_screen.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider_impl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerHQDashboardScreen extends StatelessWidget {
  final String currentScreen;

  const OwnerHQDashboardScreen({
    super.key,
    this.currentScreen = 'hq-owner/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: true);
    final adminUserProvider =
        Provider.of<shared.AdminUserProvider>(context, listen: true);
    final adminUser = adminUserProvider.user;

    // Ensure initialization (defensive)
    if (adminUser != null &&
        (franchiseProvider.franchiseId == 'unknown' ||
            franchiseProvider.franchiseId.isEmpty)) {
      franchiseProvider.initializeWithUser(adminUser);
    }

    final franchiseId = franchiseProvider.franchiseId != 'unknown' &&
            franchiseProvider.franchiseId.isNotEmpty
        ? franchiseProvider.franchiseId
        : (adminUser?.defaultFranchise ??
            (adminUser?.franchiseIds?.isNotEmpty == true
                ? adminUser!.franchiseIds!.first
                : 'test'));

    final isMobile = MediaQuery.of(context).size.width < 800;
    final gridColumns = isMobile ? 1 : 3;
    final gap = isMobile ? 12.0 : 22.0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: DesignTokens.adminCardElevation,
        title: Row(
          key: ValueKey(
              'hq-appbar-branding-$franchiseId-${franchiseProvider.currentConfigVersion}'),
          children: [
            const SizedBox(width: 8),
            Icon(Icons.business_center_rounded,
                color: DesignTokens.primaryColor, size: 22),
            const SizedBox(width: 12),
            Text(
              loc.ownerHQDashboardTitle ?? "Franchise HQ Dashboard",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const Spacer(),
            FranchisePickerDropdown(),
            const SizedBox(width: 14),
            DashboardSwitcherDropdown(
              currentScreen: currentScreen,
              user: adminUser!,
            ),
            const SizedBox(width: 8),
            NotificationsIconButton(),
            const SizedBox(width: 8),
            HelpIconButton(),
            const SizedBox(width: 8),
            SettingsIconButton(),
            const SizedBox(width: 8),
            UserAvatarMenu(),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(gap),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: gridColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                // Slightly taller so Onboarding step list fits without clipping.
                childAspectRatio: isMobile ? 1.5 : 2.8,
                children: [
                  const QuickLinksPanel(),
                  AlertsCard(
                    key: ValueKey('hq-alerts-$franchiseId'),
                    franchiseId: franchiseId,
                    userId: adminUser?.id ?? '',
                  ),
                  PlatformBillingCard(
                    key: ValueKey('hq-platform-billing-$franchiseId'),
                    franchiseId: franchiseId,
                  ),
                  const LiveBrandingPreviewCard(),
                  const MultiBrandOverviewPanel(),
                  FranchiseFinancialKpiCard(
                    key: ValueKey('hq-kpi-$franchiseId'),
                    franchiseId: franchiseId,
                  ),
                  const OnboardingProgressCard(),
                  const CustomerCardPaymentsStatusCard(),
                  CashFlowForecastCard(franchiseId: franchiseId),
                ],
              ),
              SizedBox(height: gap),
              const FutureFeaturePlaceholderPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

// === Supporting Widgets (kept minimal & clean) ===

class MultiBrandOverviewPanel extends StatelessWidget {
  const MultiBrandOverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.multiBrandSnapshot ?? "Multi-Brand Overview",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DesignTokens.primaryColor,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Single-franchise view for this HQ. Multi-brand rollup is planned.',
              style: TextStyle(color: DesignTokens.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickLinksPanel extends StatelessWidget {
  const QuickLinksPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceVariant,
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.quickLinks ?? "Quick Links",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickLinkTile(
                  icon: Icons.checklist_outlined,
                  label: 'Onboarding',
                  onTap: () {
                    final p = Provider.of<OnboardingProgressProviderImpl>(
                        context,
                        listen: false);
                    final initialKey = !p
                            .isStepComplete('onboarding_feature_setup')
                        ? 'onboarding_feature_setup'
                        : !p.isStepComplete('onboarding_design_branding')
                            ? 'onboarding_design_branding'
                            : !p.isStepComplete('onboarding_menu_foundation')
                                ? 'onboarding_menu_foundation'
                                : !p.isStepComplete('onboardingMenuItems')
                                    ? 'onboardingMenuItems'
                                    : !p.isStepComplete('onboardingReview')
                                        ? 'onboardingReview'
                                        : 'onboardingMenu';
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HqOnboardingShellScreen(
                          initialSectionKey: initialKey,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(icon, color: DesignTokens.primaryColor),
        label: Text(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: DesignTokens.primaryColor.withOpacity(0.5)),
      ),
    );
  }
}

class FutureFeaturePlaceholderPanel extends StatelessWidget {
  const FutureFeaturePlaceholderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: DesignTokens.primaryColor),
            SizedBox(width: 8),
            Text(loc.comingSoonFeatures ?? "Future Features - Coming Soon",
                style: TextStyle(color: DesignTokens.secondaryTextColor)),
          ],
        ),
      ),
    );
  }
}

/// Thin platform → franchise SaaS billing story. MVP: visible, not navigable.
/// Platform → franchise SaaS invoices (read-only, in-card MVP).
class PlatformBillingCard extends StatefulWidget {
  final String franchiseId;

  const PlatformBillingCard({
    super.key,
    required this.franchiseId,
  });

  @override
  State<PlatformBillingCard> createState() => _PlatformBillingCardState();
}

class _PlatformBillingCardState extends State<PlatformBillingCard> {
  late Future<List<shared.PlatformInvoice>> _future;
  String? _loadedForFranchiseId;

  static const _outstandingStatuses = {
    'unpaid',
    'partial',
    'overdue',
    'open',
  };

  @override
  void initState() {
    super.initState();
    _loadedForFranchiseId = widget.franchiseId;
    _future = _load(widget.franchiseId);
  }

  @override
  void didUpdateWidget(covariant PlatformBillingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _loadedForFranchiseId = widget.franchiseId;
      setState(() {
        _future = _load(widget.franchiseId);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final providerId =
        Provider.of<shared.FranchiseProvider>(context, listen: true)
            .franchiseId;
    final effectiveId = (providerId.isNotEmpty && providerId != 'unknown')
        ? providerId
        : widget.franchiseId;
    if (_loadedForFranchiseId != effectiveId) {
      _loadedForFranchiseId = effectiveId;
      setState(() {
        _future = _load(effectiveId);
      });
    }
  }

  Future<List<shared.PlatformInvoice>> _load(String franchiseId) async {
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final list = await fs.getPlatformInvoicesForFranchisee(franchiseId);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  double _outstanding(List<shared.PlatformInvoice> invoices) {
    double sum = 0;
    for (final inv in invoices) {
      if (_outstandingStatuses.contains(inv.status.toLowerCase())) {
        sum += inv.amount;
      }
    }
    return sum;
  }

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long,
                    color: DesignTokens.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Platform billing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<shared.PlatformInvoice>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Failed to load invoices',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _future = _load(widget.franchiseId);
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }

                  final invoices = snapshot.data ?? [];
                  if (invoices.isEmpty) {
                    return Center(
                      child: Text(
                        'No platform invoices for this franchise.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DesignTokens.secondaryTextColor,
                        ),
                      ),
                    );
                  }

                  final outstanding = _outstanding(invoices);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: invoices.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 8,
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                          itemBuilder: (context, i) {
                            final inv = invoices[i];
                            final number = inv.invoiceNumber.isNotEmpty
                                ? inv.invoiceNumber
                                : inv.id;
                            return Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    number,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    inv.status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${inv.amount.toStringAsFixed(2)} ${inv.currency}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtDate(inv.dueDate),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: DesignTokens.secondaryTextColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Outstanding: ${outstanding.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.primaryColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ST2: Connect status honesty + onboarding / refresh callables.
class CustomerCardPaymentsStatusCard extends StatefulWidget {
  const CustomerCardPaymentsStatusCard({super.key});

  @override
  State<CustomerCardPaymentsStatusCard> createState() =>
      _CustomerCardPaymentsStatusCardState();
}

class _CustomerCardPaymentsStatusCardState
    extends State<CustomerCardPaymentsStatusCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? e.code),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOnboarding(String franchiseId) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('createConnectAccountLink');
    final result = await callable.call(<String, dynamic>{
      'franchiseId': franchiseId,
      'returnUrl': 'https://franchisehq.io/',
      'refreshUrl': 'https://franchisehq.io/',
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final url = data['url'] as String?;
    final accountId = data['accountId'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('No onboarding URL returned');
    }

    // Keep provider in sync so Refresh status enables on this tab.
    if (accountId != null && accountId.isNotEmpty) {
      final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
      final merged = Map<String, dynamic>.from(fp.currentBranding)
        ..['stripeConnectAccountId'] = accountId
        ..['paymentsEnabled'] = false;
      fp.setBrandingFromFranchiseDoc(merged);
    }

    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!ok) {
      throw StateError('Could not open Stripe onboarding link');
    }
  }

  Future<void> _refreshStatus(String franchiseId) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('refreshConnectAccountStatus');
    final result = await callable.call(<String, dynamic>{
      'franchiseId': franchiseId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final merged = Map<String, dynamic>.from(fp.currentBranding)
      ..['paymentsEnabled'] = data['paymentsEnabled'] == true
      ..['stripeConnectStatus'] = data['stripeConnectStatus']
      ..['stripeConnectAccountId'] = data['stripeConnectAccountId'];
    fp.setBrandingFromFranchiseDoc(merged);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          data['paymentsEnabled'] == true
              ? 'Card payments enabled'
              : 'Status updated — card payments still blocked',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = fp.franchiseId;
    final enabled = fp.paymentsEnabled;
    final accountId = fp.stripeConnectAccountId;
    final status = fp.stripeConnectStatus;
    final canAct = franchiseId.isNotEmpty && franchiseId != 'unknown';

    final String headline;
    final String detail;
    if (enabled) {
      headline = 'Card payments enabled';
      detail = status != null && status.isNotEmpty
          ? 'Connect status: $status'
          : 'Ready to accept customer card orders.';
    } else if (accountId != null && accountId.isNotEmpty) {
      headline = 'Connect onboarding incomplete';
      detail = status != null && status.isNotEmpty
          ? 'Status: $status — card checkout stays blocked.'
          : 'Account linked but not ready — card checkout blocked.';
    } else {
      headline = 'Card payments not set up';
      detail =
          'Customers cannot pay by card until Stripe Connect is completed.';
    }

    return Card(
      key: ValueKey('hq-card-payments-$franchiseId-${fp.currentConfigVersion}'),
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  enabled
                      ? Icons.check_circle_outline
                      : Icons.payments_outlined,
                  color: enabled
                      ? DesignTokens.primaryColor
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer card payments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              headline,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? DesignTokens.primaryColor
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: DesignTokens.secondaryTextColor,
              ),
            ),
            if (accountId != null && accountId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Account: $accountId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.secondaryTextColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: (!canAct || _busy)
                      ? null
                      : () => _run(() => _startOnboarding(franchiseId)),
                  child: Text(
                    accountId == null || accountId.isEmpty
                        ? 'Set up card payments'
                        : 'Continue onboarding',
                  ),
                ),
                TextButton(
                  onPressed: (!canAct || _busy)
                      ? null
                      : () => _run(() => _refreshStatus(franchiseId)),
                  child: const Text('Refresh status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiveBrandingPreviewCard extends StatelessWidget {
  const LiveBrandingPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = franchiseProvider.franchiseId;
    final theme = Theme.of(context);

    return Card(
      key: ValueKey(
          'hq-live-branding-$franchiseId-${franchiseProvider.currentConfigVersion}'),
      elevation: DesignTokens.adminCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: DesignTokens.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live Branding',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DesignTokens.currentAppName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryColor,
                    border: Border.all(
                        color: DesignTokens.cardBorderColor, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DesignTokens.secondaryColor,
                    border: Border.all(
                        color: DesignTokens.cardBorderColor, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DesignBrandingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.palette_outlined, size: 16),
                label: const Text('Open'),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.primaryColor,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingProgressCard extends StatelessWidget {
  const OnboardingProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProgressProviderImpl>(
      builder: (context, onboardingProgress, child) {
        final theme = Theme.of(context);

        if (onboardingProgress.loading) {
          return Card(
            elevation: DesignTokens.adminCardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final step1 =
            onboardingProgress.isStepComplete('onboarding_feature_setup');
        final stepBranding =
            onboardingProgress.isStepComplete('onboarding_design_branding');
        final step2 =
            onboardingProgress.isStepComplete('onboarding_menu_foundation');
        final step3 = onboardingProgress.isStepComplete('onboardingMenuItems');
        final step4 = onboardingProgress.isStepComplete('onboardingReview');
        final overall =
            [step1, stepBranding, step2, step3, step4].where((c) => c).length /
                5.0;

        final pendingStyle = theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.secondaryTextColor,
            ) ??
            const TextStyle();
        final doneStyle = theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.primaryColor,
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle();

        String status(bool done) => done ? 'Done' : 'Pending';

        return Card(
          elevation: DesignTokens.adminCardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onboarding',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: overall,
                  color: DesignTokens.primaryColor,
                  backgroundColor: DesignTokens.primaryColor.withOpacity(0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(overall * 100).round()}% · 5 steps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DesignTokens.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text('1. Feature Setup: ${status(step1)}',
                    style: step1 ? doneStyle : pendingStyle),
                Text('2. Design & Branding: ${status(stepBranding)}',
                    style: stepBranding ? doneStyle : pendingStyle),
                Text('3. Core Menu Foundation: ${status(step2)}',
                    style: step2 ? doneStyle : pendingStyle),
                Text('4. Menu Items: ${status(step3)}',
                    style: step3 ? doneStyle : pendingStyle),
                Text('5. Review & Publish: ${status(step4)}',
                    style: step4 ? doneStyle : pendingStyle),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      final String initialKey = !step1
                          ? 'onboarding_feature_setup'
                          : !stepBranding
                              ? 'onboarding_design_branding'
                              : !step2
                                  ? 'onboarding_menu_foundation'
                                  : !step3
                                      ? 'onboardingMenuItems'
                                      : !step4
                                          ? 'onboardingReview'
                                          : 'onboardingMenu';
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HqOnboardingShellScreen(
                            initialSectionKey: initialKey,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.checklist_outlined, size: 16),
                    label: const Text('Continue'),
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.primaryColor,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
