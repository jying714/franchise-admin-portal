import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_type_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/editable_ingredient_type_row.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/inline_add_ingredient_type_row.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_type_json_import_export_dialog.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';

class IngredientTypeManagementScreen extends StatefulWidget {
  const IngredientTypeManagementScreen({super.key});

  @override
  State<IngredientTypeManagementScreen> createState() =>
      _IngredientTypeManagementScreenState();
}

class _IngredientTypeManagementScreenState
    extends State<IngredientTypeManagementScreen> {
  String? franchiseId;
  bool _showSelectAllBanner = false;
  bool _hasLoaded = false;
  bool _hasInitialized = false;
  final Map<String, bool> _editingMap = {};
  bool _reorderChanged = false;
  List<shared.IngredientType> _pendingReorder = [];

  bool get _isEditingAny => _editingMap.values.any((v) => v == true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newFranchiseId =
        context.watch<shared.FranchiseProvider>().franchiseId;

    if (newFranchiseId != franchiseId) {
      franchiseId = newFranchiseId;
      _hasLoaded = false;
      _hasInitialized = false;
    }

    if (!_hasLoaded &&
        franchiseId != null &&
        franchiseId!.isNotEmpty &&
        franchiseId != 'unknown') {
      _hasLoaded = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final provider =
            Provider.of<shared.IngredientTypeProvider>(context, listen: false);
        await provider.load(
          franchiseIdOverride: franchiseId!,
          forceReloadFromFirestore: true,
        );
        if (mounted) setState(() {}); // Force Consumer rebuild
      });
    }
  }

  Future<void> _refreshIngredientTypes() async {
    if (franchiseId == null || franchiseId!.isEmpty) return;

    final provider =
        Provider.of<IngredientTypeProviderImpl>(context, listen: false);
    await provider.load(
      franchiseIdOverride: franchiseId!,
      forceReloadFromFirestore: true,
    );

    // Force Consumer rebuild
    if (mounted) {
      setState(() {});
    }
  }

  void _showFormDialog({shared.IngredientType? initial}) {
    final loc = AppLocalizations.of(context);
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;

    if (loc == null || franchiseId.isEmpty) return;

    final ingredientTypeProvider =
        Provider.of<IngredientTypeProviderImpl>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider<IngredientTypeProviderImpl>.value(
          value: ingredientTypeProvider,
          child: IngredientTypeFormDialog(
            loc: loc,
            franchiseId: franchiseId,
            initial: initial,
          ),
        );
      },
    ).then((_) {
      _refreshIngredientTypes();
    });
  }

  Future<void> _markComplete() async {
    final loc = AppLocalizations.of(context)!;
    final onboardingProvider =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);
    final provider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);

    if (provider.ingredientTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAddIngredientTypesFirst)),
      );
      return;
    }

    final isCompleted = onboardingProvider.isStepComplete('ingredientTypes');

    try {
      if (isCompleted) {
        await onboardingProvider.markStepIncomplete('ingredientTypes');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedIncomplete)),
          );
        }
      } else {
        await onboardingProvider.markStepComplete('ingredientTypes');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.stepMarkedComplete)),
          );
        }
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to toggle onboarding step "ingredientTypes"',
        stack: stack.toString(),
        source: 'OnboardingIngredientTypeScreen',
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

  Future<void> _persistReorder() async {
    final provider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);
    try {
      await provider.reorderIngredientTypes(franchiseId!, _pendingReorder);
      await provider.load(
          franchiseIdOverride: franchiseId!, forceReloadFromFirestore: true);
      setState(() {
        _reorderChanged = false;
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to persist ingredient type reorder',
        source: 'IngredientTypeManagementScreen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
    }
  }

  void _cancelReorder() {
    setState(() {
      _reorderChanged = false;
    });
    final provider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);
    provider.load(
        franchiseIdOverride: franchiseId!, forceReloadFromFirestore: true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.ingredientTypes,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: loc.importExport,
            onPressed: () {
              final typeProvider = Provider.of<shared.IngredientTypeProvider>(
                  context,
                  listen: false);
              IngredientTypeJsonImportExportDialog.show(context, typeProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_add),
            tooltip: loc.loadDefaultTypes,
            onPressed: () async {
              final parentLoc = AppLocalizations.of(context);
              if (parentLoc == null) return;

              await showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return Localizations.override(
                    context: dialogContext,
                    child: Builder(
                      builder: (innerContext) {
                        return ScaffoldMessenger(
                          child: IngredientTypeTemplatePickerDialog(
                              loc: parentLoc),
                        );
                      },
                    ),
                  );
                },
              );

              // Force refresh after dialog closes
              await _refreshIngredientTypes();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(parentLoc.templateLoadedSuccessfully)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: loc.markAsComplete,
            onPressed: _markComplete,
          ),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: colorScheme.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'onboarding_ingredient_type_fab',
        onPressed: () => _showFormDialog(),
        label: Text(loc.addIngredientType),
        icon: const Icon(Icons.add),
        backgroundColor: DesignTokens.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Consumer<shared.IngredientTypeProvider>(
          builder: (context, provider, child) {
            final types = provider.ingredientTypes;

            if (franchiseId == null || franchiseId!.isEmpty) {
              return Center(child: Text(loc.selectAFranchiseFirst));
            }

            return Column(
              children: [
                if (types.isEmpty)
                  Expanded(
                    child: Center(
                      child: EmptyStateWidget(
                        title: loc.noIngredientTypesFound,
                        message: loc.noIngredientsMessage ??
                            "No ingredient types defined yet. Add some to continue.",
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        const InlineAddIngredientTypeRow(),
                        if (_showSelectAllBanner)
                          Card(
                            color: Colors.amber[100],
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      loc.selectAllPrompt,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.select_all),
                                    label: Text(loc.selectAll),
                                    onPressed: () {
                                      final allIds = provider.ingredientTypes
                                          .map((t) => t.id!)
                                          .toList();
                                      for (final id in allIds) {
                                        provider.stageTypeForDelete(id);
                                      }
                                      setState(() {
                                        _showSelectAllBanner = false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    child: Text(loc.cancel),
                                    onPressed: () {
                                      setState(() {
                                        _showSelectAllBanner = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (provider.hasStagedDeletes)
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await provider
                                      .commitStagedDeletes(franchiseId!);
                                  setState(() {});
                                },
                                child: Text(loc.saveChanges),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  provider.clearStagedDeletes();
                                  setState(() {});
                                },
                                child: Text(loc.revertChanges),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                '${provider.stagedForDelete.length} ${loc.toDelete}',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        if (_reorderChanged)
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _persistReorder,
                                child: Text(loc.saveChanges),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _cancelReorder,
                                child: Text(loc.revertChanges),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) async {
                              if (provider.ingredientTypes.isEmpty ||
                                  oldIndex == newIndex) return;

                              final updatedList =
                                  List<shared.IngredientType>.from(
                                      provider.ingredientTypes);

                              if (newIndex > oldIndex) newIndex -= 1;

                              final movedItem = updatedList.removeAt(oldIndex);
                              updatedList.insert(newIndex, movedItem);

                              for (int i = 0; i < updatedList.length; i++) {
                                updatedList[i] =
                                    updatedList[i].copyWith(sortOrder: i);
                              }

                              await provider.reorderIngredientTypes(
                                  franchiseId!, updatedList);

                              setState(() {
                                _reorderChanged = true;
                                _pendingReorder = updatedList;
                              });
                            },
                            itemCount: types.length,
                            itemBuilder: (_, index) {
                              final type = types[index];
                              if (provider.stagedForDelete.contains(type.id)) {
                                return Container(
                                  key: ValueKey('deleted_${type.id}'),
                                  color: Colors.red.withOpacity(0.07),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      const SizedBox(width: 10),
                                      Text(
                                        type.name,
                                        style: TextStyle(
                                          color: Colors.red,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.undo),
                                        tooltip: loc.undo,
                                        onPressed: () => setState(() {
                                          provider
                                              .unstageTypeForDelete(type.id!);
                                        }),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ReorderableDragStartListener(
                                key: ValueKey(type.id!),
                                index: index,
                                enabled: !_isEditingAny,
                                child: EditableIngredientTypeRow(
                                  type: type,
                                  isEditing: _editingMap[type.id!] == true,
                                  onEditTapped: () {
                                    setState(() {
                                      _editingMap[type.id!] = true;
                                    });
                                  },
                                  onDeleteTapped: () async {
                                    final inUse =
                                        await provider.isIngredientTypeInUse(
                                      franchiseId: franchiseId!,
                                      typeId: type.id!,
                                    );

                                    if (inUse) {
                                      if (!context.mounted) return;
                                      await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(loc.deletionBlocked),
                                          content: Text(
                                              loc.ingredientTypeInUseError),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(loc.ok),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    provider.stageTypeForDelete(type.id!);
                                    setState(() {});
                                  },
                                  onSaveTapped: () async {
                                    await provider.load(
                                        franchiseIdOverride: franchiseId!,
                                        forceReloadFromFirestore: true);
                                    setState(() {
                                      _editingMap[type.id!] = false;
                                    });
                                  },
                                  trailing: Checkbox(
                                    value: provider.stagedForDelete
                                        .contains(type.id),
                                    onChanged: (selected) {
                                      if (selected == true) {
                                        provider.stageTypeForDelete(type.id!);
                                        if (provider.stagedForDelete.length ==
                                            1) {
                                          setState(() {
                                            _showSelectAllBanner = true;
                                          });
                                        }
                                      } else {
                                        provider.unstageTypeForDelete(type.id!);
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class IngredientTypeFormDialog extends StatefulWidget {
  final shared.IngredientType? initial;
  final String franchiseId;
  final AppLocalizations loc;

  const IngredientTypeFormDialog({
    Key? key,
    this.initial,
    required this.franchiseId,
    required this.loc,
  }) : super(key: key);

  @override
  State<IngredientTypeFormDialog> createState() =>
      _IngredientTypeFormDialogState();
}

class _IngredientTypeFormDialogState extends State<IngredientTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  String? description;
  String? systemTag;
  int sortOrder = 1;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = initial?.name ?? '';
    description = initial?.description;
    systemTag = initial?.systemTag;
    sortOrder = initial?.sortOrder ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final colorScheme = Theme.of(context).colorScheme;
    final provider =
        Provider.of<IngredientTypeProviderImpl>(context, listen: false);

    return AlertDialog(
      title: Text(widget.initial == null
          ? widget.loc.addIngredientType
          : widget.loc.editIngredientType),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: widget.loc.name),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? widget.loc.required
                    : null,
                onChanged: (val) => name = val,
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: widget.loc.description),
                onChanged: (val) => description = val,
              ),
              TextFormField(
                initialValue: systemTag,
                decoration: InputDecoration(labelText: widget.loc.systemTag),
                onChanged: (val) => systemTag = val,
              ),
              TextFormField(
                initialValue: sortOrder.toString(),
                decoration: InputDecoration(labelText: widget.loc.sortOrder),
                keyboardType: TextInputType.number,
                onChanged: (val) => sortOrder = int.tryParse(val) ?? sortOrder,
              ),
              // ðŸ’¡ Future Feature Placeholder: Add visibility toggle, tag color, etc.
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.loc.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() != true) return;

            final newType = shared.IngredientType(
              id: widget.initial?.id,
              name: name.trim(),
              description: description?.trim(),
              systemTag: systemTag?.trim(),
              sortOrder: sortOrder,
            );

            try {
              if (newType.id == null) {
                await provider.createType(widget.franchiseId, newType);
              } else {
                await provider.updateIngredientType(widget.franchiseId,
                    newType.id!, newType.toMap() // or appropriate update map
                    );
              }
              if (mounted) Navigator.of(context).pop();
            } catch (e, stack) {
              shared.ErrorLogger.log(
                message: 'Failed to save ingredient type',
                source: 'IngredientTypeFormDialog',
                severity: 'error',
                stack: stack.toString(),
                contextData: {
                  'franchiseId': widget.franchiseId,
                  'ingredientType': newType.toMap(),
                },
              );
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
