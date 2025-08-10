import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_metadata_template_picker_dialog.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_form_card.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_list_tile.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_metadata_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/missing_type_resolution_dialog.dart';

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

  void scrollAndHighlightIngredient(String ingredientId,
      {List<String>? focusFields}) {
    final provider = context.read<IngredientMetadataProvider>();

    // Ensure the item key exists (in case load() created items but keys not registered yet)
    final key =
        provider.itemGlobalKeys.putIfAbsent(ingredientId, () => GlobalKey());

    final contextWidget = key.currentContext;
    if (contextWidget == null || !mounted) {
      debugPrint(
          '[OnboardingIngredientsScreen] No visible context for $ingredientId — skipping highlight.');
      return;
    }

    // Scroll tile into view
    Scrollable.ensureVisible(
      contextWidget,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    // Highlight tile overlay
    final overlay = Overlay.of(context);
    final renderBox = contextWidget.findRenderObject() as RenderBox?;
    if (overlay != null && renderBox != null) {
      final highlightTile = OverlayEntry(
        builder: (_) => Positioned(
          left: renderBox.localToGlobal(Offset.zero).dx,
          top: renderBox.localToGlobal(Offset.zero).dy,
          width: renderBox.size.width,
          height: renderBox.size.height,
          child: IgnorePointer(
            child: Container(color: Colors.yellow.withOpacity(0.3)),
          ),
        ),
      );
      overlay.insert(highlightTile);
      Future.delayed(const Duration(seconds: 2), () => highlightTile.remove());
    }

    // Highlight specific fields if provided
    if (focusFields != null && focusFields.isNotEmpty) {
      for (final field in focusFields) {
        final fieldKey = provider.fieldGlobalKeys['$ingredientId::$field'];
        if (fieldKey != null && fieldKey.currentContext != null) {
          final box = fieldKey.currentContext!.findRenderObject() as RenderBox?;
          if (box != null && overlay != null) {
            final highlightField = OverlayEntry(
              builder: (_) => Positioned(
                left: box.localToGlobal(Offset.zero).dx,
                top: box.localToGlobal(Offset.zero).dy,
                width: box.size.width,
                height: box.size.height,
                child: IgnorePointer(
                  child: Container(color: Colors.orange.withOpacity(0.35)),
                ),
              ),
            );
            overlay.insert(highlightField);
            Future.delayed(
                const Duration(seconds: 2), () => highlightField.remove());
          }
        }
      }
    }
  }

  // Set to track selected ingredients for bulk actions
  final Set<String> _selectedIngredientIds = {};

  void _openIngredientForm([IngredientMetadata? ingredient]) {
    final loc = AppLocalizations.of(context);
    final provider =
        Provider.of<IngredientMetadataProvider>(context, listen: false);

    if (loc == null) {
      print('[OnboardingIngredientsScreen] ERROR: loc is null in FAB');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Get the providers from the parent context
        final ingredientProvider =
            Provider.of<IngredientMetadataProvider>(context, listen: false);
        final typeProvider =
            Provider.of<IngredientTypeProvider>(context, listen: false);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<IngredientMetadataProvider>.value(
                value: ingredientProvider),
            ChangeNotifierProvider<IngredientTypeProvider>.value(
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
    final provider = context.read<IngredientMetadataProvider>();
    final onboardingProvider = context.read<OnboardingProgressProvider>();

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
      await ErrorLogger.log(
        message: 'Failed to toggle onboarding step completion',
        stack: stack.toString(),
        source: '_markComplete',
        screen: 'onboarding_ingredients_screen',
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
      final provider = context.read<IngredientMetadataProvider>();
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
        await ErrorLogger.log(
          message: 'Bulk delete ingredients failed',
          source: 'OnboardingIngredientsScreen',
          screen: 'onboarding_ingredients_screen',
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
      List<IngredientMetadata> allIngredients, bool? checked) {
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final provider = context.read<IngredientMetadataProvider>();

    // Always load the provider first so keys exist
    provider.load().then((_) {
      if (args is Map && args.containsKey('focusItemId')) {
        final String focusId = args['focusItemId'] as String;
        final List<String>? focusFields =
            (args['focusFields'] as List?)?.cast<String>();

        // Wait until the widget tree is painted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollAndHighlightIngredient(focusId, focusFields: focusFields);
        });
      }
    });

    _hasInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    print('[OnboardingIngredientsScreen] build() called');

    try {
      final typeProvider =
          Provider.of<IngredientTypeProvider>(context, listen: false);
      print(
          '[OnboardingIngredientsScreen] IngredientTypeProvider FOUND: hashCode=${typeProvider.hashCode}');
    } catch (e) {
      print(
          '[OnboardingIngredientsScreen] IngredientTypeProvider NOT FOUND: $e');
    }

    try {
      loc = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final provider = context.watch<IngredientMetadataProvider>();
      print(
          '[OnboardingIngredientsScreen] IngredientMetadataProvider build() provider hashCode=${provider.hashCode}');
      print(
          '[Screen] build: provider.ingredients.length = ${provider.ingredients.length}');

      final groupedIngredients = provider.groupedIngredients;
      final allIngredientsFlat = provider.ingredients;

      final allSelected =
          _selectedIngredientIds.length == allIngredientsFlat.length &&
              allIngredientsFlat.isNotEmpty;
      final someSelected = _selectedIngredientIds.isNotEmpty && !allSelected;
      print(
          '[OnboardingIngredientsScreen] BUILD OK! INGREDIENTS: ${provider.ingredients.length}');
      try {
        print('[OnboardingIngredientsScreen] Scaffold building...');
        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: loc.back,
            ),
            title: Text(
              loc.onboardingIngredients,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: false,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.data_object),
                  tooltip: loc.importExport,
                  onPressed: () {
                    final provider = Provider.of<IngredientMetadataProvider>(
                        context,
                        listen: false);
                    IngredientMetadataJsonImportExportDialog.show(
                        context, provider);
                  },
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.library_add),
                  tooltip: loc.selectIngredientTemplate,
                  onPressed: () async {
                    print(
                        '[OnboardingIngredientsScreen] Template import button pressed');
                    final franchiseId =
                        context.read<FranchiseProvider>().franchiseId;

                    // 1. Let user select and load the template ingredients (returns list or null)
                    final List<IngredientMetadata>? templateIngredients =
                        await IngredientMetadataTemplatePickerDialog.show(
                            context);

                    if (templateIngredients == null ||
                        templateIngredients.isEmpty) return;

                    final typeProvider = context.read<IngredientTypeProvider>();
                    final existingTypeIds =
                        typeProvider.ingredientTypes.map((t) => t.id).toSet();

                    // 2. Find all imported ingredients with missing types
                    final ingredientsWithMissingTypes = templateIngredients
                        .where((ing) => !existingTypeIds.contains(ing.typeId))
                        .toList();

                    List<IngredientMetadata> allToImport = [];

                    if (ingredientsWithMissingTypes.isNotEmpty) {
                      // 3. Show resolution dialog, block until all are mapped or skipped
                      final resolved =
                          await showDialog<List<IngredientMetadata>>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => MissingTypeResolutionDialog(
                          ingredientsWithMissingTypes:
                              ingredientsWithMissingTypes,
                          availableTypes: typeProvider.ingredientTypes,
                          dialogContext: dialogContext,
                          onResolved: (fixed) {
                            Navigator.of(dialogContext)
                                .pop(fixed); // GOOD: local dialog context
                          },
                        ),
                      );

                      // Merge: valid+resolved
                      allToImport = [
                        ...templateIngredients.where(
                            (ing) => existingTypeIds.contains(ing.typeId)),
                        if (resolved != null) ...resolved,
                      ];
                    } else {
                      allToImport = templateIngredients;
                    }

                    // 4. Add resolved/valid ingredients to provider
                    if (allToImport.isNotEmpty) {
                      final metadataProvider =
                          context.read<IngredientMetadataProvider>();
                      print(
                          '[OnboardingIngredientsScreen] About to add ${allToImport.length} imported ingredients');
                      for (final ing in allToImport) {
                        print(
                            '[OnboardingIngredientsScreen][DEBUG] New ingredient: id=${ing.id}, typeId=${ing.typeId}, name=${ing.name}');
                        assert(ing.typeId != null && ing.typeId!.isNotEmpty,
                            'ingredient typeId must not be null/empty!');
                      }

                      metadataProvider.addImportedIngredients(allToImport);
                      print(
                          '[Provider] after add, ingredients.length=${metadataProvider.ingredients.length}, staged=${metadataProvider.stagedIngredients.length}');
                      for (final ing in metadataProvider.ingredients) {
                        print(
                            '[Provider][DEBUG] Stored ingredient: id=${ing.id}, typeId=${ing.typeId}, name=${ing.name}');
                        assert(ing.typeId != null && ing.typeId!.isNotEmpty,
                            'ingredient typeId must not be null/empty!');
                      }
                      print(
                          '[OnboardingIngredientsScreen] build() after template import and dialog resolution. Ingredients: ${provider.ingredients.length}');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        print(
                            '[OnboardingIngredientsScreen][STACK] ModalRoute.of(context): ${ModalRoute.of(context)}');
                        print(
                            '[OnboardingIngredientsScreen][STACK] context.mounted: $mounted');
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(loc.ingredientsImported(allToImport.length)),
                        ),
                      );
                    }
                  },
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: loc.markAsComplete,
                  onPressed: _markComplete,
                ),
              ),
            ],
          ),
          floatingActionButton: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              if (loc == null) {
                debugPrint(
                    '[OnboardingIngredientsScreen] ERROR: loc is null in FAB');
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
                if (provider.isDirty)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final franchiseId =
                              context.read<FranchiseProvider>().franchiseId;
                          final metadataProvider =
                              context.read<IngredientMetadataProvider>();
                          final onboardingProvider =
                              context.read<OnboardingProgressProvider>();

                          try {
                            await metadataProvider.saveAllChanges(franchiseId);
                            await onboardingProvider
                                .markStepComplete('ingredients');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.saveSuccessful)),
                            );
                          } catch (e, stack) {
                            await ErrorLogger.log(
                              message: 'ingredient_save_error',
                              stack: stack.toString(),
                              source: 'onboarding_ingredients_screen',
                              screen: 'onboarding_ingredients_screen',
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
                        onPressed: provider.revertChanges,
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
                      value: provider.groupByKey,
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem(
                            value: null, child: Text('None')),
                        DropdownMenuItem(value: 'type', child: Text(loc.type)),
                        DropdownMenuItem(
                            value: 'typeId', child: Text(loc.typeId)),
                      ],
                      onChanged: (val) {
                        provider.groupByKey = val;
                      },
                    ),
                    const SizedBox(width: 24),
                    Text(loc.sortBy + ': '),
                    DropdownButton<String>(
                      value: provider.sortKey,
                      items: [
                        DropdownMenuItem(value: 'name', child: Text(loc.name)),
                        DropdownMenuItem(
                            value: 'description', child: Text(loc.description)),
                        DropdownMenuItem(value: 'type', child: Text(loc.type)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          provider.sortKey = val;
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip:
                          provider.ascending ? loc.ascending : loc.descending,
                      icon: Icon(
                        provider.ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      onPressed: () {
                        provider.ascending = !provider.ascending;
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
                  child: provider.ingredients.isEmpty
                      ? EmptyStateWidget(
                          title: loc.noIngredientsFound,
                          message: loc.noIngredientsMessage,
                        )
                      : ListView(
                          controller: _scrollController,
                          children: groupedIngredients.entries.map((entry) {
                            print(
                                '[OnboardingIngredientsScreen] Building ingredient group: ${entry.key}');
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
                                                _selectedIngredientIds
                                                    .add(item.id);
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
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...groupItems.map((item) {
                                  final itemKey =
                                      provider.itemGlobalKeys[item.id] ??
                                          GlobalKey();
                                  provider.itemGlobalKeys[item.id] = itemKey;

                                  return Container(
                                    key:
                                        itemKey, // 🔹 assign key for scroll/highlight
                                    child: IngredientListTile(
                                      ingredient: item,
                                      franchiseId: provider.franchiseId,
                                      onEdited: () => _openIngredientForm(item),
                                      onRefresh: () => provider.load(),
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
      } catch (e, stack) {
        print('[OnboardingIngredientsScreen] CRITICAL BUILD ERROR: $e\n$stack');
        return Center(child: Text('Critical UI error: $e'));
      }
    } catch (e, stack) {
      print('[OnboardingIngredientsScreen] build error: $e\n$stack');
      return Center(child: Text('An error occurred: $e'));
    }
  }

  @override
  void dispose() {
    print('[OnboardingIngredientsScreen] DISPOSED');
    super.dispose();
  }
}
