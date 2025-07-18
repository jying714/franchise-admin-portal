import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/widgets/business/business_hours_editor.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

String roleToDashboardRoute(List<String> roles) {
  if (roles.contains('platform_owner')) return '/platform-owner/dashboard';
  if (roles.contains('hq_owner')) return '/hq-owner/dashboard';
  if (roles.contains('developer')) return '/developer/dashboard';
  return '/admin/dashboard';
}

class FranchiseOnboardingScreen extends StatefulWidget {
  final String? inviteToken;
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
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _phoneController;
  late TextEditingController _supportPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _ownerController;
  late TextEditingController _einController;
  late TextEditingController _categoryController;
  String? _logoUrl;
  bool _saving = false;

  List<Map<String, dynamic>> _businessHours = [];

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
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final invite = await fs.getFranchiseeInvitationByToken(_effectiveToken!);
      if (invite == null) {
        setState(() {
          _loadError = AppLocalizations.of(context)!.unauthorized;
          _loading = false;
        });
        return;
      }
      _inviteData = invite;

      // Prefill all fields with whatever is available
      _nameController =
          TextEditingController(text: invite['franchiseName'] ?? '');
      _addressController = TextEditingController(text: invite['address'] ?? '');
      _cityController = TextEditingController(text: invite['city'] ?? '');
      _stateController = TextEditingController(text: invite['state'] ?? '');
      _zipController = TextEditingController(text: invite['zip'] ?? '');
      _phoneController = TextEditingController(
          text: invite['phone'] ?? invite['contact'] ?? '');
      _supportPhoneController =
          TextEditingController(text: invite['supportPhone'] ?? '');
      _emailController = TextEditingController(
          text: invite['businessEmail'] ?? invite['email'] ?? '');
      _websiteController = TextEditingController(text: invite['website'] ?? '');
      _ownerController = TextEditingController(text: invite['ownerName'] ?? '');
      _einController = TextEditingController(text: invite['EIN'] ?? '');
      _categoryController =
          TextEditingController(text: invite['category'] ?? '');

      // If franchiseId is pre-assigned, try to fetch hours for it
      final franchiseId = invite['franchiseId'] ?? '';
      if (franchiseId != null && franchiseId.toString().isNotEmpty) {
        _businessHours = await fs.getFranchiseBusinessHours(franchiseId);
      } else {
        _businessHours = [];
      }

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
        'address': {
          'street': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zip': _zipController.text.trim(),
        },
        'phone': _phoneController.text.trim(),
        'supportPhone': _supportPhoneController.text.trim(),
        'businessEmail': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'ownerName': _ownerController.text.trim(),
        'EIN': _einController.text.trim(),
        'category': _categoryController.text.trim(),
        'logoUrl': _logoUrl ?? '',
        'ownerId': userId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

      // Write/merge new franchise document
      final franchiseId = await firestore.createFranchiseProfile(
        franchiseData: franchiseData,
        invitedUserId: userId,
      );
      // Save business hours with new modular method
      await firestore.saveFranchiseBusinessHours(
        franchiseId: franchiseId,
        hours: _businessHours,
      );
      // Accept invitation via cloud function
      await firestore.callAcceptInvitationFunction(_effectiveToken ?? '');

// ✅ Update user's franchiseIds and claims via callable function
      await firestore.updateUserClaims(
        uid: userId,
        franchiseIds: [franchiseId],
        roles: [], // preserve existing roles
        additionalClaims: {
          'defaultFranchise': franchiseId, // ✅ NEW
        },
      );

// Optionally mirror this to Firestore directly, if not handled inside the function:
      await firestore.updateUserProfile(userId, {
        'completeProfile': true,
        'isActive': true,
        'status': 'active',
        'defaultFranchise': franchiseId,
        'franchiseIds': [franchiseId],
      });
      // Clear invite token for proper login without token
      Provider.of<AuthService>(context, listen: false).clearInviteToken();

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
                  if (kIsWeb) {
                    html.window.location.hash = '';
                  }
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
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
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
            labelText: loc.streetAddress ?? "Street Address",
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: loc.city,
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: loc.state,
                  prefixIcon: const Icon(Icons.map),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _zipController,
                decoration: InputDecoration(
                  labelText: loc.zip,
                  prefixIcon: const Icon(Icons.local_post_office),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: loc.phone ?? "Primary Phone",
            prefixIcon: const Icon(Icons.phone),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _supportPhoneController,
          decoration: InputDecoration(
            labelText: loc.contactSupport,
            prefixIcon: const Icon(Icons.support_agent),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: loc.businessEmail ?? "Business Email",
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _websiteController,
          decoration: InputDecoration(
            labelText: loc.website ?? "Website",
            prefixIcon: const Icon(Icons.public),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ownerController,
          decoration: InputDecoration(
            labelText: loc.ownerName ?? "Owner Name",
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _einController,
          decoration: InputDecoration(
            labelText: loc.taxIdEIN ?? "Tax ID (EIN)",
            prefixIcon: const Icon(Icons.badge),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _categoryController,
          decoration: InputDecoration(
            labelText: loc.businessType ?? "Business Category",
            prefixIcon: const Icon(Icons.category),
          ),
        ),
        const SizedBox(height: 24),
        Text(loc.hours ?? "Business Hours",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: 10),
        // --- The business hours editor widget ---
        BusinessHoursEditor(
          initialHours: _businessHours,
          onChanged: (val) => _businessHours = val,
        ),
        const SizedBox(height: 24),
        // --- Logo upload/preview would go here ---
        // (Placeholder for future image upload)
        _saving
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: Text(loc.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
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
