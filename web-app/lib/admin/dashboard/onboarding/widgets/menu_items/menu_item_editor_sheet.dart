import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/size_pricing_editor.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/image_upload_field.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/multi_ingredient_selector.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/customization_group_editor.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/nutrition_editor_dialog.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/preview_menu_item_card.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_template_dropdown.dart';
import 'package:flutter/foundation.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
// --- Utilities ---
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/ui_config.dart';

class MenuItemEditorSheet extends StatefulWidget {
  final shared.MenuItem? existing;
  final void Function(shared.MenuItem item) onSave;
  final VoidCallback onCancel;
  final void Function(List<shared.MenuItemSchemaIssue> issues)?
      onSchemaIssuesChanged;
  final FirebaseFirestore firestore;
  final String franchiseId;

  const MenuItemEditorSheet({
    super.key,
    this.existing,
    required this.onCancel,
    required this.onSave,
    required this.onSchemaIssuesChanged,
    required this.firestore,
    required this.franchiseId,
  });

  @override
  State<MenuItemEditorSheet> createState() => MenuItemEditorSheetState();
}

class MenuItemEditorSheetState extends State<MenuItemEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  DateTime? _lastCheckTime;
  final _formKey = GlobalKey<FormState>();

  // Core fields
  String name = '';
  String description = '';
  double price = 0.0;
  String? categoryId;
  bool outOfStock = false;
  String imageUrl = '';
  List<String> selectedTemplateRefs = [];
  shared.NutritionInfo? nutrition;
  List<shared.IngredientReference> includedIngredients = [];
  List<shared.IngredientReference> optionalAddOns = [];
  List<shared.Customization> customizations = [];
  List<shared.SizeData> sizeData = [];
  List<shared.CustomizationGroup> customizationGroups = [];

  // Advanced fields (full preservation)
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

  bool isDirty = false;
  List<shared.MenuItemSchemaIssue> _schemaIssues = [];
  bool _showSchemaSidebar = false;

  String? get selectedTemplate =>
      selectedTemplateRefs.isNotEmpty ? selectedTemplateRefs.first : null;

  shared.MenuItem? get currentEditingItem {
    return buildMenuItemForSchemaCheck(
      existing: widget.existing,
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      outOfStock: outOfStock,
      imageUrl: imageUrl,
      customizationGroups: customizationGroups,
      includedIngredients: includedIngredients,
      optionalAddOns: optionalAddOns,
      customizations: customizations,
      nutrition: nutrition,
      selectedTemplateRefs: selectedTemplateRefs,
      sizeData: sizeData,
      categories: [], // temporary for schema check
      notes: notes ?? '',
      sku: sku ?? '',
      dietaryTags: dietaryTags,
      allergens: allergens,
      prepTime: prepTime,
      sortOrder: sortOrder,
      taxCategory: taxCategory,
      exportId: exportId ?? '',
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
  }

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _priceController =
        TextEditingController(text: item?.price?.toString() ?? '');

    _hydrateFromItem(item);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProvidersAndCheck();
    });
  }

  void _hydrateFromItem(shared.MenuItem? item) {
    name = item?.name ?? '';
    description = item?.description ?? '';
    price = item?.price ?? 0.0;
    categoryId = item?.categoryId;
    outOfStock = item?.outOfStock ?? false;
    imageUrl = item?.imageUrl ?? '';
    selectedTemplateRefs = List<String>.from(item?.templateRefs ?? []);
    nutrition = item?.nutrition;

    includedIngredients = (item?.includedIngredients ?? [])
        .map((e) => e is shared.IngredientReference
            ? e
            : shared.IngredientReference.fromMap(
                Map<String, dynamic>.from(e as Map)))
        .toList()
        .cast<shared.IngredientReference>();

    optionalAddOns = (item?.optionalAddOns ?? [])
        .map((e) => e is shared.IngredientReference
            ? e
            : shared.IngredientReference.fromMap(
                Map<String, dynamic>.from(e as Map)))
        .toList()
        .cast<shared.IngredientReference>();

    customizations =
        List<shared.Customization>.from(item?.customizations ?? []);
    sizeData = List<shared.SizeData>.from(item?.sizes ?? []);
    customizationGroups = (item?.customizationGroups ?? [])
        .map((g) =>
            shared.CustomizationGroup.fromMap(Map<String, dynamic>.from(g)))
        .toList();

    // All advanced fields (preserved 100%)
    notes = item?.notes;
    sku = item?.sku;
    dietaryTags = List<String>.from(item?.dietaryTags ?? []);
    allergens = List<String>.from(item?.allergens ?? []);
    prepTime = item?.prepTime;
    sortOrder = item?.sortOrder;
    taxCategory = item?.taxCategory ?? 'standard';
    exportId = item?.exportId;
    crustTypes = item?.crustTypes;
    cookTypes = item?.cookTypes;
    cutStyles = item?.cutStyles;
    sauceOptions = item?.sauceOptions;
    dressingOptions = item?.dressingOptions;
    maxFreeToppings = item?.maxFreeToppings;
    maxFreeSauces = item?.maxFreeSauces;
    maxFreeDressings = item?.maxFreeDressings;
    maxToppings = item?.maxToppings;
    customizationsUpdatedAt = item?.customizationsUpdatedAt;
    createdAt = item?.createdAt;
    comboId = item?.comboId;
    bundleItems = item?.bundleItems;
    bundleDiscount = item?.bundleDiscount;
    highlightTags = item?.highlightTags;
    allowSpecialInstructions = item?.allowSpecialInstructions;
    hideInMenu = item?.hideInMenu;
    freeSauceCount = item?.freeSauceCount;
    extraSauceUpcharge = item?.extraSauceUpcharge;
    freeDressingCount = item?.freeDressingCount;
    extraDressingUpcharge = item?.extraDressingUpcharge;
    dippingSauceOptions = item?.dippingSauceOptions;
    dippingSplits = item?.dippingSplits;
    sideDipSauceOptions = item?.sideDipSauceOptions;
    freeDipCupCount = item?.freeDipCupCount;
    sideDipUpcharge = item?.sideDipUpcharge;
    extraCharges = item?.extraCharges;
    rawCustomizations = item?.rawCustomizations;
  }

  @override
  void didUpdateWidget(MenuItemEditorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existing != oldWidget.existing ||
        widget.franchiseId != oldWidget.franchiseId) {
      _hydrateFromItem(widget.existing);
      _checkForSchemaIssues();
    }
  }

  Future<void> _loadProvidersAndCheck() async {
    if (!mounted) return;
    try {
      await Provider.of<shared.IngredientTypeProvider>(context, listen: false)
          .load(franchiseIdOverride: widget.franchiseId);
      await Provider.of<shared.IngredientMetadataProvider>(context,
              listen: false)
          .load(forceReloadFromFirestore: true);
      _checkForSchemaIssues();
    } catch (_) {}
  }

  void repairSchemaIssue(shared.MenuItemSchemaIssue issue, String newValue) {
    if (!mounted) return;
    setState(() {
      if (issue.field == 'categoryId' ||
          issue.type == shared.MenuItemSchemaIssueType.category) {
        categoryId = newValue;
      } else if (issue.field == 'price') {
        price = double.tryParse(newValue) ?? 0.0;
        _priceController.text = price.toString();
      } else if (issue.field == 'name') {
        name = newValue;
        _nameController.text = newValue;
      } else if (issue.field == 'description') {
        description = newValue;
        _descriptionController.text = newValue;
      } else {
        _repairIngredientOrType(issue, newValue);
      }
      isDirty = true;
    });
    _checkForSchemaIssues(); // single controlled call
    widget.onSchemaIssuesChanged?.call(_schemaIssues);
  }

  void _repairIngredientOrType(
      shared.MenuItemSchemaIssue issue, String newValue) {
    if (!mounted) return;
    try {
      final ingredientProvider = Provider.of<shared.IngredientMetadataProvider>(
          context,
          listen: false);
      final typeProvider =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false);

      if (issue.type == shared.MenuItemSchemaIssueType.ingredient &&
          ingredientProvider.getById(newValue) == null) {
        ingredientProvider.stageIfNew(
            id: newValue, name: issue.label ?? newValue);
      }
      if (issue.type == shared.MenuItemSchemaIssueType.ingredientType &&
          typeProvider.getById(newValue) == null) {
        typeProvider.stageIfNew(id: newValue, name: issue.label ?? newValue);
      }

      shared.IngredientReference updateEntry(shared.IngredientReference entry) {
        final missingLower = issue.missingReference.trim().toLowerCase();
        final labelLower = issue.label?.trim().toLowerCase();
        final entryIdLower = entry.id.trim().toLowerCase();
        final entryNameLower = entry.name.trim().toLowerCase();
        final matchesId = entryIdLower == missingLower;
        final matchesName = labelLower != null && entryNameLower == labelLower;

        if (issue.type == shared.MenuItemSchemaIssueType.ingredient &&
            (matchesId || matchesName)) {
          return entry.copyWith(id: newValue);
        }
        if (issue.type == shared.MenuItemSchemaIssueType.ingredientType &&
            (matchesName || entry.typeId.trim().isEmpty)) {
          return entry.copyWith(typeId: newValue);
        }
        return entry;
      }

      if (issue.field == 'includedIngredients') {
        includedIngredients = includedIngredients.map(updateEntry).toList();
      } else if (issue.field == 'optionalAddOns') {
        optionalAddOns = optionalAddOns.map(updateEntry).toList();
      } else if (issue.field.startsWith('customizationGroups')) {
        customizationGroups = customizationGroups.map((group) {
          final updated = group.ingredients.map(updateEntry).toList();
          return group.copyWith(ingredients: updated);
        }).toList();
      }
      isDirty = true;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: '_repairIngredientOrType failed',
        source: 'menu_item_editor_sheet.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'issueType': issue.type.toString(), 'newValue': newValue},
      );
    }
  }

  void _checkForSchemaIssues() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!).inMilliseconds < 300) return;
    _lastCheckTime = now;

    try {
      final categories =
          Provider.of<shared.CategoryProvider>(context, listen: false)
              .categories;
      final ingredients =
          Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
              .allIngredients;
      final ingredientTypes =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false)
              .ingredientTypes;

      final tempItem = buildMenuItemForSchemaCheck(
        existing: widget.existing,
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        outOfStock: outOfStock,
        imageUrl: imageUrl,
        customizationGroups: customizationGroups,
        includedIngredients: includedIngredients,
        optionalAddOns: optionalAddOns,
        customizations: customizations,
        nutrition: nutrition,
        selectedTemplateRefs: selectedTemplateRefs,
        sizeData: sizeData,
        categories: categories,
        notes: notes,
        sku: sku,
        dietaryTags: dietaryTags,
        allergens: allergens,
        prepTime: prepTime,
        sortOrder: sortOrder,
        taxCategory: taxCategory,
        exportId: exportId,
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

      final freshIssues = shared.MenuItemSchemaIssue.detectAllIssues(
        menuItem: tempItem,
        categories: categories,
        ingredients: ingredients,
        ingredientTypes: ingredientTypes,
      );

      setState(() {
        _schemaIssues = freshIssues;
        _showSchemaSidebar = freshIssues.any((e) => !e.resolved);
        if (_schemaIssues.isEmpty) isDirty = true; // reliable Save enable
      });

      widget.onSchemaIssuesChanged?.call(_schemaIssues);
      if (_schemaIssues.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Schema clean – ready to save'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: '_checkForSchemaIssues failed',
        source: 'menu_item_editor_sheet.dart',
        severity: 'error',
        stack: stack.toString(),
      );
    }
  }

  void _applyTemplate(shared.MenuItem item) {
    print('[MenuItemEditorSheet] _applyTemplate called');
    try {
      final allIngredients =
          Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
              .allIngredients;
      final fieldMap = extractTemplateFieldsForEditor(item, allIngredients);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _nameController.text = fieldMap['name'] ?? '';
          name = fieldMap['name'] ?? '';
          _descriptionController.text = fieldMap['description'] ?? '';
          description = fieldMap['description'] ?? '';
          _priceController.text = (fieldMap['price'] ?? 0.0).toString();
          price = fieldMap['price'] ?? 0.0;
          categoryId = fieldMap['categoryId'] ?? '';
          imageUrl = fieldMap['imageUrl'] ?? '';
          nutrition = fieldMap['nutrition'];
          includedIngredients = List<shared.IngredientReference>.from(
              fieldMap['includedIngredients'] ?? []);
          optionalAddOns = List<shared.IngredientReference>.from(
              fieldMap['optionalAddOns'] ?? []);
          customizations =
              List<shared.Customization>.from(fieldMap['customizations'] ?? []);
          sizeData = List<shared.SizeData>.from(fieldMap['sizeData'] ?? []);
          customizationGroups = List<shared.CustomizationGroup>.from(
              fieldMap['customizationGroups'] ?? []);
          selectedTemplateRefs =
              List<String>.from(fieldMap['selectedTemplateRefs'] ?? []);
          notes = fieldMap['notes'];
          sku = fieldMap['sku'];
          dietaryTags = List<String>.from(fieldMap['dietaryTags'] ?? []);
          allergens = List<String>.from(fieldMap['allergens'] ?? []);
          prepTime = fieldMap['prepTime'];
          sortOrder = fieldMap['sortOrder'];
          taxCategory = fieldMap['taxCategory'] ?? 'standard';
          exportId = fieldMap['exportId'];
          crustTypes = fieldMap['crustTypes'];
          cookTypes = fieldMap['cookTypes'];
          cutStyles = fieldMap['cutStyles'];
          sauceOptions = fieldMap['sauceOptions'];
          dressingOptions = fieldMap['dressingOptions'];
          maxFreeToppings = fieldMap['maxFreeToppings'];
          maxFreeSauces = fieldMap['maxFreeSauces'];
          maxFreeDressings = fieldMap['maxFreeDressings'];
          maxToppings = fieldMap['maxToppings'];
          customizationsUpdatedAt = fieldMap['customizationsUpdatedAt'];
          createdAt = fieldMap['createdAt'];
          comboId = fieldMap['comboId'];
          bundleItems = fieldMap['bundleItems'];
          bundleDiscount = fieldMap['bundleDiscount'];
          highlightTags = fieldMap['highlightTags'];
          allowSpecialInstructions = fieldMap['allowSpecialInstructions'];
          hideInMenu = fieldMap['hideInMenu'];
          freeSauceCount = fieldMap['freeSauceCount'];
          extraSauceUpcharge = fieldMap['extraSauceUpcharge'];
          freeDressingCount = fieldMap['freeDressingCount'];
          extraDressingUpcharge = fieldMap['extraDressingUpcharge'];
          dippingSauceOptions = fieldMap['dippingSauceOptions'];
          dippingSplits = fieldMap['dippingSplits'];
          sideDipSauceOptions = fieldMap['sideDipSauceOptions'];
          freeDipCupCount = fieldMap['freeDipCupCount'];
          sideDipUpcharge = fieldMap['sideDipUpcharge'];
          extraCharges = fieldMap['extraCharges'];
          rawCustomizations = fieldMap['rawCustomizations'];
          isDirty = true;
          _checkForSchemaIssues();
        });
        _formKey.currentState?.validate();
      });
    } catch (e, st) {
      print('[MenuItemEditorSheet] ERROR applying template: $e');
      shared.ErrorLogger.log(
        message: 'Failed to apply template',
        source: 'menu_item_editor_sheet.dart',
        severity: 'warning',
        stack: st.toString(),
      );
    }
  }

  // _applyTemplate, _saveItem, _editNutrition preserved with minor mounted guards + isDirty = true
  // (full logic from your original kept verbatim except for the improvements above)

  void _saveItem() {
    name = _nameController.text.trim();
    description = _descriptionController.text.trim();
    price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    _checkForSchemaIssues();

    if (_schemaIssues.isNotEmpty) {
      setState(() => _showSchemaSidebar = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Resolve all schema issues before saving.'),
          backgroundColor: Colors.red));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (categoryId == null || categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (sizeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one size.')));
      return;
    }

    final categories =
        Provider.of<shared.CategoryProvider>(context, listen: false).categories;
    final category = categories.firstWhere((cat) => cat.id == categoryId);
    final categoryName = category.name;

    final item = constructMenuItemFromEditorFields(
      id: widget.existing?.id ?? const Uuid().v4(),
      outOfStock: outOfStock,
      categoryName: categoryName, // required String
      categoryId: categoryId!, // required String
      name: name, // required String
      price: price,
      description: description, // required String
      notes: notes ?? '',
      sku: sku ?? '',
      dietaryTags: dietaryTags,
      allergens: allergens,
      prepTime: prepTime,
      sortOrder: sortOrder,
      taxCategory: taxCategory, // required String
      exportId: exportId ?? '',
      customizationGroups: customizationGroups,
      includedIngredients: includedIngredients,
      optionalAddOns: optionalAddOns,
      customizations: customizations,
      imageUrl: imageUrl, // required String (default '')
      nutrition: nutrition,
      selectedTemplateRefs: selectedTemplateRefs,
      sizeData: sizeData,
      crustTypes: crustTypes ?? [],
      cookTypes: cookTypes ?? [],
      cutStyles: cutStyles ?? [],
      sauceOptions: sauceOptions ?? [],
      dressingOptions: dressingOptions ?? [],
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

    widget.onSave(item);

    // Auto-save to provider
    Provider.of<shared.MenuItemProvider>(context, listen: false)
        .addOrUpdateMenuItem(item);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Menu item saved & synced'),
        backgroundColor: Colors.green));

    // Auto-exit editor after successful save (correct context for this file)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) widget.onCancel(); // Use the passed onCancel callback
    });
  }

  void _editNutrition() async {
    final result = await showDialog<shared.NutritionInfo?>(
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
    final categoryProvider =
        Provider.of<shared.CategoryProvider>(context, listen: true);
    final categories = categoryProvider.categories;

    final menuItemProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: true);
    final templates = menuItemProvider.templateRefs;
    final availableTemplates = menuItemProvider.sizeTemplates;

    final hasCategories = categories.isNotEmpty;
    final hasIngredients =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: true)
                .allIngredients
                .isNotEmpty ||
            _schemaIssues.isNotEmpty;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              (widget.existing == null
                  ? (loc.addMenuItem?.toString() ?? 'Add Menu Item')
                  : (loc.editMenuItem?.toString() ?? 'Edit Menu Item')),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          body: SafeArea(
            child: (!hasCategories || !hasIngredients) && _schemaIssues.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Categories or Ingredients',
                    message:
                        'You must create at least one category and one ingredient before adding menu items.',
                    iconData: Icons.warning_amber_rounded,
                    isAdmin: true,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Form(
                        key: _formKey,
                        onChanged: () {
                          setState(() => isDirty = true);
                          // Only re-validate on structural changes
                          if (name.isEmpty ||
                              categoryId == null ||
                              price == 0.0 ||
                              _schemaIssues.isNotEmpty) {
                            _checkForSchemaIssues();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizePricingEditor(
                              sizes: sizeData,
                              onChanged: (val) {
                                setState(() {
                                  sizeData = val;
                                  isDirty = true;
                                });
                              },
                              trailingTemplateDropdown:
                                  DropdownButton<shared.SizeTemplate>(
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
                            MultiIngredientSelector(
                              title: 'Included Ingredients',
                              selected: includedIngredients,
                              onChanged: (val) =>
                                  setState(() => includedIngredients = val),
                            ),
                            const SizedBox(height: 16),
                            MultiIngredientSelector(
                              title: 'Optional Add-ons',
                              selected: optionalAddOns,
                              onChanged: (val) =>
                                  setState(() => optionalAddOns = val),
                            ),
                            const Divider(height: 40),
                            CustomizationGroupEditor(
                              value: customizationGroups,
                              onChanged: (val) =>
                                  setState(() => customizationGroups = val),
                            ),
                            const Divider(height: 40),
                            shared.FeatureGuard(
                              module:
                                  shared.PlatformFeature.nutritionalInfo.key,
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
                            ImageUploadField(
                              initialValue: imageUrl,
                              onSaved: (val) => imageUrl = val ?? '',
                            ),
                            const Divider(height: 40),
                            ExpansionTile(
                              title: const Text('Live Preview'),
                              initiallyExpanded: false,
                              children: [
                                PreviewMenuItemCard(
                                  menuItem: buildPreviewMenuItem(
                                    existingId: widget.existing?.id,
                                    outOfStock: outOfStock,
                                    categoryId: categoryId,
                                    name: name,
                                    price: price,
                                    description: description,
                                    imageUrl: imageUrl,
                                    nutrition: nutrition,
                                    includedIngredients: includedIngredients,
                                    optionalAddOns: optionalAddOns,
                                    customizations: customizations,
                                    selectedTemplateRefs: selectedTemplateRefs,
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
                      (_schemaIssues.isEmpty || isDirty) ? _saveItem : null,
                  child: const Text('Save & Publish to Franchise'),
                )
              ],
            ),
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
