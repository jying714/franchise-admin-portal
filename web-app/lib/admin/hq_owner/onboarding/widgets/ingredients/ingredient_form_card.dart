import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/ingredients/ingredient_tag_selector.dart';

class IngredientFormCard extends StatefulWidget {
  final shared.IngredientMetadata? initialData;
  final VoidCallback? onSaved;
  final AppLocalizations loc;
  final BuildContext parentContext;

  const IngredientFormCard({
    Key? key,
    this.initialData,
    this.onSaved,
    required this.loc,
    required this.parentContext,
  }) : super(key: key);

  @override
  State<IngredientFormCard> createState() => _IngredientFormCardState();
}

class _IngredientFormCardState extends State<IngredientFormCard> {
  String? _selectedTypeId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();
  List<String> _allergens = [];

  bool _removable = true;
  bool _supportsExtra = false;
  bool _sidesAllowed = false;
  bool _outOfStock = false;

  bool _isSaving = false;
  bool _typeSeeded = false;

  late final String _id;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    _id = data?.id ?? '_new_${DateTime.now().millisecondsSinceEpoch}';

    if (data != null) {
      _nameController.text = data.name;
      _typeController.text = data.type ?? '';
      _selectedTypeId = data.typeId;
      _notesController.text = data.notes ?? '';
      _allergens = List.from(data.allergens);
      _removable = data.removable;
      _supportsExtra = data.supportsExtra;
      _sidesAllowed = data.sidesAllowed;
      _outOfStock = data.outOfStock;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    final typeId = (_selectedTypeId ?? '').trim();
    debugPrint(
      '[IngredientFormCard] SAVE tap '
      'selectedTypeId="$_selectedTypeId" '
      'trimmedTypeId="$typeId" '
      'name="${_nameController.text}" '
      'isNew=${widget.initialData == null} '
      'initialTypeId="${widget.initialData?.typeId}"',
    );
    if (typeId.isEmpty) {
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(widget.loc.requiredField)),
        );
      }
      return;
    }

    // Always use screen context — dialog route may not have providers.
    final host = widget.parentContext;

    final typeProvider =
        Provider.of<IngredientTypeProviderImpl>(host, listen: false);
    final matched = typeProvider.ingredientTypes.where((t) => t.id == typeId);
    final typeName =
        matched.isNotEmpty ? matched.first.name : _typeController.text.trim();

    final hostTypes = typeProvider.ingredientTypes
        .map((t) => '${t.id}:${t.name}')
        .take(30)
        .join(', ');
    debugPrint(
      '[IngredientFormCard] SAVE types '
      'matchCount=${matched.length} typeName="$typeName" '
      'hostTypeCount=${typeProvider.ingredientTypes.length} '
      'containsSelected=${typeProvider.ingredientTypes.any((t) => t.id == typeId)} '
      'sample=[$hostTypes]',
    );

    if (typeName.isEmpty) {
      if (host.mounted) {
        ScaffoldMessenger.of(host).showSnackBar(
          const SnackBar(content: Text('Ingredient type name is required')),
        );
      }
      return;
    }

    final ingredient = shared.IngredientMetadata(
      id: widget.initialData?.id ??
          _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
      name: _nameController.text.trim(),
      type: typeName,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      allergens: _allergens,
      removable: _removable,
      supportsExtra: _supportsExtra,
      sidesAllowed: _sidesAllowed,
      outOfStock: _outOfStock,
      typeId: typeId,
      upcharge: widget.initialData?.upcharge,
      imageUrl: widget.initialData?.imageUrl,
      amountSelectable: widget.initialData?.amountSelectable ?? false,
      amountOptions: widget.initialData?.amountOptions,
    );

    try {
      setState(() => _isSaving = true);

      final meta = Provider.of<IngredientMetadataProviderImpl>(
        host,
        listen: false,
      );

      final franchiseId =
          Provider.of<shared.FranchiseProvider>(host, listen: false)
              .franchiseId;

      // Avoid updateFranchiseId here — it can trigger load() and rebuild under the route.
      final isNew = widget.initialData == null;
      debugPrint(
        '[IngredientFormCard] SAVE writing '
        'id=${ingredient.id} typeId=${ingredient.typeId} type=${ingredient.type} '
        'franchiseId=$franchiseId isNew=$isNew',
      );
      if (isNew) {
        await meta.createIngredient(ingredient);
      } else {
        meta.updateIngredient(ingredient);
        // saveChanges = batch write only. Do NOT saveAllChanges/load under an open dialog.
        await meta.saveChanges();
      }
      debugPrint(
        '[IngredientFormCard] SAVE write OK mounted=$mounted → onSaved (parent pops)',
      );
      widget.onSaved?.call();
      // Do not setState after a successful save — route should be gone.
      return;
    } catch (e, stack) {
      debugPrint('[IngredientFormCard] SAVE ERROR: $e');
      shared.ErrorLogger.log(
        message: 'Failed to save ingredient: $e',
        source: 'IngredientFormCard',
        stack: stack.toString(),
        severity: 'error',
        contextData: {'ingredientName': ingredient.name},
      );

      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(widget.loc.errorSavingIngredient)),
        );
      }
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = widget.loc;
    final colorScheme = theme.colorScheme;

    final ingredientTypes = Provider.of<IngredientTypeProviderImpl>(
      widget.parentContext,
      listen: false,
    ).ingredientTypes;
    final typeIds = ingredientTypes.map((t) => (t.id ?? '').trim()).toSet();

    // Seed once when types are available. Never fight user selection on every build.
    if (!_typeSeeded && ingredientTypes.isNotEmpty) {
      _typeSeeded = true;
      final initial = (widget.initialData?.typeId ?? '').trim();
      final current = (_selectedTypeId ?? '').trim();
      String? next;
      if (current.isNotEmpty && typeIds.contains(current)) {
        next = current;
      } else if (initial.isNotEmpty && typeIds.contains(initial)) {
        next = initial;
      } else {
        next = ingredientTypes.first.id;
      }
      final nextName = ingredientTypes
          .firstWhere(
            (t) => t.id == next,
            orElse: () => ingredientTypes.first,
          )
          .name;
      debugPrint(
        '[IngredientFormCard] SEED once typeId="$next" name="$nextName" '
        'initial="$initial" current="$current"',
      );
      // Schedule setState only if value must change.
      if (next != _selectedTypeId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedTypeId = next;
            _typeController.text = nextName;
          });
        });
      } else if (_typeController.text.trim().isEmpty) {
        _typeController.text = nextName;
      }
    }

    final String? safeTypeId = (_selectedTypeId != null &&
            typeIds.contains((_selectedTypeId ?? '').trim()))
        ? _selectedTypeId
        : null;

    debugPrint(
      '[IngredientFormCard] BUILD '
      'selected="$_selectedTypeId" safe="$safeTypeId" '
      'seeded=$_typeSeeded typeCount=${ingredientTypes.length} '
      'isSaving=$_isSaving',
    );

    // showDialog already supplies the modal route + barrier — do not nest Dialog.
    return KeyedSubtree(
      key: ValueKey(_id),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 725),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: loc.ingredientName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? loc.requiredField
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: safeTypeId ??
                        (_selectedTypeId != null &&
                                typeIds.contains((_selectedTypeId ?? '').trim())
                            ? _selectedTypeId
                            : null),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: loc.ingredientType,
                      border: const OutlineInputBorder(),
                    ),
                    items: ingredientTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(),
                    validator: (val) => val == null ? loc.requiredField : null,
                    onChanged: (val) {
                      setState(() {
                        _selectedTypeId = val;
                        final type = ingredientTypes.firstWhere(
                          (t) => t.id == val,
                          orElse: () => shared.IngredientType(id: '', name: ''),
                        );
                        _typeController.text = type.name;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  IngredientTagSelector(
                    selectedTags: _allergens,
                    onChanged: (tags) => setState(() => _allergens = tags),
                    loc: loc,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.ingredientDescription,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      CheckboxListTile(
                        value: _removable,
                        onChanged: (v) =>
                            setState(() => _removable = v ?? true),
                        title: Text(loc.removable),
                      ),
                      CheckboxListTile(
                        value: _supportsExtra,
                        onChanged: (v) =>
                            setState(() => _supportsExtra = v ?? false),
                        title: Text(loc.supportsExtra),
                      ),
                      CheckboxListTile(
                        value: _sidesAllowed,
                        onChanged: (v) =>
                            setState(() => _sidesAllowed = v ?? false),
                        title: Text(loc.sidesAllowed),
                      ),
                      CheckboxListTile(
                        value: _outOfStock,
                        onChanged: (v) =>
                            setState(() => _outOfStock = v ?? false),
                        title: Text(loc.outOfStock),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveIngredient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(loc.saveIngredient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
