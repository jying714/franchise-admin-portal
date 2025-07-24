import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/ingredient_type_management_screen.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sortable_grid.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_form_card.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_list_tile.dart';

class OnboardingIngredientsScreen extends StatefulWidget {
  const OnboardingIngredientsScreen({super.key});

  @override
  State<OnboardingIngredientsScreen> createState() =>
      _OnboardingIngredientsScreenState();
}

class _OnboardingIngredientsScreenState
    extends State<OnboardingIngredientsScreen> {
  bool _hasLoaded = false;
  late FirestoreService firestoreService;
  late AppLocalizations loc;
  bool _hasLoadedIngredients = false;
  List<IngredientMetadata> _ingredients = [];
  bool _isLoading = false;
  bool get hasValidIngredients =>
      _ingredients.any((i) => i.typeId?.isNotEmpty == true);
  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final franchiseProvider = context.watch<FranchiseInfoProvider>();

    if (!_hasLoadedIngredients &&
        !franchiseProvider.loading &&
        franchiseProvider.franchise != null) {
      _hasLoadedIngredients = true;
      Future.microtask(() => _fetchIngredients());
    }
  }

  Future<void> _fetchIngredients() async {
    final franchise = context.read<FranchiseInfoProvider>().franchise;
    final franchiseId = franchise?.id ?? '';

    print('[FETCH INGREDIENTS] called — franchiseId = "$franchiseId"');

    if (franchiseId.isEmpty) {
      print('❌ Missing franchiseId from FranchiseInfoProvider');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final stream = firestoreService.streamIngredients(franchiseId);
      print('[FETCH INGREDIENTS] subscribing to stream...');
      stream.listen((data) {
        print('[FETCH INGREDIENTS] received ${data.length} ingredients');
        if (mounted) {
          setState(() {
            _ingredients = data;
            _isLoading = false;
          });
        }
      }, onError: (error, stack) async {
        print('[FETCH INGREDIENTS] stream error: $error');
        await ErrorLogger.log(
          message: 'Stream error in onboarding_ingredients_screen: $error',
          stack: stack.toString(),
          source: 'onboarding_ingredients_screen',
          screen: 'OnboardingIngredientsScreen',
          severity: 'error',
          contextData: {'franchiseId': franchiseId},
        );
        if (mounted) setState(() => _isLoading = false);
      });
    } catch (e, stack) {
      print('[FETCH INGREDIENTS] try/catch error: $e');
      await ErrorLogger.log(
        message: 'onboarding_ingredients_screen error: $e',
        stack: stack.toString(),
        source: 'onboarding_ingredients_screen',
        screen: 'OnboardingIngredientsScreen',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markComplete() async {
    if (!hasValidIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAddIngredientTypesFirst)),
      );
      return;
    }
    final onboardingProvider =
        Provider.of<OnboardingProgressProvider>(context, listen: false);
    await onboardingProvider.markStepComplete('ingredients');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.stepMarkedComplete)),
      );
    }
  }

  void _onSort(String key, bool ascending) {
    setState(() {
      _ingredients.sort((a, b) {
        int cmp;
        switch (key) {
          case 'name':
            cmp = a.name.compareTo(b.name);
            break;
          case 'description':
            cmp = (a.notes ?? '').compareTo(b.notes ?? '');
            break;
          default:
            cmp = 0;
        }
        return ascending ? cmp : -cmp;
      });
    });
  }

  void _openIngredientForm([IngredientMetadata? ingredient]) {
    showDialog(
      context: context,
      builder: (_) => IngredientFormCard(
        initialData: ingredient,
        onSaved: _fetchIngredients,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: loc.back,
        ),
        title: Text(
          loc.onboardingIngredients,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: loc.manageIngredientTypes,
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard?section=onboardingIngredientTypes',
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: loc.markAsComplete,
            onPressed: _markComplete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openIngredientForm(),
        icon: const Icon(Icons.add),
        label: Text(loc.addIngredient),
        backgroundColor: DesignTokens.primaryColor,
        heroTag: 'onboarding_ingredients_fab',
      ),
      body: _isLoading
          ? const LoadingShimmerWidget()
          : _ingredients.isEmpty
              ? EmptyStateWidget(
                  title: loc.noIngredientsFound,
                  message: loc.noIngredientsMessage,
                  // imageAsset: BrandingConfig.ingredientPlaceholder,
                )
              : Padding(
                  padding: DesignTokens.gridPadding,
                  child: AdminSortableGrid<IngredientMetadata>(
                    items: _ingredients,
                    columns: [loc.ingredientName, loc.ingredientDescription],
                    columnKeys: ['name', 'description'],
                    sortKeys: ['name', 'description'],
                    itemBuilder: (context, item) => IngredientListTile(
                      ingredient: item,
                      franchiseId:
                          context.read<FranchiseInfoProvider>().franchise?.id ??
                              '',
                      onEdited: () => _openIngredientForm(item),
                      onRefresh: _fetchIngredients,
                    ),
                    onSort: _onSort,
                  ),
                ),
    );
  }
}
