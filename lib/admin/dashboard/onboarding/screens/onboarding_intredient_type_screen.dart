import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_type_template_picker_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/editable_ingredient_type_row.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/inline_add_ingredient_type_row.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/ingredients/ingredient_type_json_import_export_dialog.dart';

class IngredientTypeManagementScreen extends StatefulWidget {
  const IngredientTypeManagementScreen({super.key});

  @override
  State<IngredientTypeManagementScreen> createState() =>
      _IngredientTypeManagementScreenState();
}

class _IngredientTypeManagementScreenState
    extends State<IngredientTypeManagementScreen> {
  String? franchiseId;
  bool _hasLoaded = false;
  final Map<String, bool> _editingMap = {};
  bool _reorderChanged = false;
  List<IngredientType> _pendingReorder = [];

  bool get _isEditingAny => _editingMap.values.any((v) => v == true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newFranchiseId = context.watch<FranchiseProvider>().franchiseId;
    if (newFranchiseId != franchiseId) {
      franchiseId = newFranchiseId;
    }

    if (!_hasLoaded &&
        franchiseId != null &&
        franchiseId!.isNotEmpty &&
        franchiseId != 'unknown') {
      _hasLoaded = true;

      Future.microtask(() {
        final provider =
            Provider.of<IngredientTypeProvider>(context, listen: false);
        provider.loadTypes(franchiseId!);
      });
    }
  }

  void _showFormDialog({IngredientType? initial}) {
    showDialog(
      context: context,
      builder: (context) => IngredientTypeFormDialog(
        initial: initial,
        franchiseId: franchiseId!,
      ),
    );
  }

  Future<void> _markComplete() async {
    final loc = AppLocalizations.of(context)!;
    final onboardingProvider =
        Provider.of<OnboardingProgressProvider>(context, listen: false);
    final provider =
        Provider.of<IngredientTypeProvider>(context, listen: false);

    if (provider.types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAddIngredientTypesFirst)),
      );
      return;
    }

    await onboardingProvider.markStepComplete('ingredientTypes');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.stepMarkedComplete)),
      );
    }
  }

  Future<void> _persistReorder() async {
    final provider = context.read<IngredientTypeProvider>();
    try {
      await provider.reorderIngredientTypes(franchiseId!, _pendingReorder);
      await provider.loadTypes(franchiseId!);
      setState(() {
        _reorderChanged = false;
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to persist ingredient type reorder',
        source: 'IngredientTypeManagementScreen',
        screen: 'ingredient_type_management_screen',
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
    final provider = context.read<IngredientTypeProvider>();
    provider.loadTypes(franchiseId!);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<IngredientTypeProvider>();
    final types = provider.types;

    if (franchiseId == null || franchiseId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.ingredientTypes)),
        body: Center(child: Text(loc.selectAFranchiseFirst)),
      );
    }

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
            icon: const Icon(Icons.download),
            tooltip: loc.loadDefaultTypes,
            onPressed: () {
              IngredientTypeTemplatePickerDialog.show(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: loc.importExport,
            onPressed: () {
              IngredientTypeJsonImportExportDialog.show(context);
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
        onPressed: () => _showFormDialog(),
        label: Text(loc.addIngredientType),
        icon: const Icon(Icons.add),
        backgroundColor: DesignTokens.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: types.isEmpty
            ? Center(child: Text(loc.noIngredientTypesFound))
            : Column(
                children: [
                  const InlineAddIngredientTypeRow(),
                  const SizedBox(height: 12),
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
                        if (provider.types.isEmpty || oldIndex == newIndex)
                          return;

                        final updatedList =
                            List<IngredientType>.from(provider.types);

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
                                try {
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
                                        content:
                                            Text(loc.ingredientTypeInUseError),
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

                                  await provider.deleteType(
                                      franchiseId!, type.id!);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${loc.ingredientTypeDeleted}: ${type.name}'),
                                      ),
                                    );
                                  }
                                } catch (e, stack) {
                                  await ErrorLogger.log(
                                    message: 'Failed to delete ingredient type',
                                    source: 'IngredientTypeManagementScreen',
                                    screen: 'ingredient_type_management_screen',
                                    stack: stack.toString(),
                                    severity: 'error',
                                    contextData: {
                                      'franchiseId': franchiseId,
                                      'ingredientTypeId': type.id
                                    },
                                  );
                                }
                              },
                              onSaveTapped: () async {
                                await provider.loadTypes(franchiseId!);
                                setState(() {
                                  _editingMap[type.id!] = false;
                                });
                              },
                            ));
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class IngredientTypeFormDialog extends StatefulWidget {
  final IngredientType? initial;
  final String franchiseId;

  const IngredientTypeFormDialog({
    Key? key,
    this.initial,
    required this.franchiseId,
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
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<IngredientTypeProvider>();

    return AlertDialog(
      title: Text(widget.initial == null
          ? loc.addIngredientType
          : loc.editIngredientType),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: loc.name),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? loc.required : null,
                onChanged: (val) => name = val,
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: loc.description),
                onChanged: (val) => description = val,
              ),
              TextFormField(
                initialValue: systemTag,
                decoration: InputDecoration(labelText: loc.systemTag),
                onChanged: (val) => systemTag = val,
              ),
              TextFormField(
                initialValue: sortOrder.toString(),
                decoration: InputDecoration(labelText: loc.sortOrder),
                keyboardType: TextInputType.number,
                onChanged: (val) => sortOrder = int.tryParse(val) ?? sortOrder,
              ),
              // 💡 Future Feature Placeholder: Add visibility toggle, tag color, etc.
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() != true) return;

            final newType = IngredientType(
              id: widget.initial?.id,
              name: name.trim(),
              description: description?.trim(),
              systemTag: systemTag?.trim(),
              sortOrder: sortOrder,
            );

            try {
              if (newType.id == null) {
                await provider.addType(widget.franchiseId, newType);
              } else {
                await provider.updateType(widget.franchiseId, newType);
              }
              if (mounted) Navigator.of(context).pop();
            } catch (e, stack) {
              await ErrorLogger.log(
                message: 'Failed to save ingredient type',
                source: 'IngredientTypeFormDialog',
                screen: 'ingredient_type_management_screen',
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
