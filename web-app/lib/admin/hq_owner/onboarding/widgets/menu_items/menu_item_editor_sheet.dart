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
      customizationGroups: const [],
      includedIngredients: const [],
      optionalAddOns: const [],
      customizations: const [],
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
      menuProfile:
          _session.draft.menuProfile ?? _session.draft.effectiveMenuProfile,
      modifierGroups: _session.draft.modifierGroups,
      inventoryTracked: _session.draft.inventoryTracked,
      stockCount: _session.draft.stockCount,
      lowStockThreshold: _session.draft.lowStockThreshold,
    );

    var toSave = savedItem.copyWith(
      menuProfile:
          _session.draft.menuProfile ?? _session.draft.effectiveMenuProfile,
      modifierGroups: _session.draft.modifierGroups ??
          _session.draft.effectiveModifierGroups,
      inventoryTracked: _session.draft.inventoryTracked,
      stockCount: _session.draft.stockCount,
      lowStockThreshold: _session.draft.lowStockThreshold,
    );

    final profile =
        (toSave.menuProfile ?? toSave.effectiveMenuProfile).toLowerCase();
    if (profile == shared.MenuProfile.pizza) {
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
                      'Choose how this item is built. Pizza uses size prices + topping upcharges; '
                      'optional toppings are modifier groups (min 0), not a separate list.',
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

                        session.updateDraft(
                          session.draft.copyWith(
                            menuProfile: val,
                            modifierGroups:
                                shared.MenuProfileTemplates.seedGroups(val),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),

                    // ── 1. Basics ─────────────────────────────────────
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
                        final isPizza = profile == shared.MenuProfile.pizza;

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
                      value: session.draft.outOfStock ?? false,
                      onChanged: (v) => session.updateDraft(
                          session.draft.copyWith(availability: !v)),
                      title: const Text('Out of Stock'),
                      subtitle: const Text('Temporarily unavailable'),
                    ),

                    const Divider(height: 32),

                    Text('Modifiers',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Bind catalog ingredients. Crust/Cook/Cut are label-only. '
                      'Optional toppings = multi groups (min 0); extras use size topping upcharge.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ModifierGroupsIngredientBinder(
                      groups: session.draft.modifierGroups ??
                          session.draft.effectiveModifierGroups,
                      onChanged: (groups) => session.updateDraft(
                        session.draft.copyWith(modifierGroups: groups),
                      ),
                    ),

                    const Divider(height: 32),

                    // ── 3. Item inventory ─────────────────────────────
                    Text('Item inventory',
                        style: Theme.of(context).textTheme.titleMedium),
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
                        'Count-tracked products only. Topping OOS stays on ingredients.',
                      ),
                    ),
                    if (session.draft.inventoryTracked)
                      TextFormField(
                        key: ValueKey(
                          'stock_${session.draft.id}_${session.draft.inventoryTracked}',
                        ),
                        initialValue: '${session.draft.stockCount ?? 0}',
                        decoration: const InputDecoration(
                          labelText: 'Stock count',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => session.updateDraft(
                          session.draft.copyWith(
                            stockCount: int.tryParse(v.trim()) ?? 0,
                          ),
                        ),
                      ),

                    const Divider(height: 32),

                    // ── 4. Presentation ───────────────────────────────
                    Text('Image & sizes',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Template:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MenuItemTemplateDropdown(
                            selectedTemplateId:
                                (session.draft.templateRefs?.isNotEmpty ??
                                        false)
                                    ? session.draft.templateRefs!.first
                                    : null,
                            onTemplateApplied: (template) {
                              final categories =
                                  Provider.of<shared.CategoryProvider>(
                                context,
                                listen: false,
                              ).categories;
                              final ingredients = Provider.of<
                                  shared.IngredientMetadataProvider>(
                                context,
                                listen: false,
                              ).allIngredients;
                              final types =
                                  Provider.of<shared.IngredientTypeProvider>(
                                context,
                                listen: false,
                              ).ingredientTypes;

                              var updated = applyTemplateToDraft(
                                session.draft,
                                template,
                                allIngredients: ingredients,
                              );

                              final issues =
                                  shared.MenuItemSchemaIssue.detectAllIssues(
                                menuItem: updated,
                                categories: categories,
                                ingredients: ingredients,
                                ingredientTypes: types,
                              );

                              for (final issue in issues) {
                                if (issue.severity != 'error') continue;
                                String? mapped;
                                switch (issue.type) {
                                  case shared.MenuItemSchemaIssueType.category:
                                    mapped = categories
                                        .where((c) =>
                                            c.id == issue.missingReference ||
                                            c.name.trim().toLowerCase() ==
                                                (issue.label ??
                                                        issue.missingReference)
                                                    .trim()
                                                    .toLowerCase())
                                        .map((c) => c.id)
                                        .cast<String?>()
                                        .firstWhere((_) => true,
                                            orElse: () => null);
                                    break;
                                  case shared
                                        .MenuItemSchemaIssueType.ingredient:
                                    mapped = ingredients
                                        .where((ing) =>
                                            ing.id == issue.missingReference ||
                                            ing.name.trim().toLowerCase() ==
                                                (issue.label ??
                                                        issue.missingReference)
                                                    .trim()
                                                    .toLowerCase())
                                        .map((ing) => ing.id)
                                        .cast<String?>()
                                        .firstWhere((_) => true,
                                            orElse: () => null);
                                    break;
                                  case shared
                                        .MenuItemSchemaIssueType.ingredientType:
                                    mapped = types
                                        .where((t) =>
                                            t.id == issue.missingReference ||
                                            t.name.trim().toLowerCase() ==
                                                (issue.label ??
                                                        issue.missingReference)
                                                    .trim()
                                                    .toLowerCase())
                                        .map((t) => t.id)
                                        .cast<String?>()
                                        .firstWhere((_) => true,
                                            orElse: () => null);
                                    break;
                                  case shared
                                        .MenuItemSchemaIssueType.missingField:
                                    break;
                                }
                                if (mapped != null && mapped.isNotEmpty) {
                                  updated =
                                      repairMenuItem(updated, issue, mapped);
                                }
                              }

                              session.updateDraft(updated);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ImageUploadField(
                      initialValue: session.draft.imageUrl ?? '',
                      onSaved: (url) => session.updateDraft(
                          session.draft.copyWith(image: url ?? '')),
                    ),
                    const SizedBox(height: 16),
                    SizePricingEditor(
                      sizes: session.draft.sizes ?? [],
                      onChanged: (newSizes) => session
                          .updateDraft(session.draft.copyWith(sizes: newSizes)),
                      trailingTemplateDropdown:
                          DropdownButton<shared.SizeTemplate>(
                        value: Provider.of<shared.MenuItemProvider>(context)
                            .sizeTemplates
                            .firstWhereOrNull(
                              (t) => const DeepCollectionEquality()
                                  .equals(t.sizes, session.draft.sizes),
                            ),
                        hint: const Text('Load Size Template'),
                        items: Provider.of<shared.MenuItemProvider>(context)
                            .sizeTemplates
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (template) {
                          if (template != null) {
                            session.updateDraft(
                                session.draft.copyWith(sizes: template.sizes));
                          }
                        },
                      ),
                    ),

                    const Divider(height: 32),

                    // Legacy includedIngredients / optionalAddOns / customizationGroups
                    // UI removed (Decision 10). Canonical path: menuProfile + modifierGroups.

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
