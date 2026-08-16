// web-app/lib/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart
// FIXED VERSION – Step 1 of CLI Roadmap – Single Source of Truth + No Stale Refresh

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/size_pricing_editor.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/image_upload_field.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/nutrition_editor_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/preview_menu_item_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_template_dropdown.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_utility.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/modifier_groups_ingredient_binder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/multi_ingredient_selector.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/wings_franchise_sauce_pool.dart';

// ===================== NEW COORDINATOR (Single Source of Truth) =====================
// ===================== NEW COORDINATOR (Single Source of Truth) =====================
class MenuItemEditSession extends ChangeNotifier {
  shared.MenuItem draft;
  List<shared.MenuItemSchemaIssue> issues = [];
  bool isDirty = false;
  final String franchiseId;
  final BuildContext _buildContext;

  MenuItemEditSession({
    required this.draft,
    required this.franchiseId,
    required BuildContext buildContext,
  }) : _buildContext = buildContext;

  void updateDraft(shared.MenuItem newDraft) {
    draft = newDraft;
    isDirty = true;
    _recomputeIssues();
    notifyListeners();
  }

  void markClean() {
    isDirty = false;
    notifyListeners();
  }

  void _recomputeIssues() {
    final categories = Provider.of<shared.CategoryProvider>(
      _buildContext,
      listen: false,
    ).categories;
    final ingredients = Provider.of<shared.IngredientMetadataProvider>(
      _buildContext,
      listen: false,
    ).allIngredients;
    final types = Provider.of<shared.IngredientTypeProvider>(
      _buildContext,
      listen: false,
    ).ingredientTypes;

    issues = shared.MenuItemSchemaIssue.detectAllIssues(
      menuItem: draft,
      categories: categories,
      ingredients: ingredients,
      ingredientTypes: types,
    );
  }

  void repairIssue(shared.MenuItemSchemaIssue issue, String newValue) {
    final updatedDraft = repairMenuItem(
      draft,
      issue,
      newValue,
    );
    updateDraft(updatedDraft);
  }

  void forceRecomputeIssues() {
    _recomputeIssues();
    notifyListeners();
  }
}

// BEFORE
// (nothing)

