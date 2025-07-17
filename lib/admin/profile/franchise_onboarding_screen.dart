import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

String roleToDashboardRoute(List<String> roles) {
  if (roles.contains('platform_owner')) return '/platform-owner/dashboard';
  if (roles.contains('hq_owner')) return '/hq-owner/dashboard';
  if (roles.contains('developer')) return '/developer/dashboard';
  return '/admin/dashboard';
}

class FranchiseOnboardingScreen extends StatefulWidget {
  final String? inviteToken; // Make nullable
  const FranchiseOnboardingScreen({super.key, this.inviteToken});

  @override
  State<FranchiseOnboardingScreen> createState() =>
      _FranchiseOnboardingScreenState();
}

class _FranchiseOnboardingScreenState extends State<FranchiseOnboardingScreen> {
  bool _loading = true;
  String? _loadError;
  Map<String, dynamic>? _inviteData;

  // Franchise profile fields
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _hoursController;
  String? _logoUrl;
  bool _saving = false;

  String? _effectiveToken;
  bool _didLoadToken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadToken) return;
    _didLoadToken = true;

    _effectiveToken = widget.inviteToken;
    if (_effectiveToken == null) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _effectiveToken = args['token'] as String?;
    }
    _fetchInvite();
  }

  Future<void> _fetchInvite() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    if (_effectiveToken == null || _effectiveToken!.isEmpty) {
      setState(() {
        _loadError = "No invite token found. Please use your invitation link.";
        _loading = false;
      });
      return;
    }
    try {
      final invite = await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).getFranchiseeInvitationByToken(_effectiveToken ?? '');
      if (invite == null) {
        setState(() {
          _loadError = AppLocalizations.of(context)!.unauthorized;
          _loading = false;
        });
        return;
      }
      _inviteData = invite;
      // Pre-fill from invite data if available
      _nameController =
          TextEditingController(text: invite['franchiseName'] ?? '');
      _addressController = TextEditingController(text: invite['address'] ?? '');
      _contactController = TextEditingController(text: invite['contact'] ?? '');
      _hoursController = TextEditingController(text: invite['hours'] ?? '');
      _logoUrl = invite['logoUrl'] as String?;
      setState(() => _loading = false);
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Error loading invite: $e',
        stack: st.toString(),
        source: 'FranchiseOnboardingScreen',
        screen: 'franchise_onboarding',
        severity: 'error',
      );
      setState(() {
        _loadError = AppLocalizations.of(context)!.failedToLoadData;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _loadError = null;
    });
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final userId = _inviteData?['invitedUserId'] as String?;
      if (userId == null) throw Exception('No user linked to invite.');
      final franchiseData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _contactController.text.trim(),
        'hours': _hoursController.text.trim(),
        'logoUrl': _logoUrl ?? '',
        'ownerId': userId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        // Add more fields as needed
      };
      // Write new franchise document
      final franchiseId = await firestore.createFranchiseProfile(
        franchiseData: franchiseData,
        invitedUserId: userId,
      );
      // Accept invitation via cloud function
      await firestore.callAcceptInvitationFunction(_effectiveToken ?? '');

      // Optionally route to dashboard or show success
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.account),
            content:
                Text(AppLocalizations.of(context)!.profileEditContactSupport),
            actions: [
              TextButton(
                onPressed: () {
                  final adminUserProvider =
                      Provider.of<AdminUserProvider>(context, listen: false);
                  final roles =
                      adminUserProvider.user?.roles?.cast<String>() ?? [];
                  final dashboardRoute = roleToDashboardRoute(roles);
                  Navigator.of(context).pushReplacementNamed(dashboardRoute);
                },
                child: Text(AppLocalizations.of(context)!.continueLabel),
              ),
            ],
          ),
        );
      }
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to save franchise profile: $e',
        stack: st.toString(),
        source: 'FranchiseOnboardingScreen',
        screen: 'franchise_onboarding',
        severity: 'error',
      );
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(loc.account),
        backgroundColor: colorScheme.surface,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Text(
                    _loadError!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: ListView(
                    children: [
                      DashboardSectionCard(
                        title: loc.accountDetails,
                        icon: Icons.store_mall_directory,
                        builder: (context) => _buildForm(context, loc),
                        showFuturePlaceholders: false,
                      ),
                      const SizedBox(height: 30),
                      _buildFutureFeaturesPlaceholder(
                          context, loc, colorScheme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.account,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: loc.name,
            prefixIcon: const Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: loc.address,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contactController,
          decoration: InputDecoration(
            labelText: loc.contactSupport,
            prefixIcon: const Icon(Icons.contact_phone),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hoursController,
          decoration: InputDecoration(
            labelText: loc.hours ?? 'Business Hours',
            prefixIcon: const Icon(Icons.access_time),
          ),
        ),
        const SizedBox(height: 20),
        // Logo upload could be added here
        // Add upload field or logo preview widget
        _saving
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: Text(loc.save),
                onPressed: _saveProfile,
              ),
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _loadError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildFutureFeaturesPlaceholder(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.futureFeatures,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 7),
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
