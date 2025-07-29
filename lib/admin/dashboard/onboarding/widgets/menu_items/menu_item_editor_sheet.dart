import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/size_pricing_editor.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/ingredient_reference.dart';
import 'package:franchise_admin_portal/core/models/nutrition_info.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/models/customization.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/image_upload_field.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/multi_ingredient_selector.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/customization_group_editor.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/nutrition_editor_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/preview_menu_item_card.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/core/models/customization_group.dart';
import 'package:franchise_admin_portal/core/utils/features/feature_guard.dart';
import 'package:franchise_admin_portal/core/utils/features/enum_platform_features.dart';
import 'package:franchise_admin_portal/core/models/size_template.dart';
import 'package:collection/collection.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_dropdown.dart';
import 'package:flutter/foundation.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:franchise_admin_portal/core/models/menu_item_schema_issue.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';

class MenuItemEditorSheet extends StatefulWidget {
  final MenuItem? existing;
  final void Function(MenuItem item) onSave;
  final VoidCallback onCancel;

  const MenuItemEditorSheet({
    Key? key,
    this.existing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<MenuItemEditorSheet> createState() => _MenuItemEditorSheetState();
}

class _MenuItemEditorSheetState extends State<MenuItemEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  List<CustomizationGroup> customizationGroups = [];
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String description;
  late double price;
  String? categoryId;
  bool outOfStock = false;
  String imageUrl = '';
  List<String> selectedTemplateRefs = [];
  NutritionInfo? nutrition;
  List<IngredientReference> includedIngredients = [];
  List<IngredientReference> optionalAddOns = [];
  List<Customization> customizations = [];
  List<SizeData> sizeData = [];
  String? get selectedTemplate =>
      selectedTemplateRefs.isNotEmpty ? selectedTemplateRefs.first : null;

  bool isDirty = false;
  List<MenuItem> availableTemplates = [];
  bool loadingTemplates = true;
  List<MenuItemSchemaIssue> _schemaIssues = [];
  bool _showSchemaSidebar = false;

  // --- ADVANCED FIELDS ---
  String? notes;
  String? sku;
  List<String> dietaryTags = [];
  List<String> allergens = [];
  int? prepTime;
  int? sortOrder;
  String taxCategory = 'standard';
  String? exportId;
  List<String>? crustTypes;
  List<String>? cookTypes;
  List<String>? cutStyles;
  List<String>? sauceOptions;
  List<String>? dressingOptions;
  int? maxFreeToppings;
  int? maxFreeSauces;
  int? maxFreeDressings;
  int? maxToppings;
  DateTime? customizationsUpdatedAt;
  DateTime? createdAt;
  String? comboId;
  List<String>? bundleItems;
  double? bundleDiscount;
  List<String>? highlightTags;
  bool? allowSpecialInstructions;
  bool? hideInMenu;
  dynamic freeSauceCount;
  double? extraSauceUpcharge;
  dynamic freeDressingCount;
  double? extraDressingUpcharge;
  List<String>? dippingSauceOptions;
  Map<String, int>? dippingSplits;
  List<String>? sideDipSauceOptions;
  Map<String, int>? freeDipCupCount;
  Map<String, double>? sideDipUpcharge;
  Map<String, dynamic>? extraCharges;
  List<Map<String, dynamic>>? rawCustomizations;

  @override
  void initState() {
    print(
        '[MenuItemEditorSheet] initState: existing=${widget.existing != null}');
    final item = widget.existing;

    // --- Controller initialization ---
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _priceController =
        TextEditingController(text: item?.price?.toString() ?? '');

    name = item?.name ?? '';
    description = item?.description ?? '';
    price = item?.price ?? 0.0;
    categoryId = item?.categoryId;
    outOfStock = item?.outOfStock ?? false;
    imageUrl = item?.imageUrl ?? '';
    selectedTemplateRefs = List<String>.from(item?.templateRefs ?? []);
    nutrition = item?.nutrition;
    includedIngredients = List.from(item?.includedIngredients ?? []);
    optionalAddOns = List.from(item?.optionalAddOns ?? []);
    customizations = List.from(item?.customizations ?? []);
    sizeData = List.from(item?.sizes ?? []);
    customizationGroups = (item?.customizationGroups != null)
        ? (item!.customizationGroups as List)
            .map(
                (g) => CustomizationGroup.fromMap(Map<String, dynamic>.from(g)))
            .toList()
        : [];
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final franchise = context.read<FranchiseInfoProvider>().franchise;
      if (franchise?.restaurantType != null) {
        await context
            .read<MenuItemProvider>()
            .loadSizeTemplates(franchise!.restaurantType!);
      }
    });
  }

  void _checkForSchemaIssues() {
    final categories = context.read<CategoryProvider>().categories;
    final ingredients =
        context.read<IngredientMetadataProvider>().allIngredients;
    final ingredientTypes =
        context.read<IngredientTypeProvider>().ingredientTypes;

    // Construct a temporary MenuItem using the current editor values
    final tempItem = MenuItem(
      id: widget.existing?.id ?? '',
      available: !outOfStock,
      availability: !outOfStock,
      category:
          categories.firstWhereOrNull((cat) => cat.id == categoryId)?.name ??
              '',
      categoryId: categoryId ?? '',
      name: name,
      price: price,
      description: description,
      notes: notes,
      sku: sku,
      dietaryTags: dietaryTags,
      allergens: allergens,
      prepTime: prepTime,
      sortOrder: sortOrder,
      taxCategory: taxCategory,
      exportId: exportId,
      customizationGroups: customizationGroups.map((g) => g.toMap()).toList(),
      includedIngredients: includedIngredients.map((i) => i.toMap()).toList(),
      optionalAddOns: optionalAddOns.map((i) => i.toMap()).toList(),
      customizations: customizations,
      image: imageUrl,
      nutrition: nutrition,
      templateRefs: selectedTemplateRefs,
      sizes: sizeData,
      // --- Advanced Fields ---
      crustTypes: crustTypes,
      cookTypes: cookTypes,
      cutStyles: cutStyles,
      sauceOptions: sauceOptions,
      dressingOptions: dressingOptions,
      maxFreeToppings: maxFreeToppings,
      maxFreeSauces: maxFreeSauces,
      maxFreeDressings: maxFreeDressings,
      maxToppings: maxToppings,
      customizationsUpdatedAt: customizationsUpdatedAt,
      createdAt: createdAt,
      comboId: comboId,
      bundleItems: bundleItems,
      bundleDiscount: bundleDiscount,
      highlightTags: highlightTags,
      allowSpecialInstructions: allowSpecialInstructions,
      hideInMenu: hideInMenu,
      freeSauceCount: freeSauceCount,
      extraSauceUpcharge: extraSauceUpcharge,
      freeDressingCount: freeDressingCount,
      extraDressingUpcharge: extraDressingUpcharge,
      dippingSauceOptions: dippingSauceOptions,
      dippingSplits: dippingSplits,
      sideDipSauceOptions: sideDipSauceOptions,
      freeDipCupCount: freeDipCupCount,
      sideDipUpcharge: sideDipUpcharge,
      extraCharges: extraCharges,
      rawCustomizations: rawCustomizations,
    );

    // Use the unified robust detection for *all* possible issues (ingredient, type, etc)
    final issues = MenuItemSchemaIssue.detectAllIssues(
      menuItem: tempItem,
      categories: categories,
      ingredients: ingredients,
      ingredientTypes: ingredientTypes,
    );

    setState(() {
      _schemaIssues = issues;
      _showSchemaSidebar = issues.isNotEmpty;
    });
  }

  void _applyTemplate(MenuItem item) {
    print('[MenuItemEditorSheet] _applyTemplate called with item: '
        'id=${item.id}, name=${item.name}, categoryId=${item.categoryId}, '
        'customizationGroups=${item.customizationGroups?.length ?? 0}');
    print('[MenuItemEditorSheet] Template data dump: ${item.toJson()}');
    try {
      setState(() {
        // --- Update controllers for user-editable fields ---
        _nameController.text = item.name ?? '';
        name = item.name ?? '';

        _descriptionController.text = item.description ?? '';
        description = item.description ?? '';

        _priceController.text = (item.price ?? 0.0).toString();
        price = item.price ?? 0.0;

        categoryId = item.categoryId ?? '';
        imageUrl = item.imageUrl ?? '';
        nutrition = item.nutrition;
        includedIngredients = (item.includedIngredients ?? [])
            .map((e) => e is IngredientReference
                ? e
                : IngredientReference.fromMap(Map<String, dynamic>.from(e)))
            .toList()
            .cast<IngredientReference>();
        optionalAddOns = (item.optionalAddOns ?? [])
            .map((e) => e is IngredientReference
                ? e
                : IngredientReference.fromMap(Map<String, dynamic>.from(e)))
            .toList()
            .cast<IngredientReference>();
        customizations = List.from(item.customizations ?? []);
        final sizesValue = item.sizes;
        if (sizesValue != null &&
            sizesValue is List<SizeData> &&
            sizesValue.isNotEmpty) {
          sizeData = List<SizeData>.from(sizesValue);
        } else if (sizesValue != null &&
            sizesValue is List &&
            sizesValue.isNotEmpty &&
            (item.sizePrices != null || item.additionalToppingPrices != null)) {
          final basePriceMap = item.sizePrices ?? {};
          final toppingPriceMap = item.additionalToppingPrices ?? {};
          sizeData = sizesValue
              .map((s) => SizeData(
                    label: s.toString(),
                    basePrice:
                        (basePriceMap[s.toString()] as num?)?.toDouble() ?? 0.0,
                    toppingPrice:
                        (toppingPriceMap[s.toString()] as num?)?.toDouble() ??
                            0.0,
                  ))
              .toList();
        } else {
          sizeData = [];
        }

        final ingredientMap = {
          for (var ing
              in context.read<IngredientMetadataProvider>().allIngredients)
            ing.id: ing
        };

        customizationGroups = (item.customizationGroups ?? []).map((g) {
          final groupMap = Map<String, dynamic>.from(g);

          // 1. If group has 'ingredientIds' (legacy), generate 'ingredients'
          if (groupMap['ingredientIds'] is List &&
              groupMap['ingredientIds'].isNotEmpty) {
            groupMap['ingredients'] =
                (groupMap['ingredientIds'] as List).map((id) {
              final meta = ingredientMap[id];
              if (meta != null) return meta.toMap();
              return {'id': id, 'name': id, 'typeId': '', 'isRemovable': true};
            }).toList();
          }

          // 2. If 'ingredients' exists, ensure every entry is a Map
          if (groupMap['ingredients'] is List) {
            groupMap['ingredients'] =
                (groupMap['ingredients'] as List).map((e) {
              if (e is String) {
                return {'id': e, 'name': e, 'typeId': '', 'isRemovable': true};
              }
              if (e is Map) return e;
              print(
                  '[DEBUG] Ingredient entry type: ${e.runtimeType} | value: $e');
              if (e is IngredientReference) return e.toMap();
              // Fallback for legacy/unknown
              return {
                'id': e.toString(),
                'name': e.toString(),
                'typeId': '',
                'isRemovable': true
              };
            }).toList();
          } else {
            // 3. Defensive: If 'ingredients' is missing or not a List, create empty list
            groupMap['ingredients'] = <Map<String, dynamic>>[];
          }

          // 4. Always remove 'ingredientIds' to prevent model confusion
          groupMap.remove('ingredientIds');

          // Now safe to call:
          return CustomizationGroup.fromMap(groupMap);
        }).toList();

        selectedTemplateRefs = item.templateRefs ?? [];
        notes = item.notes;
        sku = item.sku;
        dietaryTags = List<String>.from(item.dietaryTags ?? []);
        allergens = List<String>.from(item.allergens ?? []);
        prepTime = item.prepTime;
        sortOrder = item.sortOrder;
        taxCategory = item.taxCategory ?? 'standard';
        exportId = item.exportId;
        crustTypes = item.crustTypes;
        cookTypes = item.cookTypes;
        cutStyles = item.cutStyles;
        sauceOptions = item.sauceOptions;
        dressingOptions = item.dressingOptions;
        maxFreeToppings = item.maxFreeToppings;
        maxFreeSauces = item.maxFreeSauces;
        maxFreeDressings = item.maxFreeDressings;
        maxToppings = item.maxToppings;
        customizationsUpdatedAt = item.customizationsUpdatedAt;
        createdAt = item.createdAt;
        comboId = item.comboId;
        bundleItems = item.bundleItems;
        bundleDiscount = item.bundleDiscount;
        highlightTags = item.highlightTags;
        allowSpecialInstructions = item.allowSpecialInstructions;
        hideInMenu = item.hideInMenu;
        freeSauceCount = item.freeSauceCount;
        extraSauceUpcharge = item.extraSauceUpcharge;
        freeDressingCount = item.freeDressingCount;
        extraDressingUpcharge = item.extraDressingUpcharge;
        dippingSauceOptions = item.dippingSauceOptions;
        dippingSplits = item.dippingSplits;
        sideDipSauceOptions = item.sideDipSauceOptions;
        freeDipCupCount = item.freeDipCupCount;
        sideDipUpcharge = item.sideDipUpcharge;
        extraCharges = item.extraCharges;
        rawCustomizations = item.rawCustomizations;
        isDirty = true;
        _checkForSchemaIssues();
      });
      // Trigger re-validation after UI updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });
    } catch (e, st) {
      print('[MenuItemEditorSheet] ERROR applying template: $e\n$st');
      ErrorLogger.log(
        message: 'Failed to apply template into editor state',
        source: 'menu_item_editor_sheet.dart',
        screen: 'menu_item_editor_sheet.dart',
        severity: 'warning',
        stack: st.toString(),
        contextData: {
          'templateRefs': item.templateRefs?.join(', ') ?? 'none',
          'menuItemId': item.id,
          'name': item.name,
          'env': kReleaseMode ? 'production' : 'development',
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply template. See logs.')),
      );
    }
  }

  void _saveItem() {
    print(
        '[DEBUG] Save Button Enabled: schemaIssues=${_schemaIssues.length}, isDirty=$isDirty');

    // Sync fields from controllers before checking schema
    name = _nameController.text.trim();
    description = _descriptionController.text.trim();
    price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    _checkForSchemaIssues();
    print(
        '[DEBUG] Schema issues at save: ${_schemaIssues.map((e) => e.displayMessage).toList()}');

    if (_schemaIssues.isNotEmpty) {
      setState(() {
        _showSchemaSidebar = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolve all schema issues before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('[MenuItemEditorSheet] _saveItem called');
    print('[MenuItemEditorSheet] Current form state: '
        'name=$name, description=$description, price=$price, categoryId=$categoryId, '
        'imageUrl=$imageUrl, includedIngredients=${includedIngredients.length}, '
        'optionalAddOns=${optionalAddOns.length}, customizations=${customizations.length}, '
        'customizationGroups=${customizationGroups.length}, sizeData=${sizeData.length}, '
        'selectedTemplateRefs=$selectedTemplateRefs, nutrition=$nutrition, outOfStock=$outOfStock');
    final categories = context.read<CategoryProvider>().categories;
    if (!_formKey.currentState!.validate()) return;

    if (categoryId == null || categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final categoryName =
        categories.firstWhere((cat) => cat.id == categoryId).name;

    if (sizeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one size.')),
      );
      return;
    }
    print('[MenuItemEditorSheet] Constructing MenuItem for save...');
    final item = MenuItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      available: !outOfStock,
      availability: !outOfStock, // Negate outOfStock for availability
      category: categoryName,
      categoryId: categoryId!,
      name: name,
      price: price,
      description: description,
      notes: notes,
      sku: sku,
      dietaryTags: dietaryTags,
      allergens: allergens,
      prepTime: prepTime,
      sortOrder: sortOrder,
      taxCategory: taxCategory,
      exportId: exportId,
      customizationGroups: customizationGroups.map((g) => g.toMap()).toList(),
      includedIngredients: includedIngredients.map((i) => i.toMap()).toList(),
      optionalAddOns: optionalAddOns.map((i) => i.toMap()).toList(),
      customizations: customizations,
      image: imageUrl,
      nutrition: nutrition,
      templateRefs: selectedTemplateRefs,
      sizes: sizeData,
      // --- ADVANCED FIELDS ---
      crustTypes: crustTypes,
      cookTypes: cookTypes,
      cutStyles: cutStyles,
      sauceOptions: sauceOptions,
      dressingOptions: dressingOptions,
      maxFreeToppings: maxFreeToppings,
      maxFreeSauces: maxFreeSauces,
      maxFreeDressings: maxFreeDressings,
      maxToppings: maxToppings,
      customizationsUpdatedAt: customizationsUpdatedAt,
      createdAt: createdAt,
      comboId: comboId,
      bundleItems: bundleItems,
      bundleDiscount: bundleDiscount,
      highlightTags: highlightTags,
      allowSpecialInstructions: allowSpecialInstructions,
      hideInMenu: hideInMenu,
      freeSauceCount: freeSauceCount,
      extraSauceUpcharge: extraSauceUpcharge,
      freeDressingCount: freeDressingCount,
      extraDressingUpcharge: extraDressingUpcharge,
      dippingSauceOptions: dippingSauceOptions,
      dippingSplits: dippingSplits,
      sideDipSauceOptions: sideDipSauceOptions,
      freeDipCupCount: freeDipCupCount,
      sideDipUpcharge: sideDipUpcharge,
      extraCharges: extraCharges,
      rawCustomizations: rawCustomizations,
    );

    print('[MenuItemEditorSheet] MenuItem constructed: ${item.toJson()}');
    widget.onSave(item);
  }

  void _editNutrition() async {
    final result = await showDialog<NutritionInfo?>(
      context: context,
      builder: (_) => NutritionEditorDialog(initialValue: nutrition),
    );

    if (result != null) {
      setState(() {
        nutrition = result;
        isDirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final templates = context.read<MenuItemProvider>().templateRefs;
    final availableTemplates = context.watch<MenuItemProvider>().sizeTemplates;
    final hasCategories = categories.isNotEmpty;
    final hasIngredients =
        context.read<IngredientMetadataProvider>().allIngredients.isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
                widget.existing == null ? 'Add Menu Item' : 'Edit Menu Item'),
            actions: [
              TextButton(
                onPressed: (!(_showSchemaSidebar && _schemaIssues.isNotEmpty) &&
                        (_schemaIssues.isEmpty || isDirty))
                    ? _saveItem
                    : null,
                child: const Text('Save'),
              )
            ],
          ),
          body: SafeArea(
            child: !hasCategories || !hasIngredients
                ? EmptyStateWidget(
                    title: 'No Categories or Ingredients',
                    message:
                        'You must create at least one category and one ingredient before adding menu items.',
                    iconData: Icons.warning_amber_rounded,
                    isAdmin: true,
                  )
                : SingleChildScrollView(
                    controller: ScrollController(),
                    padding: const EdgeInsets.all(16),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Form(
                        key: _formKey,
                        onChanged: () => setState(() => isDirty = true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 0: Menu Item Template Dropdown
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Menu Item Template:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MenuItemTemplateDropdown(
                                    selectedTemplateId: selectedTemplate,
                                    onTemplateApplied: _applyTemplate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Section 1: Basic Info
                            TextFormField(
                              controller: _nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                              onChanged: (val) => name = val,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Name required'
                                  : null,
                            ),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                  labelText: 'Description'),
                              onChanged: (val) => description = val,
                              maxLines: 2,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'Price'),
                                    onChanged: (val) =>
                                        price = double.tryParse(val) ?? 0.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: categories
                                            .any((cat) => cat.id == categoryId)
                                        ? categoryId
                                        : null,
                                    decoration: const InputDecoration(
                                        labelText: 'Category'),
                                    items: categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat.id,
                                              child: Text(cat.name),
                                            ))
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => categoryId = val),
                                  ),
                                ),
                              ],
                            ),
                            SwitchListTile(
                              value: outOfStock,
                              onChanged: (val) =>
                                  setState(() => outOfStock = val),
                              title: const Text('Out of Stock'),
                            ),

                            const SizedBox(height: 20),

                            ExpansionTile(
                              title: const Text('Advanced Fields'),
                              initiallyExpanded: false,
                              children: [
                                TextFormField(
                                  initialValue: notes ?? '',
                                  decoration:
                                      const InputDecoration(labelText: 'Notes'),
                                  onChanged: (val) => notes = val,
                                ),
                                TextFormField(
                                  initialValue: sku ?? '',
                                  decoration:
                                      const InputDecoration(labelText: 'SKU'),
                                  onChanged: (val) => sku = val,
                                ),
                                TextFormField(
                                  initialValue: taxCategory,
                                  decoration: const InputDecoration(
                                      labelText: 'Tax Category'),
                                  onChanged: (val) => taxCategory = val,
                                ),
                                TextFormField(
                                  initialValue: prepTime?.toString() ?? '',
                                  decoration: const InputDecoration(
                                      labelText: 'Prep Time (min)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) =>
                                      prepTime = int.tryParse(val),
                                ),
                                // Add more as needed, or use ChipsInput for tags/allergens, etc.
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section 2b: Size Pricing
                            SizePricingEditor(
                              sizes: sizeData,
                              onChanged: (val) {
                                print(
                                    '[MenuItemEditorSheet] sizeData changed: $val');
                                setState(() {
                                  sizeData = val;
                                  isDirty = true;
                                });
                              },
                              trailingTemplateDropdown:
                                  DropdownButton<SizeTemplate>(
                                isExpanded: true,
                                value: availableTemplates.firstWhereOrNull(
                                  (t) => const DeepCollectionEquality()
                                      .equals(t.sizes, sizeData),
                                ),
                                hint: const Text('Template (optional)'),
                                items: availableTemplates
                                    .map((template) => DropdownMenuItem(
                                          value: template,
                                          child: Text(template.label),
                                        ))
                                    .toList(),
                                onChanged: (template) {
                                  if (template != null) {
                                    setState(() {
                                      sizeData = template.sizes;
                                      isDirty = true;
                                    });
                                  }
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Divider(height: 40),

                            // Section 3: Included Ingredients
                            MultiIngredientSelector(
                              title: 'Included Ingredients',
                              selected: includedIngredients,
                              onChanged: (val) =>
                                  setState(() => includedIngredients = val),
                            ),

                            const SizedBox(height: 16),

                            // Section 4: Optional Add-ons
                            MultiIngredientSelector(
                              title: 'Optional Add-ons',
                              selected: optionalAddOns,
                              onChanged: (val) =>
                                  setState(() => optionalAddOns = val),
                            ),

                            const Divider(height: 40),

                            // Section 5: Customizations
                            CustomizationGroupEditor(
                              value: customizationGroups,
                              onChanged: (val) =>
                                  setState(() => customizationGroups = val),
                            ),

                            const Divider(height: 40),

                            // Section 6: Nutrition (FeatureGuard)
                            FeatureGuard(
                              module: PlatformFeature.nutritionalInfo.key,
                              fallback: const SizedBox.shrink(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nutrition Info',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: _editNutrition,
                                    child: Text(nutrition == null
                                        ? 'Add Nutrition'
                                        : 'Edit Nutrition'),
                                  ),
                                  if (nutrition != null)
                                    Text(
                                      '${nutrition!.calories} cal | Protein: ${nutrition!.protein}g | Fat: ${nutrition!.fat}g | Carbs: ${nutrition!.carbs}g',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),

                            const Divider(height: 40),

                            // Section 7: Image Upload
                            ImageUploadField(
                              initialValue: imageUrl,
                              onSaved: (val) => imageUrl = val ?? '',
                              validator: (val) => null,
                            ),

                            const Divider(height: 40),

                            // Preview Section
                            ExpansionTile(
                              title: const Text('Live Preview'),
                              initiallyExpanded: false,
                              children: [
                                PreviewMenuItemCard(
                                  menuItem: MenuItem(
                                    id: widget.existing?.id ??
                                        const Uuid().v4(),
                                    available: !outOfStock,
                                    category: categoryId ?? '',
                                    categoryId: categoryId ?? '',
                                    name: name,
                                    price: price,
                                    description: description,
                                    notes: null,
                                    customizationGroups: [],
                                    image: imageUrl,
                                    taxCategory: 'standard',
                                    availability: !outOfStock,
                                    sku: null,
                                    dietaryTags: [],
                                    allergens: [],
                                    prepTime: null,
                                    nutrition: nutrition,
                                    sortOrder: null,
                                    lastModified: null,
                                    lastModifiedBy: null,
                                    archived: false,
                                    exportId: null,
                                    sizes: null,
                                    sizePrices: null,
                                    additionalToppingPrices: null,
                                    includedIngredients: includedIngredients
                                        .map((e) => e.toMap())
                                        .toList(),
                                    optionalAddOns: optionalAddOns
                                        .map((e) => e.toMap())
                                        .toList(),
                                    customizations: customizations,
                                    crustTypes: null,
                                    cookTypes: null,
                                    cutStyles: null,
                                    sauceOptions: null,
                                    dressingOptions: null,
                                    maxFreeToppings: null,
                                    maxFreeSauces: null,
                                    maxFreeDressings: null,
                                    maxToppings: null,
                                    customizationsUpdatedAt: null,
                                    createdAt: null,
                                    comboId: null,
                                    bundleItems: null,
                                    bundleDiscount: null,
                                    highlightTags: null,
                                    allowSpecialInstructions: null,
                                    hideInMenu: null,
                                    freeSauceCount: null,
                                    extraSauceUpcharge: null,
                                    freeDressingCount: null,
                                    extraDressingUpcharge: null,
                                    dippingSauceOptions: null,
                                    dippingSplits: null,
                                    sideDipSauceOptions: null,
                                    freeDipCupCount: null,
                                    sideDipUpcharge: null,
                                    extraCharges: null,
                                    rawCustomizations: null,
                                    templateRefs: selectedTemplateRefs,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Row(
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed:
                      (!(_showSchemaSidebar && _schemaIssues.isNotEmpty) &&
                              (_schemaIssues.isEmpty || isDirty))
                          ? _saveItem
                          : null,
                  child: const Text('Save'),
                )
              ],
            ),
          ),
        ),
        if (_showSchemaSidebar)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: SchemaIssueSidebar(
              issues: _schemaIssues,
              onRepair: (issue, newValue) {
                setState(() {
                  if (issue.type == MenuItemSchemaIssueType.category) {
                    categoryId = newValue;
                  } else if (issue.type == MenuItemSchemaIssueType.ingredient) {
                    // Check all ingredient locations
                    for (var i = 0; i < includedIngredients.length; i++) {
                      if (includedIngredients[i].id == issue.missingReference) {
                        includedIngredients[i] =
                            includedIngredients[i].copyWith(id: newValue);
                      }
                    }
                    for (var i = 0; i < optionalAddOns.length; i++) {
                      if (optionalAddOns[i].id == issue.missingReference) {
                        optionalAddOns[i] =
                            optionalAddOns[i].copyWith(id: newValue);
                      }
                    }
                    // Repair inside customizationGroups options
                    for (var groupIdx = 0;
                        groupIdx < customizationGroups.length;
                        groupIdx++) {
                      final group = customizationGroups[groupIdx];
                      for (var ingIdx = 0;
                          ingIdx < group.ingredients.length;
                          ingIdx++) {
                        if (group.ingredients[ingIdx].id ==
                            issue.missingReference) {
                          group.ingredients[ingIdx] =
                              group.ingredients[ingIdx].copyWith(id: newValue);
                        }
                      }
                    }
                  } else if (issue.type ==
                      MenuItemSchemaIssueType.ingredientType) {
                    // FIX: Ingredient Type repair
                    // Update typeId/type on all ingredient locations matching the label/missingReference
                    for (var i = 0; i < includedIngredients.length; i++) {
                      if (includedIngredients[i].name == issue.label ||
                          includedIngredients[i].id == issue.missingReference) {
                        includedIngredients[i] =
                            includedIngredients[i].copyWith(typeId: newValue);
                      }
                    }
                    for (var i = 0; i < optionalAddOns.length; i++) {
                      if (optionalAddOns[i].name == issue.label ||
                          optionalAddOns[i].id == issue.missingReference) {
                        optionalAddOns[i] =
                            optionalAddOns[i].copyWith(typeId: newValue);
                      }
                    }
                    for (var group in customizationGroups) {
                      for (var j = 0; j < group.ingredients.length; j++) {
                        if (group.ingredients[j].name == issue.label ||
                            group.ingredients[j].id == issue.missingReference) {
                          group.ingredients[j] =
                              group.ingredients[j].copyWith(typeId: newValue);
                        }
                      }
                    }
                  }
                  // Mark issue as resolved
                  _schemaIssues = _schemaIssues.map((e) {
                    return e == issue ? e.markResolved(true) : e;
                  }).toList();
                  isDirty = true;
                });
                Future.delayed(
                    const Duration(milliseconds: 100), _checkForSchemaIssues);
              },
              onClose: () {
                setState(() => _showSchemaSidebar = false);
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