// AFTER
List<shared.IngredientReference> _refsFromMaps(
    List<Map<String, dynamic>>? maps) {
  if (maps == null || maps.isEmpty) return [];
  return maps
      .map((m) {
        final id = (m['ingredientId'] ?? m['id'] ?? '').toString();
        final name = (m['name'] ?? id).toString();
        final typeId = (m['typeId'] ?? m['type'] ?? 'unknown').toString();
        double? upcharge;
        final raw = m['price'] ?? m['upcharge'];
        if (raw is num) {
          upcharge = raw.toDouble();
        } else if (raw is String) {
          upcharge = double.tryParse(raw);
        }
        return shared.IngredientReference(
          id: id,
          name: name,
          typeId: typeId,
          upcharge: upcharge,
        );
      })
      .where((r) => r.id.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _mapsFromRefs(
    List<shared.IngredientReference> refs) {
  return refs.map((r) {
    final map = <String, dynamic>{
      'ingredientId': r.id,
      'id': r.id,
      'name': r.name,
      'typeId': r.typeId,
    };
    // Mobile pricing reads optionalAddOns[].price first, then meta.upcharge.
    // Persist both so either path works.
    if (r.upcharge != null) {
      map['price'] = r.upcharge;
      map['upcharge'] = r.upcharge;
    }
    return map;
  }).toList();
}

class MenuItemEditorSheet extends StatefulWidget {
  final shared.MenuItem? existing;
  final void Function(shared.MenuItem item) onSave;
  final VoidCallback onCancel;
  final FirebaseFirestore firestore;
  final String franchiseId;
  final ValueChanged<List<shared.MenuItemSchemaIssue>>? onSchemaIssuesChanged;

  const MenuItemEditorSheet({
    super.key,
    this.existing,
    required this.onCancel,
    required this.onSave,
    required this.firestore,
    required this.franchiseId,
    this.onSchemaIssuesChanged,
  });

  @override
  State<MenuItemEditorSheet> createState() => MenuItemEditorSheetState();
}

class MenuItemEditorSheetState extends State<MenuItemEditorSheet> {
  late MenuItemEditSession _session;
  final _formKey = GlobalKey<FormState>();

  shared.MenuItem get currentDraft => _session.draft;
  List<shared.MenuItemSchemaIssue> get currentIssues => _session.issues;
  bool get hasUnresolvedIssues => _session.issues.any((i) => !i.resolved);

  @override
  void initState() {
    super.initState();

    final initialItem = widget.existing ?? emptyDraft();

    _session = MenuItemEditSession(
      draft: initialItem,
      franchiseId: widget.franchiseId,
      buildContext: context,
    );

    // Keep parent sidebar in sync on every session notify (updateDraft / repair / force).
    _session.addListener(_forwardIssuesToParent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _session.forceRecomputeIssues();
      _forwardIssuesToParent();
    });
  }

  void _forwardIssuesToParent() {
    widget.onSchemaIssuesChanged?.call(List.from(_session.issues));
  }

  @override
  void dispose() {
    _session.removeListener(_forwardIssuesToParent);
    super.dispose();
  }

  void repairSchemaIssue(shared.MenuItemSchemaIssue issue, String newValue) {
    _session.repairIssue(issue, newValue);
    // Force UI refresh in parent
    widget.onSchemaIssuesChanged?.call(_session.issues);
  }

  void forceRecomputeIssues() {
    _session.forceRecomputeIssues();
    widget.onSchemaIssuesChanged?.call(_session.issues);
  }

  void _saveItem() {
    final hasErrors = _session.issues.any((i) => i.severity == 'error');
    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Resolve remaining schema errors first'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final savedItem = constructMenuItemFromEditorFields(
      id: _session.draft.id,
      outOfStock: _session.draft.outOfStock ?? false,
      categoryName: Provider.of<shared.CategoryProvider>(context, listen: false)
          .categories
          .firstWhere((c) => c.id == _session.draft.categoryId,
              orElse: () => shared.Category(id: '', name: ''))
          .name,
      categoryId: _session.draft.categoryId,
      name: _session.draft.name,
      price: _session.draft.price,
      description: _session.draft.description,
      notes: _session.draft.notes,
      sku: _session.draft.sku,
      dietaryTags: _session.draft.dietaryTags ?? [],
      allergens: _session.draft.allergens ?? [],
      prepTime: _session.draft.prepTime,
      sortOrder: _session.draft.sortOrder,
      taxCategory: _session.draft.taxCategory ?? 'standard',
      exportId: _session.draft.exportId,
      // M5: do not inject empty dual-tree lists. Model still requires the
      // fields; construct defaults keep them empty. toFirestore omits empties.
      includedIngredients: _refsFromMaps(_session.draft.includedIngredients),
      optionalAddOns: _refsFromMaps(_session.draft.optionalAddOns),
      imageUrl: _session.draft.imageUrl ?? '',
      nutrition: _session.draft.nutrition,
      selectedTemplateRefs: _session.draft.templateRefs ?? [],
      sizeData: _session.draft.sizes ?? [],
      crustTypes: _session.draft.crustTypes,
      cookTypes: _session.draft.cookTypes,
      cutStyles: _session.draft.cutStyles,
      sauceOptions: _session.draft.sauceOptions,
      dressingOptions: _session.draft.dressingOptions,
      maxFreeToppings: _session.draft.maxFreeToppings,
      maxFreeSauces: _session.draft.maxFreeSauces,
      maxFreeDressings: _session.draft.maxFreeDressings,
      maxToppings: _session.draft.maxToppings,
      freeDressingCount: _session.draft.freeDressingCount,
      extraDressingUpcharge: _session.draft.extraDressingUpcharge,
      optionalAddonPriceOverrides: _session.draft.optionalAddonPriceOverrides,
      dippingSauceOptions: _session.draft.dippingSauceOptions,
      dippingSplits: _session.draft.dippingSplits,
      sideDipSauceOptions: _session.draft.sideDipSauceOptions,
      freeDipCupCount: _session.draft.freeDipCupCount,
      sideDipUpcharge: _session.draft.sideDipUpcharge,
      menuProfile:
          _session.draft.menuProfile ?? _session.draft.effectiveMenuProfile,
      modifierGroups: _session.draft.modifierGroups ??
          _session.draft.effectiveModifierGroups,
      inventoryTracked: _session.draft.inventoryTracked,
      stockCount: _session.draft.stockCount,
      lowStockThreshold: _session.draft.lowStockThreshold,
    );

    var toSave = savedItem.copyWith(
      menuProfile:
          _session.draft.menuProfile ?? _session.draft.effectiveMenuProfile,
      modifierGroups: _session.draft.modifierGroups ??
          _session.draft.effectiveModifierGroups,
      includedIngredients: _session.draft.includedIngredients,
      optionalAddOns: _session.draft.optionalAddOns,
      inventoryTracked: _session.draft.inventoryTracked,
      stockCount: _session.draft.stockCount,
      lowStockThreshold: _session.draft.lowStockThreshold,
      freeDressingCount: _session.draft.freeDressingCount,
      extraDressingUpcharge: _session.draft.extraDressingUpcharge,
      maxFreeDressings: _session.draft.maxFreeDressings,
      optionalAddonPriceOverrides: _session.draft.optionalAddonPriceOverrides,
      dippingSauceOptions: _session.draft.dippingSauceOptions,
      dippingSplits: _session.draft.dippingSplits,
      sideDipSauceOptions: _session.draft.sideDipSauceOptions,
      freeDipCupCount: _session.draft.freeDipCupCount,
      sideDipUpcharge: _session.draft.sideDipUpcharge,
    );

    final profile =
        (toSave.menuProfile ?? toSave.effectiveMenuProfile).toLowerCase();

    // Wings: project bound sauce ingredientIds from modifier groups into the
    // legacy lists mobile still reads (toss list == side-cup list).
    if (profile == shared.MenuProfile.wings) {
      final groups = toSave.modifierGroups ?? const <shared.ModifierGroup>[];
      List<String> idsFromGroup(String groupId) {
        final g = groups.where(
          (x) =>
              x.id.toLowerCase() == groupId || x.label.toLowerCase() == groupId,
        );
        if (g.isEmpty) return const [];
        final out = <String>[];
        final seen = <String>{};
        for (final o in g.first.options) {
          final id =
              (o.ingredientId != null && o.ingredientId!.trim().isNotEmpty)
                  ? o.ingredientId!.trim()
                  : o.id.trim();
          if (id.isEmpty || seen.contains(id)) continue;
          // Skip pure label options (e.g. Plain if ever added as label-only)
          if (o.isLabelOnly && id.toLowerCase() == 'plain') continue;
          seen.add(id);
          out.add(id);
        }
        return out;
      }

      final tossIds = idsFromGroup('wing_sauce');
      // Product rule: toss list == side-cup list. Prefer wing_dips if bound,
      // else reuse toss list so one bind covers both.
      final dipIds = idsFromGroup('wing_dips');
      final sharedIds = dipIds.isNotEmpty ? dipIds : tossIds;

      final sizes = toSave.sizes ?? const <shared.SizeData>[];
      final freeCups = Map<String, int>.from(toSave.freeDipCupCount ?? {});
      final upcharges = Map<String, double>.from(toSave.sideDipUpcharge ?? {});
      final splits = Map<String, int>.from(toSave.dippingSplits ?? {});
      for (final s in sizes) {
        freeCups.putIfAbsent(s.label, () => 2);
        upcharges.putIfAbsent(s.label, () => 0.95);
        splits.putIfAbsent(s.label, () => 2);
      }
      if (sizes.isNotEmpty) {
        final labels = sizes.map((s) => s.label).toSet();
        freeCups.removeWhere((k, _) => !labels.contains(k));
        upcharges.removeWhere((k, _) => !labels.contains(k));
        splits.removeWhere((k, _) => !labels.contains(k));
      }

      toSave = toSave.copyWith(
        dippingSauceOptions: tossIds.isNotEmpty ? tossIds : sharedIds,
        sideDipSauceOptions: sharedIds,
        freeDipCupCount: sizes.isEmpty ? toSave.freeDipCupCount : freeCups,
        sideDipUpcharge: sizes.isEmpty ? toSave.sideDipUpcharge : upcharges,
        dippingSplits: sizes.isEmpty ? toSave.dippingSplits : splits,
        // Ensure included/optional stay empty on wings
        includedIngredients: const <Map<String, dynamic>>[],
        optionalAddOns: const <Map<String, dynamic>>[],
      );
    }

    if (profile == shared.MenuProfile.salad) {
      final groups = List<shared.ModifierGroup>.from(
        toSave.modifierGroups ?? const [],
      );
      final cleaned = [
        for (final g in groups)
          if (g.id.toLowerCase() == 'dressings' ||
              g.label.toLowerCase().contains('dressing'))
            g.copyWith(
                maxFree:
                    null) // or 0 only if copyWith can't clear — prefer omit
          else
            g,
      ];
      // If copyWith can't set null, rebuild ModifierGroup without maxFree.
      toSave = toSave.copyWith(
        freeDressingCount: toSave.freeDressingCount ?? 1,
        extraDressingUpcharge: toSave.extraDressingUpcharge ?? 0.75,
        maxFreeDressings: toSave.freeDressingCount is int
            ? toSave.freeDressingCount as int
            : (toSave.maxFreeDressings ?? 1),
        modifierGroups: cleaned,
      );
    }

    if (profile == shared.MenuProfile.pizza ||
        profile == shared.MenuProfile.calzone) {
      final sizes = toSave.sizes ?? const <shared.SizeData>[];
      if (sizes.isNotEmpty) {
        final large = sizes.where((s) {
          final l = s.label.toLowerCase();
          return l.contains('large') && !l.contains('x');
        });
        final derived =
            large.isNotEmpty ? large.first.basePrice : sizes.first.basePrice;
        toSave = toSave.copyWith(price: derived);
      }
    }

    widget.onSave(toSave);
    _session.markClean();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Saved to Firestore • Provider synced'),
      backgroundColor: Colors.green,
    ));
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categories = Provider.of<shared.CategoryProvider>(context).categories;
    return ChangeNotifierProvider.value(
      value: _session,
      child: Consumer<MenuItemEditSession>(
        builder: (context, session, _) {
          final hasErrors = session.issues.any((i) => i.severity == 'error');
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(session.draft.id.isEmpty
                  ? 'New Menu Item'
                  : 'Edit ${session.draft.name}'),
              actions: [
                IconButton(
                  tooltip: 'Back to menu list',
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                ),
                ElevatedButton(
                  onPressed: !hasErrors && session.isDirty ? _saveItem : null,
                  child: const Text('Save & Publish'),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 0. Profile first ──────────────────────────────
                    Text('Menu profile',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how this item is built. Pizza/calzone use size prices + topping upcharges; '
                      'wings use free cups + extra-cup price per size. '
                      'Optional toppings are modifier groups (min 0), not a separate list.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: shared.MenuProfile.known.contains(
                              (session.draft.menuProfile ??
                                      session.draft.effectiveMenuProfile)
                                  .toLowerCase())
                          ? (session.draft.menuProfile ??
                                  session.draft.effectiveMenuProfile)
                              .toLowerCase()
                          : shared.MenuProfile.standard,
                      decoration: const InputDecoration(
                        labelText: 'Menu profile',
                      ),
                      items: shared.MenuProfile.known
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p,
                              child: Text(p),
                            ),
                          )
                          .toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        final current = session.draft.menuProfile ??
                            session.draft.effectiveMenuProfile;
                        if (val == current) return;

                        final existing = session.draft.modifierGroups;
                        final hasCustom = existing != null &&
                            existing.any((g) => g.options.isNotEmpty);

                        if (hasCustom) {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Replace modifier groups?'),
                              content: const Text(
                                'Changing profile will re-seed default groups. '
                                'Custom option bindings may be cleared.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Replace'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                        }

                        Map<String, int>? nextSplits =
                            session.draft.dippingSplits;
                        Map<String, int>? nextFreeCups =
                            session.draft.freeDipCupCount;
                        Map<String, double>? nextUpcharge =
                            session.draft.sideDipUpcharge;

                        if (val == shared.MenuProfile.wings) {
                          final sizes =
                              session.draft.sizes ?? const <shared.SizeData>[];
                          if (sizes.isNotEmpty) {
                            nextSplits = {
                              for (final s in sizes) s.label: 2,
                            };
                            nextFreeCups = {
                              for (final s in sizes)
                                s.label:
                                    (session.draft.freeDipCupCount?[s.label] ??
                                        2),
                            };
                            nextUpcharge = {
                              for (final s in sizes)
                                s.label:
                                    (session.draft.sideDipUpcharge?[s.label] ??
                                        0.95),
                            };
                          }
                        }

                        session.updateDraft(
                          session.draft.copyWith(
                            menuProfile: val,
                            modifierGroups:
                                shared.MenuProfileTemplates.seedGroups(val),
                            dippingSplits: nextSplits,
                            freeDipCupCount: nextFreeCups,
                            sideDipUpcharge: nextUpcharge,
                            // Salad: item-level free dressings + extra $
                            freeDressingCount: val == shared.MenuProfile.salad
                                ? (session.draft.freeDressingCount ?? 1)
                                : session.draft.freeDressingCount,
                            extraDressingUpcharge: val ==
                                    shared.MenuProfile.salad
                                ? (session.draft.extraDressingUpcharge ?? 0.75)
                                : session.draft.extraDressingUpcharge,
                            maxFreeDressings: val == shared.MenuProfile.salad
                                ? (session.draft.maxFreeDressings ?? 1)
                                : session.draft.maxFreeDressings,
                            // Wings: no included toppings / optional add-ons
                            includedIngredients: val == shared.MenuProfile.wings
                                ? <Map<String, dynamic>>[]
                                : session.draft.includedIngredients,
                            optionalAddOns: val == shared.MenuProfile.wings
                                ? <Map<String, dynamic>>[]
                                : session.draft.optionalAddOns,
                          ),
                        );
                      },
                    ),
                    // Legacy MenuItemTemplateDropdown hidden until templates are
                    // re-seeded for Decision 10 profiles + modifier groups.
                    const Divider(height: 32),

                    // ── 1. Basics ─────────────────────────────────────
                    Text('Basics',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: session.draft.name,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      onChanged: (v) => session
                          .updateDraft(session.draft.copyWith(name: v.trim())),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: session.draft.description,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        helperText: 'Shown to customers',
                      ),
                      maxLines: 3,
                      onChanged: (v) => session.updateDraft(
                          session.draft.copyWith(description: v.trim())),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Description required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        final isPizza = profile == shared.MenuProfile.pizza ||
                            profile == shared.MenuProfile.calzone;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isPizza) ...[
                              Expanded(
                                child: TextFormField(
                                  initialValue: session.draft.price.toString(),
                                  decoration: InputDecoration(
                                    labelText: 'Base Price *',
                                    prefixText: '\$',
                                    helperText: session.draft.price == 0
                                        ? 'Warning: \$0 is allowed (free item)'
                                        : null,
                                    helperStyle: TextStyle(
                                      color: session.draft.price == 0
                                          ? Colors.orange.shade800
                                          : null,
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (v) => session.updateDraft(
                                      session.draft.copyWith(
                                          price: double.tryParse(v) ?? 0.0)),
                                  validator: (v) {
                                    final parsed = double.tryParse(v ?? '');
                                    if (parsed == null) {
                                      return 'Enter a valid price';
                                    }
                                    if (parsed < 0) {
                                      return 'Price cannot be negative';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                            ] else
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Pizza pricing is per size (see Image & sizes). '
                                    'Set each size base price and topping upcharge there.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            if (isPizza) const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: Provider.of<shared.CategoryProvider>(
                                        context)
                                    .resolveCategoryId(
                                        session.draft.categoryId),
                                decoration: const InputDecoration(
                                    labelText: 'Category *'),
                                items: Provider.of<shared.CategoryProvider>(
                                        context)
                                    .uniqueCategories
                                    .map((cat) => DropdownMenuItem<String>(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    session.updateDraft(session.draft
                                        .copyWith(categoryId: val));
                                  }
                                },
                                validator: (v) =>
                                    v == null ? 'Category required' : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: !session.draft.availability,
                      onChanged: (v) => session.updateDraft(
                          session.draft.copyWith(availability: !v)),
                      title: const Text('Out of Stock'),
                      subtitle: const Text(
                        'Manual unavailable flag (separate from tracked stock at 0)',
                      ),
                    ),

                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: session.draft.inventoryTracked,
                      onChanged: (v) => session.updateDraft(
                        session.draft.copyWith(
                          inventoryTracked: v,
                          stockCount: v
                              ? (session.draft.stockCount ?? 0)
                              : session.draft.stockCount,
                        ),
                      ),
                      title: const Text('Track inventory on this item'),
                      subtitle: const Text(
                        'When on, stock count is enforced for this SKU',
                      ),
                    ),
                    if (session.draft.inventoryTracked) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('stock_${session.draft.stockCount ?? 0}'),
                        initialValue: '${session.draft.stockCount ?? 0}',
                        decoration: const InputDecoration(
                          labelText: 'Stock count',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 0) return;
                          session.updateDraft(
                            session.draft.copyWith(stockCount: n),
                          );
                        },
                      ),
                      // Keep any lowStockThreshold field that already exists
                      // in the old inventory block (copy it here if present).
                    ],

                    const SizedBox(height: 16),
                    Text('Image',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Customer-facing photo for this item.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ImageUploadField(
                      initialValue: session.draft.image?.isNotEmpty == true
                          ? session.draft.image
                          : (session.draft.imageUrl.isNotEmpty
                              ? session.draft.imageUrl
                              : ''),
                      onChanged: (url) => session.updateDraft(
                        session.draft.copyWith(image: url ?? ''),
                      ),
                      onSaved: (url) => session.updateDraft(
                        session.draft.copyWith(image: url ?? ''),
                      ),
                    ),
                    const Divider(height: 32),

                    Text('Sizes & pricing',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Piece counts / prices for this item. Wings also use free cups and extra-cup price per size below.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizePricingEditor(
                      sizes: session.draft.sizes ?? [],
                      onChanged: (newSizes) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        var next = session.draft.copyWith(sizes: newSizes);
                        if (profile == shared.MenuProfile.wings) {
                          final free = Map<String, int>.from(
                              session.draft.freeDipCupCount ?? {});
                          final up = Map<String, double>.from(
                              session.draft.sideDipUpcharge ?? {});
                          final splits = Map<String, int>.from(
                              session.draft.dippingSplits ?? {});
                          for (final s in newSizes) {
                            free.putIfAbsent(s.label, () => 2);
                            up.putIfAbsent(s.label, () => 0.95);
                            splits.putIfAbsent(s.label, () => 2);
                          }
                          final labels = newSizes.map((s) => s.label).toSet();
                          free.removeWhere((k, _) => !labels.contains(k));
                          up.removeWhere((k, _) => !labels.contains(k));
                          splits.removeWhere((k, _) => !labels.contains(k));
                          next = next.copyWith(
                            freeDipCupCount: free,
                            sideDipUpcharge: up,
                            dippingSplits: splits,
                          );
                        }
                        session.updateDraft(next);
                      },
                    ),

                    Builder(
                      builder: (context) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        if (profile != shared.MenuProfile.wings) {
                          return const SizedBox.shrink();
                        }
                        final sizes =
                            session.draft.sizes ?? const <shared.SizeData>[];
                        if (sizes.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Add sizes above first. Free cups and extra-cup price are set per size.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }
                        final freeMap = Map<String, int>.from(
                            session.draft.freeDipCupCount ?? {});
                        final upchargeMap = Map<String, double>.from(
                            session.draft.sideDipUpcharge ?? {});
                        // Default free cups when size row has none yet (product: 2 for most, editable)
                        for (final s in sizes) {
                          freeMap.putIfAbsent(s.label, () => 2);
                          upchargeMap.putIfAbsent(s.label, () => 0.95);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            Text('Wings dipping cups',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Free cups and price per extra cup are owned on the item (per size). '
                              'Toss sauces and side cups share the same sauce list (bind via modifier groups).',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            ...sizes.map((s) {
                              final free = freeMap[s.label] ?? 2;
                              final up = upchargeMap[s.label] ?? 0.95;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(s.label,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey('free_${s.label}_$free'),
                                        initialValue: '$free',
                                        decoration: const InputDecoration(
                                          labelText: 'Free cups',
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          final n = int.tryParse(v.trim()) ?? 0;
                                          final next = Map<String, int>.from(
                                              session.draft.freeDipCupCount ??
                                                  {});
                                          next[s.label] = n < 0 ? 0 : n;
                                          session.updateDraft(session.draft
                                              .copyWith(freeDipCupCount: next));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey('up_${s.label}_$up'),
                                        initialValue: up.toStringAsFixed(2),
                                        decoration: const InputDecoration(
                                          labelText: 'Extra cup \$',
                                          prefixText: '\$',
                                          isDense: true,
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        onChanged: (v) {
                                          final n =
                                              double.tryParse(v.trim()) ?? 0.0;
                                          final next = Map<String, double>.from(
                                              session.draft.sideDipUpcharge ??
                                                  {});
                                          next[s.label] = n < 0 ? 0.0 : n;
                                          session.updateDraft(session.draft
                                              .copyWith(sideDipUpcharge: next));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),

                    // Salad: free dressings + extra dressing charge (item-level)
                    Builder(
                      builder: (context) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        if (profile != shared.MenuProfile.salad) {
                          return const SizedBox.shrink();
                        }
                        final freeRaw = session.draft.freeDressingCount;
                        final free = freeRaw is int
                            ? freeRaw
                            : (freeRaw is Map && freeRaw.isNotEmpty)
                                ? (freeRaw.values.first as num?)?.toInt() ?? 1
                                : 1;
                        final up = session.draft.extraDressingUpcharge ?? 0.75;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Salad dressings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bind dressing options on the Dressings modifier group. '
                              'Free count and extra price apply to this item (same idea as wings cups).',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('salad_free_$free'),
                                    initialValue: '$free',
                                    decoration: const InputDecoration(
                                      labelText: 'Free dressings',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      final n = int.tryParse(v.trim()) ?? 0;
                                      final safe = n < 0 ? 0 : n;
                                      session.updateDraft(
                                        session.draft.copyWith(
                                          freeDressingCount: safe,
                                          maxFreeDressings: safe,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('salad_up_$up'),
                                    initialValue: up.toStringAsFixed(2),
                                    decoration: const InputDecoration(
                                      labelText: 'Extra dressing \$',
                                      prefixText: '\$',
                                      isDense: true,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (v) {
                                      final n =
                                          double.tryParse(v.trim()) ?? 0.0;
                                      session.updateDraft(
                                        session.draft.copyWith(
                                          extraDressingUpcharge:
                                              n < 0 ? 0.0 : n,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    // W2: franchise default sauce pool (config/menu_profile_wings)
                    Builder(
                      builder: (context) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        if (profile != shared.MenuProfile.wings) {
                          return const SizedBox.shrink();
                        }
                        final allIngredients =
                            Provider.of<shared.IngredientMetadataProvider>(
                          context,
                          listen: false,
                        ).allIngredients;
                        final sauceIngredients = allIngredients.where((ing) {
                          final t =
                              (ing.typeId ?? ing.type ?? '').toLowerCase();
                          return t == 'sauces' || t == 'sauce';
                        }).toList();
                        final bound = <String>{
                          ...?session.draft.dippingSauceOptions,
                          ...?session.draft.sideDipSauceOptions,
                        }.toList();
                        return WingsFranchiseSaucePool(
                          franchiseId: widget.franchiseId,
                          sauceIngredients: sauceIngredients,
                          itemBoundSauceIds: bound,
                          onApplyPoolToItem: (ids) {
                            final unique = ids
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toSet()
                                .toList();
                            var groups = List<shared.ModifierGroup>.from(
                              session.draft.modifierGroups ??
                                  session.draft.effectiveModifierGroups,
                            );
                            shared.ModifierGroup project(
                              String groupId,
                              String label,
                            ) {
                              final options = unique.map(
                                (id) {
                                  final meta = allIngredients
                                      .where((i) => i.id == id)
                                      .cast<shared.IngredientMetadata?>()
                                      .firstWhere(
                                        (i) => true,
                                        orElse: () => null,
                                      );
                                  return shared.ModifierOption(
                                    id: id,
                                    label: meta?.name ?? id,
                                    ingredientId: id,
                                  );
                                },
                              ).toList();
                              final idx = groups.indexWhere(
                                (g) =>
                                    g.id.toLowerCase() == groupId ||
                                    g.label.toLowerCase() == groupId,
                              );
                              final base = idx >= 0
                                  ? groups[idx]
                                  : shared.ModifierGroup(
                                      id: groupId,
                                      label: label,
                                      selectMode:
                                          shared.ModifierSelectMode.multi,
                                      min: 0,
                                      max: options.length,
                                      options: const [],
                                    );
                              return shared.ModifierGroup(
                                id: base.id,
                                label: base.label,
                                selectMode: base.selectMode,
                                min: base.min,
                                max: base.max,
                                maxFree: base.maxFree,
                                options: options,
                              );
                            }

                            final wingSauce = project('wing_sauce', 'Sauce');
                            final wingDips =
                                project('wing_dips', 'Dipping cups');
                            final without = groups.where((g) {
                              final id = g.id.toLowerCase();
                              return id != 'wing_sauce' && id != 'wing_dips';
                            }).toList();
                            groups = [...without, wingSauce, wingDips];

                            session.updateDraft(
                              session.draft.copyWith(
                                dippingSauceOptions: unique,
                                sideDipSauceOptions: unique,
                                modifierGroups: groups,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const Divider(height: 32),

                    Builder(
                      builder: (context) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        final isWings = profile == shared.MenuProfile.wings;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isWings ? 'Wings sauces' : 'Modifiers',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isWings
                                  ? 'Bind sauces from the catalog (type sauces). '
                                      'Sauce = toss / flavor portions (max 2). '
                                      'Dipping cups = side cups (same sauce list is fine). '
                                      'Free cups and extra-cup price are set per size above.'
                                  : 'Bind catalog ingredients. Crust/Cook/Cut are label-only. '
                                      'Optional toppings = multi groups (min 0); extras use size topping upcharge.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ModifierGroupsIngredientBinder(
                      franchiseId: widget.franchiseId,
                      groups: session.draft.modifierGroups ??
                          session.draft.effectiveModifierGroups,
                      onChanged: (groups) => session.updateDraft(
                        session.draft.copyWith(modifierGroups: groups),
                      ),
                    ),

                    const Divider(height: 32),

                    // ── Included + optional ingredients ───────────────
                    // Wings: no included toppings / optional add-ons (Build your wings + dips only)
                    Builder(
                      builder: (context) {
                        final profile = (session.draft.menuProfile ??
                                session.draft.effectiveMenuProfile)
                            .toLowerCase();
                        if (profile == shared.MenuProfile.wings) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Included toppings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Starts on the item. Customer can remove; re-add stays free.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    MultiIngredientSelector(
                                      title: 'Included (on by default)',
                                      selected: _refsFromMaps(
                                          session.draft.includedIngredients),
                                      allowEmpty: true,
                                      onChanged: (refs) => session.updateDraft(
                                        session.draft.copyWith(
                                          includedIngredients:
                                              _mapsFromRefs(refs),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Optional add-ons',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Extras use size topping price unless an override is set below.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    MultiIngredientSelector(
                                      title: 'Optional add-ons',
                                      selected: _refsFromMaps(
                                          session.draft.optionalAddOns),
                                      allowEmpty: true,
                                      onChanged: (refs) {
                                        session.updateDraft(
                                          session.draft.copyWith(
                                            optionalAddOns: _mapsFromRefs(refs),
                                          ),
                                        );
                                      },
                                    ),
                                    // Keep the existing optional pricing
                                    // Builder (overrides) as the next child
                                    // inside this Card if it currently sits
                                    // immediately below MultiIngredientSelector.
                                    // Per-addon price editor (only when at least one is selected)
                                    Builder(
                                      builder: (context) {
                                        final profile =
                                            (session.draft.menuProfile ??
                                                    session.draft
                                                        .effectiveMenuProfile)
                                                .toLowerCase();
                                        // Pizza/calzone: size toppingPrice owns extras
                                        if (profile ==
                                                shared.MenuProfile.pizza ||
                                            profile ==
                                                shared.MenuProfile.calzone ||
                                            profile ==
                                                shared.MenuProfile.wings) {
                                          return const SizedBox.shrink();
                                        }
                                        final selected = _refsFromMaps(
                                            session.draft.optionalAddOns);
                                        if (selected.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        final overrides =
                                            List<Map<String, dynamic>>.from(
                                          session.draft
                                                  .optionalAddonPriceOverrides ??
                                              const [],
                                        );
                                        final types = Provider.of<
                                            shared.IngredientTypeProvider>(
                                          context,
                                          listen: false,
                                        ).ingredientTypes;
                                        final allIng = Provider.of<
                                            shared.IngredientMetadataProvider>(
                                          context,
                                          listen: false,
                                        ).allIngredients;

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Optional add-on pricing',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Size topping price is the house extra. '
                                                'Add overrides only for premium ingredients.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              const SizedBox(height: 8),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    final next = [
                                                      ...overrides,
                                                      {
                                                        'ingredientId': '',
                                                        'typeId': '',
                                                        'price': 0.0,
                                                      },
                                                    ];
                                                    session.updateDraft(
                                                      session.draft.copyWith(
                                                        optionalAddonPriceOverrides:
                                                            next,
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.add,
                                                      size: 18),
                                                  label: const Text(
                                                      'Add price override'),
                                                ),
                                              ),
                                              ...List.generate(overrides.length,
                                                  (i) {
                                                final row = overrides[i];
                                                final typeId =
                                                    row['typeId']?.toString() ??
                                                        '';
                                                final ingId =
                                                    row['ingredientId']
                                                            ?.toString() ??
                                                        '';
                                                final price =
                                                    (row['price'] as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final typeOk = types
                                                    .any((t) => t.id == typeId);
                                                final ingsForType = allIng
                                                    .where((ing) =>
                                                        typeId.isEmpty ||
                                                        (ing.typeId ?? '') ==
                                                            typeId)
                                                    .toList();
                                                final selectedBound = selected
                                                    .map((r) => r.id)
                                                    .toSet();
                                                final ings = ingsForType
                                                    .where((ing) =>
                                                        selectedBound
                                                            .contains(ing.id) ||
                                                        ing.id == ingId)
                                                    .toList();

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                          value: typeOk
                                                              ? typeId
                                                              : null,
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText: 'Type',
                                                            isDense: true,
                                                          ),
                                                          items: [
                                                            const DropdownMenuItem(
                                                              value: null,
                                                              child:
                                                                  Text('Type…'),
                                                            ),
                                                            ...types.map(
                                                              (t) =>
                                                                  DropdownMenuItem(
                                                                value: t.id,
                                                                child: Text(
                                                                    t.name),
                                                              ),
                                                            ),
                                                          ],
                                                          onChanged: (v) {
                                                            final next = [
                                                              for (var j = 0;
                                                                  j <
                                                                      overrides
                                                                          .length;
                                                                  j++)
                                                                if (j == i)
                                                                  {
                                                                    ...overrides[
                                                                        j],
                                                                    'typeId':
                                                                        v ?? '',
                                                                    'ingredientId':
                                                                        '',
                                                                  }
                                                                else
                                                                  overrides[j],
                                                            ];
                                                            session.updateDraft(
                                                              session.draft
                                                                  .copyWith(
                                                                optionalAddonPriceOverrides:
                                                                    next,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                          value: ings.any((e) =>
                                                                  e.id == ingId)
                                                              ? ingId
                                                              : null,
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText:
                                                                'Ingredient',
                                                            isDense: true,
                                                          ),
                                                          items: [
                                                            const DropdownMenuItem(
                                                              value: null,
                                                              child:
                                                                  Text('Item…'),
                                                            ),
                                                            ...ings.map(
                                                              (ing) =>
                                                                  DropdownMenuItem(
                                                                value: ing.id,
                                                                child: Text(
                                                                    ing.name),
                                                              ),
                                                            ),
                                                          ],
                                                          onChanged: (v) {
                                                            final next = [
                                                              for (var j = 0;
                                                                  j <
                                                                      overrides
                                                                          .length;
                                                                  j++)
                                                                if (j == i)
                                                                  {
                                                                    ...overrides[
                                                                        j],
                                                                    'ingredientId':
                                                                        v ?? '',
                                                                  }
                                                                else
                                                                  overrides[j],
                                                            ];
                                                            session.updateDraft(
                                                              session.draft
                                                                  .copyWith(
                                                                optionalAddonPriceOverrides:
                                                                    next,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      SizedBox(
                                                        width: 100,
                                                        child: TextFormField(
                                                          key: ValueKey(
                                                              'ovr_${i}_${ingId}_$price'),
                                                          initialValue: price
                                                              .toStringAsFixed(
                                                                  2),
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText: '\$',
                                                            isDense: true,
                                                          ),
                                                          keyboardType:
                                                              const TextInputType
                                                                  .numberWithOptions(
                                                                  decimal:
                                                                      true),
                                                          onChanged: (v) {
                                                            final n = double
                                                                    .tryParse(v
                                                                        .trim()) ??
                                                                0.0;
                                                            final next = [
                                                              for (var j = 0;
                                                                  j <
                                                                      overrides
                                                                          .length;
                                                                  j++)
                                                                if (j == i)
                                                                  {
                                                                    ...overrides[
                                                                        j],
                                                                    'price': n <
                                                                            0
                                                                        ? 0.0
                                                                        : n,
                                                                  }
                                                                else
                                                                  overrides[j],
                                                            ];
                                                            session.updateDraft(
                                                              session.draft
                                                                  .copyWith(
                                                                optionalAddonPriceOverrides:
                                                                    next,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons
                                                            .delete_outline),
                                                        onPressed: () {
                                                          final next = [
                                                            for (var j = 0;
                                                                j <
                                                                    overrides
                                                                        .length;
                                                                j++)
                                                              if (j != i)
                                                                overrides[j],
                                                          ];
                                                          session.updateDraft(
                                                            session.draft
                                                                .copyWith(
                                                              optionalAddonPriceOverrides:
                                                                  next,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 32),
                          ],
                        );
                      },
                    ),

                    // ── 6. Nutrition / preview / schema ───────────────
                    shared.FeatureGuard(
                      module: shared.PlatformFeature.nutritionalInfo.key,
                      fallback: const SizedBox.shrink(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nutrition',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () async {
                              final result =
                                  await showDialog<shared.NutritionInfo?>(
                                context: context,
                                builder: (_) => NutritionEditorDialog(
                                    initialValue: session.draft.nutrition),
                              );
                              if (result != null) {
                                session.updateDraft(
                                    session.draft.copyWith(nutrition: result));
                              }
                            },
                            child: Text(session.draft.nutrition == null
                                ? 'Add Nutrition'
                                : 'Edit Nutrition'),
                          ),
                          if (session.draft.nutrition != null)
                            Text(
                              '${session.draft.nutrition!.calories} cal • P:${session.draft.nutrition!.protein}g • F:${session.draft.nutrition!.fat}g • C:${session.draft.nutrition!.carbs}g',
                            ),
                          const Divider(height: 32),
                        ],
                      ),
                    ),

                    ExpansionTile(
                      title: const Text('Live mobile preview'),
                      children: [PreviewMenuItemCard(menuItem: session.draft)],
                    ),
                    const SizedBox(height: 16),

                    if (session.issues.isNotEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active schema issues: ${session.issues.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...session.issues.map(
                                (issue) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.error_outline,
                                      color: Colors.orange, size: 18),
                                  title: Text(issue.displayMessage),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Schema clean – ready to publish'),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: Row(
                children: [
                  TextButton(
                      onPressed: widget.onCancel, child: const Text('Cancel')),
                  const Spacer(),
                  ElevatedButton(
                    onPressed:
                        !session.issues.any((i) => i.severity == 'error') &&
                                session.isDirty
                            ? _saveItem
                            : null,
                    child: const Text('Save & Publish to Franchise'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
