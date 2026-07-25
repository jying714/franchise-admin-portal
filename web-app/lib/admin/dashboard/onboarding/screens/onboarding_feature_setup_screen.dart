import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/feature_toggle_tile.dart';
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
  String? _highlightFeatureKey;
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeatureMetadata();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('featureKey')) {
      _highlightFeatureKey = args['featureKey'] as String?;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFeature(_highlightFeatureKey);
      });
    }
  }

  Future<void> _loadFeatureMetadata() async {
    try {
      _loading = true;
      _error = null;
      setState(() {});

      final snapshot = await FirebaseFirestore.instance
          .collection('platform_features')
          .orderBy('name')
          .get();

      _featureMetadata = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((f) => f['deprecated'] != true)
          .toList();

      final provider =
          Provider.of<shared.FranchiseFeatureProvider>(context, listen: false);
      await provider.initialize();
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Failed to fetch platform_features from Firestore',
        stack: st.toString(),
        source: 'onboarding_feature_setup_screen.dart',
      );
      _error = e.toString();
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  void _scrollToFeature(String? featureKey) {
    if (featureKey == null) return;
    final index =
        _featureMetadata.indexWhere((meta) => meta['key'] == featureKey);
    if (index != -1 && _scrollController.hasClients) {
      final scrollPos =
          (index * 75.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(scrollPos,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(loc.featureSetupTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(loc.featureSetupTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading features',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadFeatureMetadata, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(loc.featureSetupTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: loc.markAsComplete,
            onPressed: _markComplete,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(loc.featureSetupDescription,
                style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _featureMetadata
                  .where((meta) => meta['developerOnly'] != true)
                  .map((meta) {
                final moduleKey = meta['key'];
                final title = meta['name'] ?? moduleKey;
                final description = meta['description'] ?? '';
                final isHighlighted = moduleKey == _highlightFeatureKey;

                return FeatureToggleTile(
                  moduleKey: moduleKey,
                  featureKey: 'enabled',
                  title: title,
                  description: description,
                  highlight: isHighlighted,
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'onboarding_feature_setup_fab',
        onPressed: _isSaving ? null : _handleSave,
        label: _isSaving ? Text(loc.saving) : Text(loc.save),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final featureProvider =
        Provider.of<shared.FranchiseFeatureProvider>(context, listen: false);
    final onboarding =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);
    final franchiseId =
        Provider.of<shared.FranchiseInfoProvider>(context, listen: false)
                .franchise
                ?.id ??
            'unknown';
    final loc = AppLocalizations.of(context)!;

    try {
      final success = await featureProvider.persistToFirestore();

      if (success && mounted) {
        await onboarding.markStepComplete('onboarding_feature_setup');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.saveSuccess)),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Failed to save onboarding features',
        stack: st.toString(),
        source: 'onboarding_feature_setup_screen.dart',
        contextData: {'franchiseId': franchiseId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.saveErrorBody),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _markComplete() async {
    final loc = AppLocalizations.of(context)!;
    final onboardingProvider =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);
    final isCompleted =
        onboardingProvider.isStepComplete('onboarding_feature_setup');

    try {
      if (isCompleted) {
        await onboardingProvider.markStepIncomplete('onboarding_feature_setup');
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(loc.stepMarkedIncomplete)));
      } else {
        await onboardingProvider.markStepComplete('onboarding_feature_setup');
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(loc.stepMarkedComplete)));
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to toggle onboarding step "onboarding_feature_setup"',
        stack: stack.toString(),
        source: 'OnboardingFeatureSetupScreen',
        severity: 'error',
        contextData: {'error': e.toString()},
      );
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.errorGeneric)));
    }
  }
}
