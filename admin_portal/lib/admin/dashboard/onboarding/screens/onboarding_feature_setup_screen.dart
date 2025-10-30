// File: lib/admin/dashboard/onboarding/screens/onboarding_feature_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/providers/franchise_feature_provider.dart';
import 'package:admin_portal/core/providers/franchise_info_provider.dart';
import 'package:admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/core/models/dashboard_section.dart';
import 'package:admin_portal/admin/dashboard/onboarding/widgets/feature_toggle_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingFeatureSetupScreen extends StatefulWidget {
  const OnboardingFeatureSetupScreen({super.key});

  @override
  State<OnboardingFeatureSetupScreen> createState() =>
      _OnboardingFeatureSetupScreenState();
}

class _OnboardingFeatureSetupScreenState
    extends State<OnboardingFeatureSetupScreen> {
  bool _isSaving = false;
  List<Map<String, dynamic>> _featureMetadata = [];
  String?
      _highlightFeatureKey; // Feature to highlight for deep-link error repair
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<FranchiseFeatureProvider>();
      await provider.initialize();

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('platform_features')
            .orderBy('name')
            .get();

        _featureMetadata = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .where((f) => f['deprecated'] != true)
            .toList();

        debugPrint(
            '[FeatureSetup] Loaded ${_featureMetadata.length} features from Firestore.');
      } catch (e, st) {
        await ErrorLogger.log(
          message: 'Failed to fetch platform_features from Firestore',
          stack: st.toString(),
          source: 'onboarding_feature_setup_screen.dart',
          screen: 'OnboardingFeatureSetupScreen',
        );
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accept navigation/focus argument from schema repair or review screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('featureKey')) {
      _highlightFeatureKey = args['featureKey'] as String?;
      // Defer scroll until after the next build/layout pass
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFeature(_highlightFeatureKey);
      });
    }
  }

  // Scrolls the list to the feature needing attention (for schema repair deep-link)
  void _scrollToFeature(String? featureKey) {
    if (featureKey == null) return;
    final index =
        _featureMetadata.indexWhere((meta) => meta['key'] == featureKey);
    if (index != -1 && _scrollController.hasClients) {
      // Each tile is roughly ~70-80px tall; tweak as needed for your UI
      final scrollPos =
          (index * 75.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        scrollPos,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final featureProvider = context.watch<FranchiseFeatureProvider>();
    final isInitialized = featureProvider.isInitialized;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          localizations.featureSetupTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: localizations.markAsComplete,
            onPressed: _markComplete,
          ),
        ],
      ),
      body: isInitialized
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    localizations.featureSetupDescription,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _featureMetadata
                        .where((meta) =>
                            meta['deprecated'] != true &&
                            meta['developerOnly'] != true)
                        .map((meta) {
                      final moduleKey = meta['key'];
                      final title = meta['name'] ?? moduleKey;
                      final description = meta['description'] ?? '';
                      final isLocked = !featureProvider.hasFeature(moduleKey);
                      final isHighlighted = moduleKey == _highlightFeatureKey;

                      return FeatureToggleTile(
                        moduleKey: moduleKey,
                        featureKey: 'enabled',
                        title: title,
                        description: description,
                        highlight:
                            isHighlighted, // Visually accent this tile if deep-linked
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: isInitialized
          ? FloatingActionButton.extended(
              heroTag: 'onboarding_feature_setup_fab',
              onPressed: _isSaving ? null : _handleSave,
              label: _isSaving
                  ? Text(localizations.saving)
                  : Text(localizations.save),
              icon: const Icon(Icons.save),
            )
          : null,
    );
  }

  /// Handles saving the current feature setup to Firestore and marking the onboarding step complete.
  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final featureProvider = context.read<FranchiseFeatureProvider>();
    final onboarding = context.read<OnboardingProgressProvider>();
    final franchiseId =
        context.read<FranchiseInfoProvider>().franchise?.id ?? 'unknown';

    try {
      final success = await featureProvider.persistToFirestore();

      if (success) {
        await onboarding.markStepComplete('onboarding_feature_setup');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saveSuccess),
            ),
          );
          Navigator.of(context)
              .maybePop(); // Go back or proceed to next onboarding step
        }
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.saveErrorTitle),
            content: Text(AppLocalizations.of(context)!.saveErrorBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              )
            ],
          ),
        );
      }
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to save onboarding features',
        stack: st.toString(),
        source: 'onboarding_feature_setup_screen.dart',
        screen: 'OnboardingFeatureSetupScreen',
        contextData: {'franchiseId': franchiseId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveErrorBody),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Allows toggling the onboarding step as complete/incomplete for workflow enforcement.
  Future<void> _markComplete() async {
    final loc = AppLocalizations.of(context)!;
    final onboardingProvider =
        Provider.of<OnboardingProgressProvider>(context, listen: false);

    final isCompleted =
        onboardingProvider.isStepComplete('onboarding_feature_setup');

    try {
      if (isCompleted) {
        await onboardingProvider.markStepIncomplete('onboarding_feature_setup');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedIncomplete)),
          );
        }
      } else {
        await onboardingProvider.markStepComplete('onboarding_feature_setup');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedComplete)),
          );
        }
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to toggle onboarding step "onboarding_feature_setup"',
        stack: stack.toString(),
        source: 'OnboardingFeatureSetupScreen',
        screen: 'onboarding_feature_setup_screen',
        severity: 'error',
        contextData: {'error': e.toString()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    }
  }
}
