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
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/multi_ingredient_selector.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/customization_group_editor.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/nutrition_editor_dialog.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/preview_menu_item_card.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_template_dropdown.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_utility.dart';
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

    // Initial computation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _session.forceRecomputeIssues();
    });
  }

  void repairSchemaIssue(shared.MenuItemSchemaIssue issue, String newValue) {
    _session.repairIssue(issue, newValue);
    // Force UI refresh in parent
    widget.onSchemaIssuesChanged?.call(_session.issues);
  }

  void _saveItem() {
    if (_session.issues.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Resolve remaining schema issues first'),
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
      customizationGroups:
          customizationGroupsFromDraft(_session.draft.customizationGroups),
      includedIngredients:
          ingredientRefsFromDraft(_session.draft.includedIngredients),
      optionalAddOns: ingredientRefsFromDraft(_session.draft.optionalAddOns),
      customizations: _session.draft.customizations ?? [],
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
    );

    widget.onSave(savedItem);
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
          return Scaffold(
            appBar: AppBar(
              title: Text(session.draft.id.isEmpty
                  ? 'New Menu Item'
                  : 'Edit ${session.draft.name}'),
              actions: [
                IconButton(
                    onPressed: widget.onCancel, icon: const Icon(Icons.close)),
                ElevatedButton(
                  onPressed: session.issues.isEmpty && session.isDirty
                      ? _saveItem
                      : null,
                  child: const Text('Save & Publish'),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // === BASIC INFO ===
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
                          helperText: 'Shown to customers'),
                      maxLines: 3,
                      onChanged: (v) => session.updateDraft(
                          session.draft.copyWith(description: v.trim())),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Description required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: session.draft.price.toString(),
                            decoration: const InputDecoration(
                                labelText: 'Base Price *', prefixText: '\$'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (v) => session.updateDraft(session.draft
                                .copyWith(price: double.tryParse(v) ?? 0.0)),
                            validator: (v) =>
                                (double.tryParse(v ?? '') ?? 0.0) <= 0
                                    ? 'Price must be > 0'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: Provider.of<shared.CategoryProvider>(context)
                                .resolveCategoryId(session.draft.categoryId),
                            decoration:
                                const InputDecoration(labelText: 'Category *'),
                            items: Provider.of<shared.CategoryProvider>(context)
                                .uniqueCategories
                                .map((cat) => DropdownMenuItem<String>(
                                      value: cat.id,
                                      child: Text(cat.name),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                session.updateDraft(
                                    session.draft.copyWith(categoryId: val));
                            },
                            validator: (v) =>
                                v == null ? 'Category required' : null,
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      value: session.draft.outOfStock ?? false,
                      onChanged: (v) => session.updateDraft(
                          session.draft.copyWith(availability: !v)),
                      title: const Text('Out of Stock'),
                      subtitle: const Text('Temporarily unavailable'),
                    ),
                    const SizedBox(height: 20),

                    // === IMAGE & TEMPLATE ===
                    Row(
                      children: [
                        const Text('Menu Item Template:',
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
                              final updated =
                                  applyTemplateToDraft(session.draft, template);
                              session.updateDraft(updated);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ImageUploadField(
                      initialValue: session.draft.imageUrl ?? '',
                      onSaved: (url) => session.updateDraft(
                          session.draft.copyWith(image: url ?? '')),
                    ),

                    const Divider(height: 40),

                    // === SIZE & PRICING ===
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
                          if (template != null)
                            session.updateDraft(
                                session.draft.copyWith(sizes: template.sizes));
                        },
                      ),
                    ),

                    const Divider(height: 40),

                    // === INGREDIENTS & ADD-ONS ===
                    MultiIngredientSelector(
                      title: 'Included Ingredients',
                      selected: ingredientRefsFromDraft(
                          session.draft.includedIngredients),
                      onChanged: (list) => session.updateDraft(session.draft
                          .copyWith(
                              includedIngredients:
                                  ingredientRefsToDraft(list))),
                    ),
                    const SizedBox(height: 12),
                    MultiIngredientSelector(
                      title: 'Optional Add-ons',
                      selected:
                          ingredientRefsFromDraft(session.draft.optionalAddOns),
                      onChanged: (list) => session.updateDraft(session.draft
                          .copyWith(
                              optionalAddOns: ingredientRefsToDraft(list))),
                    ),

                    // ...

                    CustomizationGroupEditor(
                      value: customizationGroupsFromDraft(
                          session.draft.customizationGroups),
                      onChanged: (groups) => session.updateDraft(session.draft
                          .copyWith(
                              customizationGroups:
                                  customizationGroupsToDraft(groups))),
                    ),

                    const Divider(height: 40),

                    // === NUTRITION ===
                    shared.FeatureGuard(
                      module: shared.PlatformFeature.nutritionalInfo.key,
                      fallback: const SizedBox.shrink(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nutrition Info',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () async {
                              final result =
                                  await showDialog<shared.NutritionInfo?>(
                                context: context,
                                builder: (_) => NutritionEditorDialog(
                                    initialValue: session.draft.nutrition),
                              );
                              if (result != null)
                                session.updateDraft(
                                    session.draft.copyWith(nutrition: result));
                            },
                            child: Text(session.draft.nutrition == null
                                ? 'Add Nutrition'
                                : 'Edit Nutrition'),
                          ),
                          if (session.draft.nutrition != null)
                            Text(
                                '${session.draft.nutrition!.calories} cal • P:${session.draft.nutrition!.protein}g • F:${session.draft.nutrition!.fat}g • C:${session.draft.nutrition!.carbs}g'),
                        ],
                      ),
                    ),

                    const Divider(height: 40),

                    // === LIVE PREVIEW ===
                    ExpansionTile(
                      title: const Text('Live Mobile Preview'),
                      children: [PreviewMenuItemCard(menuItem: session.draft)],
                    ),

                    const Divider(height: 40),

                    // === SCHEMA ISSUES DISPLAY ===
                    if (session.issues.isNotEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Active Schema Issues: ${session.issues.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)),
                              const SizedBox(height: 8),
                              ...session.issues.map((issue) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.error_outline,
                                        color: Colors.orange, size: 18),
                                    title: Text(issue.displayMessage),
                                    trailing: TextButton(
                                      child: const Text('Fix'),
                                      onPressed: () {
                                        // Trigger repair UI in sidebar or inline dropdown
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Open sidebar to repair: ${issue.displayMessage}')));
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      )
                    else
                      const ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('✅ Schema clean – ready to publish'),
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
                    onPressed: session.issues.isEmpty && session.isDirty
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
