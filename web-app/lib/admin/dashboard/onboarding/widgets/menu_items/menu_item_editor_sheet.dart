import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/size_pricing_editor.dart';
import 'package:shared_core/shared_core.dart' as shared; // Phase 3 scoped fix
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

class MenuItemEditorSheet extends StatefulWidget {
  final shared.MenuItem? existing;
  final void Function(shared.MenuItem item) onSave;
  final VoidCallback onCancel;
  final void Function(List<shared.MenuItemSchemaIssue> issues)?
      onSchemaIssuesChanged;
  final FirebaseFirestore firestore;
  final String franchiseId;

  const MenuItemEditorSheet({
    Key? key,
    this.existing,
    required this.onCancel,
    required this.onSave,
    required this.onSchemaIssuesChanged,
    required this.firestore,
    required this.franchiseId,
  }) : super(key: key);

  @override
  State<MenuItemEditorSheet> createState() => MenuItemEditorSheetState();
}

class MenuItemEditorSheetState extends State<MenuItemEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  List<shared.CustomizationGroup> customizationGroups = [];
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String description;
  late double price;
  String? categoryId;
  bool outOfStock = false;
  String imageUrl = '';
  List<String> selectedTemplateRefs = [];
  shared.NutritionInfo? nutrition;
  List<shared.IngredientReference> includedIngredients = [];
  List<shared.IngredientReference> optionalAddOns = [];
  List<shared.Customization> customizations = [];
  List<shared.SizeData> sizeData = [];
  String? get selectedTemplate =>
      selectedTemplateRefs.isNotEmpty ? selectedTemplateRefs.first : null;

  bool isDirty = false;
  List<shared.MenuItem> availableTemplates = [];
  bool loadingTemplates = true;
  List<shared.MenuItemSchemaIssue> _schemaIssues = [];
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

    // === CRITICAL FIX: Safe deserialization from raw Firestore/template maps ===
    includedIngredients = (item?.includedIngredients ?? [])
        .map((dynamic e) => e is shared.IngredientReference
            ? e
            : shared.IngredientReference.fromMap(
                Map<String, dynamic>.from(e as Map)))
        .toList();

    optionalAddOns = (item?.optionalAddOns ?? [])
        .map((dynamic e) => e is shared.IngredientReference
            ? e
            : shared.IngredientReference.fromMap(
                Map<String, dynamic>.from(e as Map)))
        .toList();

    customizations =
        List<shared.Customization>.from(item?.customizations ?? []);
    sizeData = List<shared.SizeData>.from(item?.sizes ?? []);

    customizationGroups = (item?.customizationGroups != null)
        ? (item!.customizationGroups as List)
            .map((g) =>
                shared.CustomizationGroup.fromMap(Map<String, dynamic>.from(g)))
            .toList()
        : [];

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);

      // FranchiseProvider does not expose currentFranchise — use franchiseId + adminUser context
      if (franchiseProvider.isFranchiseSelected) {
        await Provider.of<shared.MenuItemProvider>(context, listen: false)
            .loadTemplateRefs();
      }

      await Provider.of<shared.IngredientTypeProvider>(context, listen: false)
          .load(franchiseIdOverride: widget.franchiseId);
      _checkForSchemaIssues();
    });
  }

  List<shared.MenuItemSchemaIssue> validateMenuItem({
    required BuildContext context,
    required String menuItemId,
  }) {
    if (!mounted) {
      shared.ErrorLogger.log(
        message: 'validateMenuItem called on unmounted widget',
        source: 'menu_item_editor_sheet.dart',
        severity: 'warning',
        contextData: {'menuItemId': menuItemId},
      );
      return [];
    }

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

      final menuItem = constructMenuItemFromEditorFields(
        id: menuItemId,
        outOfStock: outOfStock,
        categoryName: categoryId ?? '',
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
        customizationGroups: customizationGroups,
        includedIngredients: includedIngredients,
        optionalAddOns: optionalAddOns,
        customizations: customizations,
        imageUrl: imageUrl,
        nutrition: nutrition,
        selectedTemplateRefs: selectedTemplateRefs,
        sizeData: sizeData,
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

      return shared.MenuItemSchemaIssue.detectAllIssues(
        menuItem: menuItem,
        categories: categories,
        ingredients: ingredients,
        ingredientTypes: ingredientTypes,
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'validateMenuItem failed',
        source: 'menu_item_editor_sheet.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'menuItemId': menuItemId,
          'name': name,
          'franchiseId': widget.franchiseId,
        },
      );
      return [];
    }
  }

  void repairSchemaIssue(shared.MenuItemSchemaIssue issue, String newValue) {
    if (!mounted) return;

    print('[repairSchemaIssue] Resolving: ${issue.displayMessage} → $newValue');

    try {
      // Apply the repair
      final ingredientProvider = Provider.of<shared.IngredientMetadataProvider>(
          context,
          listen: false);
      final typeProvider =
          Provider.of<shared.IngredientTypeProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<shared.CategoryProvider>(context, listen: false);

      setState(() {
        switch (issue.field) {
          case 'categoryId':
            categoryId = newValue;
            break;
          case 'price':
            price = double.tryParse(newValue) ?? 0.0;
            _priceController.text = price.toString();
            break;
          case 'description':
            description = newValue;
            _descriptionController.text = newValue;
            break;
          case 'includedIngredients':
          case 'optionalAddOns':
          case 'customizationGroups':
          case 'customizationGroups.options':
            _repairIngredientOrType(issue, newValue);
            break;
          default:
            print('[WARNING] Unhandled repair field: ${issue.field}');
        }
      });

      // Immediate + delayed revalidation to ensure UI sync
      _checkForSchemaIssues();
      widget.onSchemaIssuesChanged?.call(_schemaIssues);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _checkForSchemaIssues();
        widget.onSchemaIssuesChanged?.call(_schemaIssues);
        setState(() {
          _showSchemaSidebar = _schemaIssues.any((e) => !e.resolved);
        });
      });
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'repairSchemaIssue failed',
        source: 'menu_item_editor_sheet.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'issue': issue.toString(), 'newValue': newValue},
      );
    }
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

      final ingredientExists = ingredientProvider.getById(newValue) != null;
      final typeExists = typeProvider.getById(newValue) != null;

      print(
          '[DEBUG] Lookup results: ingredientExists=$ingredientExists, typeExists=$typeExists, issueType=${issue.type}');

      // Stage missing references
      if (issue.type == shared.MenuItemSchemaIssueType.ingredient &&
          !ingredientExists) {
        final stagedName = issue.label ?? newValue;
        final staged =
            ingredientProvider.stageIfNew(id: newValue, name: stagedName);
        print('[DEBUG] Staged ingredient: $staged');
      }

      if (issue.type == shared.MenuItemSchemaIssueType.ingredientType &&
          !typeExists) {
        final stagedName = issue.label ?? newValue;
        final staged = typeProvider.stageIfNew(id: newValue, name: stagedName);
        print('[DEBUG] Staged ingredient type: $staged');
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
    if (!mounted) {
      shared.ErrorLogger.log(
        message: '_checkForSchemaIssues called on unmounted widget',
        source: 'menu_item_editor_sheet.dart',
        severity: 'warning',
      );
      return;
    }

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

      // Preserve resolved state
      final updatedIssues = <shared.MenuItemSchemaIssue>[];
      for (final newIssue in freshIssues) {
        final existing = _schemaIssues.firstWhere(
          (e) =>
              e.type == newIssue.type &&
              e.missingReference == newIssue.missingReference &&
              e.field == newIssue.field &&
              e.context == newIssue.context,
          orElse: () => newIssue,
        );
        final resolved = existing.resolved;
        updatedIssues.add(resolved ? newIssue.markResolved(true) : newIssue);
      }

      // Add any new issues
      for (final newIssue in freshIssues) {
        if (!updatedIssues.any((i) =>
            i.type == newIssue.type &&
            i.missingReference == newIssue.missingReference &&
            i.field == newIssue.field &&
            i.context == newIssue.context)) {
          updatedIssues.add(newIssue);
        }
      }

      setState(() {
        _schemaIssues = updatedIssues;
        _showSchemaSidebar = updatedIssues.any((e) => !e.resolved);
      });

      widget.onSchemaIssuesChanged?.call(_schemaIssues);
      // Force sidebar update
      if (_schemaIssues.any((e) => !e.resolved)) {
        setState(() => _showSchemaSidebar = true);
      }

      widget.onSchemaIssuesChanged?.call(_schemaIssues);
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
    print('[MenuItemEditorSheet] _applyTemplate called with item: '
        'id=${item.id}, name=${item.name}, categoryId=${item.categoryId}, '
        'customizationGroups=${item.customizationGroups?.length ?? 0}');
    print('[MenuItemEditorSheet] Template data dump: ${item.toJson()}');
    try {
      final allIngredients =
          Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
              .allIngredients;
      final fieldMap = extractTemplateFieldsForEditor(item, allIngredients);

      // DEFER ALL STATE UPDATES TO NEXT FRAME!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // --- Update controllers for user-editable fields ---
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
          print(
              '[MenuItemEditorSheet] Template applied. Triggered schema re-check.');
          _checkForSchemaIssues();
        });

        _formKey.currentState?.validate();
      });
    } catch (e, st) {
      print('[MenuItemEditorSheet] ERROR applying template: $e\n$st');
      shared.ErrorLogger.log(
        message: 'Failed to apply template into editor state',
        source: 'menu_item_editor_sheet.dart',
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
    _schemaIssues.removeWhere((issue) => issue.resolved);
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
    final categories =
        Provider.of<shared.CategoryProvider>(context, listen: false).categories;
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
    final item = constructMenuItemFromEditorFields(
      id: widget.existing?.id ?? const Uuid().v4(),
      outOfStock: outOfStock,
      categoryName: categoryName,
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
      customizationGroups: customizationGroups,
      includedIngredients: includedIngredients,
      optionalAddOns: optionalAddOns,
      customizations: customizations,
      imageUrl: imageUrl,
      nutrition: nutrition,
      selectedTemplateRefs: selectedTemplateRefs,
      sizeData: sizeData,
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
    // === SAFE PROVIDER ACCESS (avoids ProviderNotFound in modal context) ===
    final categoryProvider =
        Provider.of<shared.CategoryProvider>(context, listen: true);
    final categories = categoryProvider.categories;

    final menuItemProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: true);
    final templates = menuItemProvider.templateRefs;
    final availableTemplates = menuItemProvider.sizeTemplates;

    final hasCategories = categories.isNotEmpty;
    final hasIngredients =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false)
            .allIngredients
            .isNotEmpty;

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
              '${widget.existing == null ? loc.addMenuItem : loc.editMenuItem}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              // Optional save button logic can be re-enabled here
              // TextButton(
              //   onPressed: (!(_showSchemaSidebar && _schemaIssues.isNotEmpty) &&
              //           (_schemaIssues.isEmpty || isDirty))
              //       ? _saveItem
              //       : null,
              //   child: Text(
              //     loc.save,
              //     style: TextStyle(color: colorScheme.primary),
              //   ),
              // ),
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
                        onChanged: () {
                          setState(() => isDirty = true);
                          _checkForSchemaIssues(); // Live validation — shows sidebar immediately
                        },
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

                            // Section 7: Image Upload
                            ImageUploadField(
                              initialValue: imageUrl,
                              onSaved: (val) => imageUrl = val ?? '',
                            ),

                            const Divider(height: 40),

                            // Preview Section
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
