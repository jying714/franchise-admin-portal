import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_metadata_template_picker_dialog.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_form_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_list_tile.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_metadata_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/missing_type_resolution_dialog.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';

class OnboardingIngredientsScreen extends StatefulWidget {
  const OnboardingIngredientsScreen({super.key});

  @override
  State<OnboardingIngredientsScreen> createState() =>
      _OnboardingIngredientsScreenState();
}

class _OnboardingIngredientsScreenState
    extends State<OnboardingIngredientsScreen> {
  final ScrollController _scrollController = ScrollController();
  late AppLocalizations loc;
  bool _hasInitialized = false;
  final _listViewKey = GlobalKey();
  final Set<String> _highlightedIngredients = {};

  // Local-only keys for this screen instance (do NOT store in provider)
  final Map<String, GlobalKey> _itemKeys = {};
  final Map<String, GlobalKey> _fieldKeys =
      {}; // optional, used for field highlights

  // Handoff args from router â†’ this screen
  String? _focusIdFromArgs;
  List<String>? _focusFieldsFromArgs;
  bool _appliedFocusFromArgs = false;

  void _maybeApplyInitialFocus() {
    if (!mounted || _appliedFocusFromArgs != false) return;
    if (_focusIdFromArgs == null) return;

    final provider =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false);

    // Only try when items are present and the target exists
    if (provider.ingredients.isEmpty) return;
    final exists = provider.ingredients.any((e) => e.id == _focusIdFromArgs);
    if (!exists) return;

    // debugPrint(
    //   '[OnboardingIngredientsScreen] Applying initial focus to '
    //   'ingredientId="${_focusIdFromArgs}" fields=${_focusFieldsFromArgs}',
    // );

    _appliedFocusFromArgs = true; // guard: run exactly once

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      scrollAndHighlightIngredient(
        _focusIdFromArgs!,
        focusFields: _focusFieldsFromArgs,
      );
    });
  }

  void scrollAndHighlightIngredient(
    String ingredientId, {
    List<String>? focusFields,
  }) {
    // Use screen-local keys, not provider-level keys
    final key = _itemKeys.putIfAbsent(ingredientId, () => GlobalKey());
    final ctx = key.currentContext;

    if (ctx == null || !mounted) {
      // debugPrint(
      //   '[OnboardingIngredientsScreen] No visible context for $ingredientId â€” skipping highlight.',
      // );
      return;
    }

    // Scroll tile into view
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    // Tile highlight overlay
    final overlay = Overlay.of(context);
    final box = ctx.findRenderObject() as RenderBox?;
    if (overlay != null && box != null) {
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          left: box.localToGlobal(Offset.zero).dx,
          top: box.localToGlobal(Offset.zero).dy,
          width: box.size.width,
          height: box.size.height,
          child: IgnorePointer(
            child: Container(color: Colors.yellow.withOpacity(0.30)),
          ),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 2), entry.remove);
    }

    // Optional: highlight specific fields if our screen registered them
    if (focusFields != null && focusFields.isNotEmpty) {
      for (final field in focusFields) {
        final fKey = _fieldKeys['$ingredientId::$field'];
        final fCtx = fKey?.currentContext;
        if (fCtx == null) continue;
        final overlay2 = Overlay.of(context);
        final fBox = fCtx.findRenderObject() as RenderBox?;
        if (overlay2 != null && fBox != null) {
          final entry2 = OverlayEntry(
            builder: (_) => Positioned(
              left: fBox.localToGlobal(Offset.zero).dx,
              top: fBox.localToGlobal(Offset.zero).dy,
              width: fBox.size.width,
              height: fBox.size.height,
              child: IgnorePointer(
                child: Container(color: Colors.orange.withOpacity(0.35)),
              ),
            ),
          );
          overlay2.insert(entry2);
          Future.delayed(const Duration(seconds: 2), entry2.remove);
        }
      }
    }
  }

  // Set to track selected ingredients for bulk actions
  final Set<String> _selectedIngredientIds = {};

  void _openIngredientForm([shared.IngredientMetadata? ingredient]) {
    final loc = AppLocalizations.of(context);
    final provider =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false);

    if (loc == null) {
      // print('[OnboardingIngredientsScreen] ERROR: loc is null in FAB');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Get the providers from the parent context
        final ingredientProvider =
            Provider.of<IngredientMetadataProviderImpl>(context, listen: false);
        final typeProvider =
            Provider.of<IngredientTypeProviderImpl>(context, listen: false);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<IngredientMetadataProviderImpl>.value(
                value: ingredientProvider),
            ChangeNotifierProvider<IngredientTypeProviderImpl>.value(
                value: typeProvider),
          ],
          child: IngredientFormCard(
            initialData: ingredient,
            onSaved: () {
              Navigator.of(dialogContext).pop();
            },
            loc: loc,
            parentContext: context,
          ),
        );
      },
    );
  }

  Future<void> _markComplete() async {
    final provider =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false);
    final onboardingProvider =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);

    if (provider.ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAddIngredientTypesFirst)),
      );
      return;
    }

    final isCompleted = onboardingProvider.isStepComplete('ingredients');

    try {
      if (isCompleted) {
        await onboardingProvider.markStepIncomplete('ingredients');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedIncomplete)),
          );
        }
      } else {
        await onboardingProvider.markStepComplete('ingredients');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedComplete)),
          );
        }
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to toggle onboarding step completion',
        stack: stack.toString(),
        source: '_markComplete',
        severity: 'error',
        contextData: {'ingredientsCount': provider.ingredients.length},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedIngredientIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDeletion),
        content: Text(
          loc.bulkDeleteConfirmation(_selectedIngredientIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<shared.IngredientMetadataProvider>(context,
          listen: false);
      final deletedCount =
          _selectedIngredientIds.length; // Capture before clearing

      try {
        // Delete from Firestore and reload provider data
        await provider.bulkDeleteIngredientsFromFirestore(
            _selectedIngredientIds.toList());

        // Explicitly reload provider so UI updates
        await provider.load();

        // Clear selection BEFORE showing snackbar so count is accurate
        _selectedIngredientIds.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.bulkDeleteSuccess(deletedCount)),
            ),
          );
        }
      } catch (e, stack) {
        shared.ErrorLogger.log(
          message: 'Bulk delete ingredients failed',
          source: 'OnboardingIngredientsScreen',
          severity: 'error',
          stack: stack.toString(),
          contextData: {'selectedCount': deletedCount},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorGeneric)),
          );
        }
      }
      setState(() {}); // Refresh UI after clearing selections and loading data
    }
  }

  void _toggleSelectAll(
      List<shared.IngredientMetadata> allIngredients, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedIngredientIds.addAll(allIngredients.map((e) => e.id));
      } else {
        _selectedIngredientIds.clear();
      }
    });
  }

  void _toggleSelection(String ingredientId, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedIngredientIds.add(ingredientId);
      } else {
        _selectedIngredientIds.remove(ingredientId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    loc = AppLocalizations.of(context)!;

    // Capture router args ONCE
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _focusIdFromArgs = (args['focusItemId'] ??
          args['ingredientId'] ??
          args['itemId']) as String?;
      final fields = args['focusFields'];
      if (fields is List) _focusFieldsFromArgs = fields.cast<String>();
    }

    // Ensure providers exist before loading
    try {
      final metadataProvider = Provider.of<shared.IngredientMetadataProvider>(
          context,
          listen: false);
      final typeProvider =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false);

      metadataProvider.load(forceReloadFromFirestore: true).then((_) {
        if (!mounted) return;
        _maybeApplyInitialFocus();
        setState(() {}); // Safe UI refresh after load
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Provider access failed in didChangeDependencies',
        stack: stack.toString(),
        source: 'OnboardingIngredientsScreen',
        severity: 'error',
      );
    }

    _hasInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    // print('[OnboardingIngredientsScreen] build() called');

    loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Safe provider access with proper reactivity
    final metadataProvider =
        Provider.of<shared.IngredientMetadataProvider>(context);
    final typeProvider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);

    _maybeApplyInitialFocus();

    // print(
    //     '[OnboardingIngredientsScreen] IngredientMetadataProvider FOUND - Count: ${metadataProvider.ingredients.length}');
    // print('[OnboardingIngredientsScreen] IngredientTypeProvider FOUND');

    final groupedIngredients = metadataProvider.groupedIngredients;
    final allIngredientsFlat = metadataProvider.ingredients;

    final allSelected =
        _selectedIngredientIds.length == allIngredientsFlat.length &&
            allIngredientsFlat.isNotEmpty;
    final someSelected = _selectedIngredientIds.isNotEmpty && !allSelected;

    // print(
    //     '[OnboardingIngredientsScreen] BUILD OK! INGREDIENTS: ${metadataProvider.ingredients.length}');

    return Scaffold(
      floatingActionButton: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context);
          if (loc == null) {
            // debugPrint(
            //     '[OnboardingIngredientsScreen] ERROR: loc is null in FAB');
            return const SizedBox.shrink(); // Prevents crash
          }

          return FloatingActionButton.extended(
            onPressed: () => _openIngredientForm(),
            icon: const Icon(Icons.add),
            label: Text(loc.addIngredient),
            backgroundColor: DesignTokens.primaryColor,
            heroTag: 'onboarding_ingredients_fab',
          );
        },
      ),
      body: Padding(
        padding: DesignTokens.gridPadding,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.onboardingIngredients,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.library_add),
                    tooltip: loc.selectIngredientTemplate,
                    onPressed: () async {
                      final franchiseId = Provider.of<shared.FranchiseProvider>(
                              context,
                              listen: false)
                          .franchiseId;

                      final List<shared.IngredientMetadata>?
                          templateIngredients =
                          await IngredientMetadataTemplatePickerDialog.show(
                              context);

                      if (templateIngredients == null ||
                          templateIngredients.isEmpty) {
                        return;
                      }

                      final typeProvider =
                          Provider.of<shared.IngredientTypeProvider>(context,
                              listen: false);
                      final existingTypeIds =
                          typeProvider.ingredientTypes.map((t) => t.id).toSet();

                      final ingredientsWithMissingTypes = templateIngredients
                          .where((ing) => !existingTypeIds.contains(ing.typeId))
                          .toList();

                      List<shared.IngredientMetadata> allToImport = [];

                      if (ingredientsWithMissingTypes.isNotEmpty) {
                        final resolved =
                            await showDialog<List<shared.IngredientMetadata>>(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) =>
                              MissingTypeResolutionDialog(
                            ingredientsWithMissingTypes:
                                ingredientsWithMissingTypes,
                            availableTypes: typeProvider.ingredientTypes,
                            dialogContext: dialogContext,
                            onResolved: (fixed) {
                              Navigator.of(dialogContext).pop(fixed);
                            },
                          ),
                        );

                        allToImport = [
                          ...templateIngredients.where(
                              (ing) => existingTypeIds.contains(ing.typeId)),
                          if (resolved != null) ...resolved,
                        ];
                      } else {
                        allToImport = templateIngredients;
                      }

                      if (allToImport.isNotEmpty) {
                        final metadataProvider =
                            Provider.of<shared.IngredientMetadataProvider>(
                                context,
                                listen: false);
                        for (final ing in allToImport) {
                          assert(ing.typeId != null && ing.typeId!.isNotEmpty,
                              'ingredient typeId must not be null/empty!');
                        }

                        metadataProvider.addImportedIngredients(allToImport);
                        for (final ing in metadataProvider.ingredients) {
                          assert(ing.typeId != null && ing.typeId!.isNotEmpty,
                              'ingredient typeId must not be null/empty!');
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                loc.ingredientsImported(allToImport.length)),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (metadataProvider.isDirty)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final franchiseId = Provider.of<shared.FranchiseProvider>(
                              context,
                              listen: false)
                          .franchiseId;
                      final metadataProvider =
                          Provider.of<shared.IngredientMetadataProvider>(
                              context,
                              listen: false);
                      final onboardingProvider =
                          Provider.of<shared.OnboardingProgressProvider>(
                              context,
                              listen: false);

                      try {
                        await metadataProvider.saveAllChanges(franchiseId);
                        await onboardingProvider
                            .markStepComplete('ingredients');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.saveSuccessful)),
                        );
                      } catch (e, stack) {
                        shared.ErrorLogger.log(
                          message: 'ingredient_save_error',
                          stack: stack.toString(),
                          source: 'onboarding_ingredients_screen',
                          severity: 'error',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.saveFailed)),
                        );
                      }
                    },
                    child: Text(loc.saveChanges),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: metadataProvider.revertChanges,
                    child: Text(loc.revertChanges),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // --- Grouping & Sorting Controls ---
            Row(
              children: [
                Text(loc.groupBy + ': '),
                DropdownButton<String?>(
                  value: metadataProvider.groupByKey,
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'type', child: Text(loc.type)),
                    DropdownMenuItem(value: 'typeId', child: Text(loc.typeId)),
                  ],
                  onChanged: (val) {
                    metadataProvider.groupByKey = val;
                  },
                ),
                const SizedBox(width: 24),
                Text(loc.sortBy + ': '),
                DropdownButton<String>(
                  value: metadataProvider.sortKey,
                  items: [
                    DropdownMenuItem(value: 'name', child: Text(loc.name)),
                    DropdownMenuItem(
                        value: 'description', child: Text(loc.description)),
                    DropdownMenuItem(value: 'type', child: Text(loc.type)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      metadataProvider.sortKey = val;
                    }
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: metadataProvider.ascending
                      ? loc.ascending
                      : loc.descending,
                  icon: Icon(
                    metadataProvider.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    metadataProvider.ascending = !metadataProvider.ascending;
                  },
                )
              ],
            ),

            const SizedBox(height: 12),

            if (_selectedIngredientIds.isNotEmpty)
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: Text(loc.deleteSelected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _confirmBulkDelete,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIngredientIds.clear();
                      });
                    },
                    child: Text(loc.clearSelection),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            Expanded(
              child: metadataProvider.ingredients.isEmpty
                  ? EmptyStateWidget(
                      title: loc.noIngredientsFound,
                      message: loc.noIngredientsMessage,
                    )
                  : ListView(
                      controller: _scrollController,
                      children: groupedIngredients.entries.map((entry) {
                        // print(
                        //     '[OnboardingIngredientsScreen] Building ingredient group: ${entry.key}');
                        final groupName = entry.key ?? loc.ungrouped;
                        final groupItems = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: groupItems.every((item) =>
                                        _selectedIngredientIds
                                            .contains(item.id)),
                                    onChanged: (checked) {
                                      setState(() {
                                        for (final item in groupItems) {
                                          if (checked == true) {
                                            _selectedIngredientIds.add(item.id);
                                          } else {
                                            _selectedIngredientIds
                                                .remove(item.id);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    groupName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...groupItems.map((item) {
                              final itemKey = _itemKeys.putIfAbsent(
                                  item.id, () => GlobalKey());

                              return Container(
                                key: itemKey,
                                child: IngredientListTile(
                                  ingredient: item,
                                  franchiseId:
                                      Provider.of<shared.FranchiseProvider>(
                                              context,
                                              listen: false)
                                          .franchiseId,
                                  onEdited: () => _openIngredientForm(item),
                                  onRefresh: () => metadataProvider.load(),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // print('[OnboardingIngredientsScreen] DISPOSED');
    super.dispose();
  }
}
