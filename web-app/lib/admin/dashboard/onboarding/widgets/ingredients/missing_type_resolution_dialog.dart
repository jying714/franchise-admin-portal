// lib/admin/dashboard/onboarding/widgets/ingredients/missing_type_resolution_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../package:shared_core/src/core/models/ingredient_metadata.dart';
import '../package:shared_core/src/core/models/ingredient_type_model.dart';
import '../package:shared_core/src/core/providers/ingredient_type_provider.dart';
import '../package:shared_core/src/core/utils/error_logger.dart';
import '../package:shared_core/src/core/providers/franchise_provider.dart';

class MissingTypeResolutionDialog extends StatefulWidget {
  /// Ingredients that reference a typeId not present in current ingredient types
  final List<IngredientMetadata> ingredientsWithMissingTypes;

  /// List of all available types (id, name)
  final List<IngredientType> availableTypes;

  /// Callback when all missing types are resolved. Receives list of resolved ingredients (with updated typeId if needed)
  final void Function(List<IngredientMetadata> resolvedIngredients) onResolved;

  /// Context from the dialog builder for safe pops!
  final BuildContext dialogContext;

  const MissingTypeResolutionDialog({
    super.key,
    required this.ingredientsWithMissingTypes,
    required this.availableTypes,
    required this.onResolved,
    required this.dialogContext,
  });

  @override
  State<MissingTypeResolutionDialog> createState() =>
      _MissingTypeResolutionDialogState();
}

class _MissingTypeResolutionDialogState
    extends State<MissingTypeResolutionDialog> {
  late List<IngredientMetadata>
      workingList; // Current ingredient rows (removable)
  late Map<String, String?>
      typeMapping; // ingredientId -> selected typeId (null if unresolved)
  late List<IngredientType>
      allTypes; // local, can be updated when new type added
  bool _addingType = false;
  final TextEditingController _newTypeNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    workingList = List.from(widget.ingredientsWithMissingTypes);
    typeMapping = {for (final i in workingList) i.id: null};
    allTypes = List.from(widget.availableTypes);
  }

  bool get allResolved =>
      typeMapping.isNotEmpty && typeMapping.values.every((v) => v != null);

  Future<void> _addNewType(BuildContext context) async {
    final name = _newTypeNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _addingType = true);

    try {
      final provider = context.read<IngredientTypeProvider>();
      final id = name.toLowerCase().replaceAll(' ', '_');
      final added = provider.stageIfNew(id: id, name: name);
      if (!added) {
        // Already exists, optionally warn
        setState(() => _addingType = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingredient type already exists.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final newType = provider.getById(id);

      setState(() {
        if (newType != null) allTypes.add(newType);
        _newTypeNameCtrl.clear();
        _addingType = false;
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to create new ingredient type',
        stack: stack.toString(),
        source: 'MissingTypeResolutionDialog',
        screen: 'onboarding_ingredients_screen',
        severity: 'error',
      );
      setState(() => _addingType = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create new ingredient type.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _newTypeNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
        '[MissingTypeResolutionDialog] FranchiseId in context: ${context.read<FranchiseProvider>().franchiseId}');
    print(
        '[MissingTypeResolutionDialog] IngredientTypeProvider franchiseId: ${context.read<IngredientTypeProvider>().franchiseId}');

    print('[MissingTypeResolutionDialog] build() called');
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Resolve Missing Ingredient Types'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The following imported ingredients reference ingredient types that do not exist. '
              'Please assign an existing type, create a new type, or remove the ingredient from import.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: workingList.length,
                itemBuilder: (ctx, idx) {
                  final ing = workingList[idx];
                  final currentTypeId = typeMapping[ing.id];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Ingredient name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ing.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'Missing type: "${ing.typeId}"',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        // Type dropdown
                        DropdownButton<String>(
                          value: currentTypeId,
                          hint: const Text('Select type'),
                          items: [
                            for (final type in allTypes)
                              DropdownMenuItem(
                                value: type.id,
                                child: Text(type.name),
                              ),
                          ],
                          onChanged: (selected) {
                            setState(() {
                              typeMapping[ing.id] = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Option to remove ingredient from import
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove ingredient from import',
                          onPressed: () {
                            setState(() {
                              typeMapping.remove(ing.id);
                              workingList.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Inline "Add new type"
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTypeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add new type',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_addingType,
                      onSubmitted: (_) {
                        if (!_addingType) _addNewType(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addingType
                        ? null
                        : () async {
                            await _addNewType(context);
                          },
                    child: _addingType
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(widget.dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: allResolved
              ? () {
                  final resolved = workingList.map((ing) {
                    final mappedTypeId = typeMapping[ing.id];
                    assert(mappedTypeId != null && mappedTypeId.isNotEmpty,
                        '[MissingTypeResolutionDialog] Resolved ingredient ${ing.id} has invalid typeId');
                    return ing.copyWith(typeId: mappedTypeId ?? 'Unknown');
                  }).toList();

                  widget.onResolved(resolved);
                  // Don't double-pop! widget.onResolved will pop with data.
                }
              : null,
          child: const Text('Proceed'),
        ),
      ],
    );
  }

  @override
  void deactivate() {
    print('[OnboardingIngredientsScreen] DEACTIVATE');
    super.deactivate();
  }
}


