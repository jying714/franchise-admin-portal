// File: lib/widgets/profile/universal_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/profile/account_details_panel.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invoice_list.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_payment_list.dart';
import 'package:franchise_admin_portal/core/models/platform_payment.dart';

// FUTURE: Modular import for payment methods and plan management
// import 'package:franchise_admin_portal/widgets/financials/payment_method_manager.dart';
// import 'package:franchise_admin_portal/widgets/support/support_contact_panel.dart';

class UniversalProfileScreen extends StatefulWidget {
  const UniversalProfileScreen({super.key});

  @override
  State<UniversalProfileScreen> createState() => _UniversalProfileScreenState();
}

class _UniversalProfileScreenState extends State<UniversalProfileScreen> {
  bool _loading = false;
  dynamic _billingData;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchBilling();
  }

  Future<void> _fetchBilling() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = Provider.of<AdminUserProvider>(context, listen: false).user;
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      if (user == null) {
        setState(() {
          _billingData = null;
          _loadError = null;
          _loading = false;
        });
        return;
      }

      // Role logic: get correct billing info
      if (user.isPlatformOwner == true) {
        // Platform owner: no personal billing, but could show org-wide info
        setState(() => _billingData = null);
      } else if (user.isFranchisee == true || user.roles.contains('hq_owner')) {
        // Franchisee or HQ Owner: show platform_invoices, platform_payments
        final invoices = await firestore.getPlatformInvoicesForUser(user.id);
        final payments = await firestore.getPlatformPaymentsForUser(user.id);
        setState(() => _billingData = {
              'invoices': invoices,
              'payments': payments,
            });
      } else if (user.isStoreOwner == true) {
        // Store owner: show direct store invoices/payments
        final invoices = await firestore.getStoreInvoicesForUser(user.id);
        setState(() => _billingData = {
              'invoices': invoices,
            });
      } else {
        setState(() => _billingData = null);
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'UniversalProfileScreen',
        screen: 'profile',
        severity: 'error',
      );
      setState(() {
        _loadError = AppLocalizations.of(context)!.failedToLoadData;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final user = Provider.of<AdminUserProvider>(context).user;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Access control: Developer/admin/platform only
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.account)),
        body: Center(child: Text(loc.unauthorized)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.account),
        actions: [
          // Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: CircleAvatar(
              radius: 20,
              backgroundImage:
                  user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                  ? Icon(Icons.person, color: colorScheme.onPrimary)
                  : null,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileBody(context, user, loc, colorScheme, isDark),
    );
  }

  Widget _buildProfileBody(BuildContext context, dynamic user,
      AppLocalizations loc, ColorScheme colorScheme, bool isDark) {
    // Modular dashboard sections
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AccountDetailsPanel(
          user: user,
          onProfileUpdated: () async {
            // Refresh user data from Firestore after save.
            final provider =
                Provider.of<AdminUserProvider>(context, listen: false);
            provider.listenToAdminUser(
              Provider.of<FirestoreService>(context, listen: false),
              user.id,
            );
          },
        ),
        const SizedBox(height: 28),

        // Role-based billing section
        if (user.isPlatformOwner == true)
          DashboardSectionCard(
            title: loc.platformOwner,
            icon: Icons.workspace_premium,
            builder: (context) =>
                _platformOwnerPanel(context, user, loc, colorScheme),
          ),
        if (user.isFranchisee == true || user.roles.contains('hq_owner'))
          DashboardSectionCard(
            title: loc.billingAndPayments,
            icon: Icons.receipt_long,
            builder: (context) =>
                _franchiseeBillingPanel(context, user, loc, colorScheme),
          ),
        if (user.isStoreOwner == true)
          DashboardSectionCard(
            title: loc.storeBilling,
            icon: Icons.store_mall_directory,
            builder: (context) =>
                _storeOwnerBillingPanel(context, user, loc, colorScheme),
          ),

        const SizedBox(height: 24),
        DashboardSectionCard(
          title: loc.securitySettings,
          icon: Icons.security,
          builder: (context) => _securityPanel(context, user, loc, colorScheme),
        ),
        const SizedBox(height: 24),
        DashboardSectionCard(
          title: loc.support,
          icon: Icons.support_agent,
          builder: (context) => _supportPanel(context, user, loc, colorScheme),
        ),

        // ---- Future Feature Placeholders ----
        const SizedBox(height: 40),
        _futureFeaturesPanel(context, loc, colorScheme),
      ],
    );
  }

  // ------------------ Profile Panels -------------------

  Widget _platformOwnerPanel(BuildContext context, dynamic user,
      AppLocalizations loc, ColorScheme colorScheme) {
    // FUTURE: Platform metrics, manage org, link to admin/finance screens.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.platformOwnerDescription,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, '/platform-owner/dashboard'),
          icon: const Icon(Icons.workspace_premium),
          label: Text(loc.goToPlatformAdmin),
        ),
        // Future: add org billing/metrics
      ],
    );
  }

  Widget _franchiseeBillingPanel(BuildContext context, dynamic user,
      AppLocalizations loc, ColorScheme colorScheme) {
    // Show platform_invoices & platform_payments for this franchisee
    final invoices = (_billingData?['invoices'] as List?) ?? [];
    final payments = (_billingData?['payments'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FranchiseeInvoiceList(invoices: invoices.cast()),
        const SizedBox(height: 14),
        FranchiseePaymentList(payments: payments.cast<PlatformPayment>()),
        // Future: payment methods, disputes, receipts
      ],
    );
  }

  Widget _storeOwnerBillingPanel(BuildContext context, dynamic user,
      AppLocalizations loc, ColorScheme colorScheme) {
    // Show store_invoices
    final invoices = (_billingData?['invoices'] as List?) ?? [];

    return invoices.isEmpty
        ? Text(loc.noBillingRecords,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)))
        : _invoiceListPanel(context, invoices, loc, colorScheme);
  }

  Widget _invoiceListPanel(BuildContext context, List invoices,
      AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.invoices,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        ...invoices.map((inv) => ListTile(
              leading: Icon(Icons.receipt_long, color: colorScheme.primary),
              title: Text(
                  '${loc.amount}: \$${inv['amount_due'] ?? inv['amount'] ?? '-'}'),
              subtitle: Text('${loc.status}: ${inv['status'] ?? '-'}'),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: colorScheme.secondary),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/hq/invoice_detail',
                  arguments: inv['id'],
                );
              },
            )),
      ],
    );
  }

  Widget _securityPanel(BuildContext context, dynamic user,
      AppLocalizations loc, ColorScheme colorScheme) {
    // Security: password, login info, etc.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.securityFeaturesComingSoon,
            style: TextStyle(color: colorScheme.onSurface)),
        const SizedBox(height: 10),
        // Future: change password, MFA, sessions, etc.
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_reset),
          label: Text(loc.resetPassword),
          onPressed: () {
            // TODO: Implement password reset/modal
          },
        ),
      ],
    );
  }

  Widget _supportPanel(BuildContext context, dynamic user, AppLocalizations loc,
      ColorScheme colorScheme) {
    // Support: contact, help links
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.needHelpContact,
            style: TextStyle(color: colorScheme.onSurface)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.support_agent),
          label: Text(loc.contactSupport),
          onPressed: () {
            // TODO: Show support dialog or open mailto:
          },
        ),
      ],
    );
  }

  Widget _futureFeaturesPanel(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    // Placeholders for expansion
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.futureFeatures, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(loc.paymentMethodManagementComing,
            style: TextStyle(color: colorScheme.onSurface)),
        Text(loc.downloadReceiptsExportComing,
            style: TextStyle(color: colorScheme.onSurface)),
        Text(loc.upgradePlanAddOnsComing,
            style: TextStyle(color: colorScheme.onSurface)),
      ],
    );
  }
}
