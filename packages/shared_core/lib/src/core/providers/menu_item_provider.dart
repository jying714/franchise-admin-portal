// packages/shared_core/lib/src/core/providers/menu_item_provider.dart
// PURE DART INTERFACE ONLY

import '../models/menu_item.dart';
import '../models/menu_template_ref.dart';
import '../models/size_template.dart';
import '../models/onboarding_validation_issue.dart';

abstract class MenuItemProvider {
  List<MenuItem> get menuItems;
  bool get isLoading;
  bool get isDirty;
  bool get isLoaded;

  List<MenuTemplateRef> get templateRefs;
  bool get templateRefsLoading;
  String? get templateRefsError;

  List<SizeTemplate> get sizeTemplates;
  String? get selectedSizeTemplateId;

  void setSelectedSizeTemplateId(String? id);
  Future<void> load(
      {bool forceReloadFromFirestore = false, String? franchiseIdOverride});
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false});
  void addOrUpdateMenuItem(MenuItem item);
  void deleteMenuItem(String id);
  Future<void> persistChanges();
  void revertChanges();
  Future<void> reorderMenuItems(List<MenuItem> reordered);
  Future<void> loadTemplateRefs();
  Future<MenuItem?> fetchMenuItemTemplateById(
      {required String restaurantType, required String templateId});
  MenuItem applyTemplateToNewItem(MenuItem template);
  List<String> getMissingRequiredFields(MenuItem item);
  Future<List<OnboardingValidationIssue>> validate({
    required List<String> validCategoryIds,
    required List<String> validIngredientIds,
    required List<String> validTypeIds,
  });
  List<String> get allMenuItemIds;
  MenuItem? getByName(String name);
  MenuItem? getByIdCaseInsensitive(String id);
  List<String> get allReferencedCategoryIds;
  List<String> get allReferencedIngredientIds;
  List<String> get allReferencedIngredientTypeIds;
}
