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

  @override
  void initState() {
    final item = widget.existing;
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

  void _saveItem() {
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

    final item = MenuItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      category: categoryName, // <-- must resolve from categoryId, see below
      categoryId: categoryId!,
      name: name,
      price: price,
      description: description,
      customizationGroups: customizationGroups
          .map((g) => g.toMap())
          .toList(), // Replace with actual groups if needed
      taxCategory: 'standard', // Or appropriate value
      availability: !outOfStock, // Negate outOfStock for availability
      includedIngredients: includedIngredients.map((i) => i.toMap()).toList(),
      optionalAddOns: optionalAddOns.map((i) => i.toMap()).toList(),
      customizations: customizations,
      image: imageUrl,
      nutrition: nutrition,
      templateRefs: selectedTemplateRefs, // List<String>
      sizes: sizeData,
      sizePrices: null, // deprecated or not used in your current schema
    );

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

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existing == null ? 'Add Menu Item' : 'Edit Menu Item'),
        actions: [
          TextButton(
            onPressed: isDirty ? _saveItem : null,
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
                iconData:
                    Icons.warning_amber_rounded, // Optional, for visual warning
                isAdmin: true, // Or false, depending on your use-case
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                primary: false, // 👈 this is crucial
                child: Material(
                  type: MaterialType.transparency,
                  child: Form(
                    key: _formKey,
                    onChanged: () => setState(() => isDirty = true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Basic Info
                        TextFormField(
                          initialValue: name,
                          decoration: const InputDecoration(labelText: 'Name'),
                          onChanged: (val) => name = val,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Name required'
                              : null,
                        ),
                        TextFormField(
                          initialValue: description,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          onChanged: (val) => description = val,
                          maxLines: 2,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: price.toString(),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration:
                                    const InputDecoration(labelText: 'Price'),
                                onChanged: (val) =>
                                    price = double.tryParse(val) ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: categoryId,
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
                          onChanged: (val) => setState(() => outOfStock = val),
                          title: const Text('Out of Stock'),
                        ),

                        const SizedBox(height: 20),

                        // if (availableTemplates.isEmpty)
                        //   const SizedBox.shrink()
                        // else
                        //   DropdownButtonFormField<SizeTemplate>(
                        //     value: availableTemplates.firstWhereOrNull(
                        //       (t) => const DeepCollectionEquality()
                        //           .equals(t.sizes, sizeData),
                        //     ),
                        //     decoration: const InputDecoration(
                        //       labelText: 'Size Template (optional)',
                        //     ),
                        //     items: availableTemplates
                        //         .map((template) => DropdownMenuItem(
                        //               value: template,
                        //               child: Text(template.label),
                        //             ))
                        //         .toList(),
                        //     onChanged: (template) {
                        //       if (template != null) {
                        //         setState(() {
                        //           sizeData = template.sizes;
                        //           isDirty = true;
                        //         });
                        //       }
                        //     },
                        //   ),

                        // const SizedBox(height: 10),
                        // Section 2b: Size Pricing
                        SizePricingEditor(
                          sizes: sizeData,
                          onChanged: (val) {
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

                        // Section 2: Template
                        DropdownButtonFormField<String>(
                          value: selectedTemplate,
                          decoration: const InputDecoration(
                            labelText: 'Template (optional)',
                          ),
                          items: templates
                              .map((t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(t.name),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedTemplateRefs = val != null ? [val] : [];
                              isDirty = true;
                            });
                          },
                        ),

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
                          value:
                              customizationGroups, // must be List<CustomizationGroup>
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: _editNutrition,
                                child: Text(nutrition == null
                                    ? 'Add Nutrition'
                                    : 'Edit Nutrition'),
                              ),
                              if (nutrition != null)
                                Text(
                                  '${nutrition!.calories} cal | Protein: ${nutrition!.protein}g | Fat: ${nutrition!.fat}g | Carbs: ${nutrition!.carbs}g',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),

                        const Divider(height: 40),

                        // Section 7: Image Upload
                        ImageUploadField(
                          initialValue: imageUrl,
                          onSaved: (val) => imageUrl = val ?? '',
                          validator: (val) {
                            // Optional, your image validation
                            return null;
                          },
                        ),

                        const Divider(height: 40),

                        // Preview
                        ExpansionTile(
                          title: const Text('Live Preview'),
                          initiallyExpanded: false,
                          children: [
                            PreviewMenuItemCard(
                              menuItem: MenuItem(
                                id: widget.existing?.id ?? const Uuid().v4(),
                                category: categoryId ?? '',
                                categoryId: categoryId ?? '',
                                name: name,
                                price: price,
                                description: description,
                                notes: null,
                                customizationGroups: [], // or the current groups if you have them
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
              onPressed: isDirty ? _saveItem : null,
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
