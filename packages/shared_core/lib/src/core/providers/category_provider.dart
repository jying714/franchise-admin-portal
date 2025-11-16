// packages/shared_core/lib/src/core/providers/category_provider.dart
// PURE DART INTERFACE ONLY

import '../models/category.dart';
import '../models/onboarding_validation_issue.dart';

abstract class CategoryProvider {
  List<Category> get categories;
  bool get isLoading;
  bool get isDirty;
  bool get isLoaded;
  bool get groupByVisible;
  set groupByVisible(bool val);

  Set<String> get selectedCategoryIds;
  int get stagedCategoryCount;
  List<Category> get stagedCategories;
  bool get hasStagedCategoryChanges;

  Future<void> load(
      {bool forceReloadFromFirestore = false, String? franchiseIdOverride});
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false});
  Future<void> createCategory(Category newCategory);
  void addOrUpdateCategories(List<Category> newCategories);
  List<String> missingCategoryIds(List<String> ids);
  Future<void> saveCategories();
  void addOrUpdateCategory(Category category);
  Future<void> deleteCategory(String categoryId);
  Future<void> bulkDeleteCategoriesFromFirestore(List<String> ids);
  void reorderCategories(int oldIndex, int newIndex);
  void toggleSelection(String categoryId);
  void clearSelection();
  void deleteSelected();
  void revertChanges();
  void updateFranchiseId(String newId);
  Future<void> bulkImportCategories(List<Category> imported);
  String exportAsJson();
  Category? getCategoryById(String id);
  Future<void> loadTemplate(String templateId);
  Map<String, String> get categoryIdToName;
  List<String> get allCategoryIds;
  List<String> get allCategoryNames;
  Category? getByName(String name);
  Category? getByIdCaseInsensitive(String id);
  void stageCategory(Category category);
  Future<void> saveStagedCategories();
  void discardStagedCategories();
  bool stageIfNew({required String id, required String name});
  Future<List<OnboardingValidationIssue>> validate(
      {List<String>? referencedCategoryIds});
}
