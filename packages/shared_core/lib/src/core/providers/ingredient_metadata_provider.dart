// packages/shared_core/lib/src/core/providers/ingredient_metadata_provider.dart
// PURE DART INTERFACE ONLY

import '../models/ingredient_metadata.dart';
import '../models/onboarding_validation_issue.dart';

abstract class IngredientMetadataProvider {
  List<IngredientMetadata> get ingredients;
  bool get isInitialized;
  bool get isDirty;
  bool get hasStagedChanges;
  int get stagedIngredientCount;
  List<IngredientMetadata> get stagedIngredients;
  List<IngredientMetadata> get allIngredients;
  Set<String> get selectedIngredientIds;

  String get sortKey;
  bool get ascending;
  String? get groupByKey;
  set sortKey(String key);
  set ascending(bool asc);
  set groupByKey(String? key);

  List<IngredientMetadata> get sortedIngredients;
  Map<String, List<IngredientMetadata>> get groupedIngredients;

  Future<void> load({bool forceReloadFromFirestore = false});
  Future<void> reload();
  Future<void> createIngredient(IngredientMetadata newIngredient);
  void addIngredients(List<IngredientMetadata> newItems);
  void addImportedIngredients(List<IngredientMetadata> imported);
  List<String> missingIngredientIds(List<String> ids);
  void updateIngredient(IngredientMetadata newData);
  void deleteIngredient(String id);
  Future<void> saveChanges();
  Future<void> saveAllChanges(String franchiseId);
  void toggleSelection(String id);
  void clearSelection();
  void selectAll();
  void deleteSelected();
  Future<void> bulkDeleteIngredients(List<String> ids);
  Future<void> bulkDeleteIngredientsFromFirestore(List<String> ids);
  Future<void> bulkReplaceIngredientMetadata(
      String franchiseId, List<IngredientMetadata> newItems);
  void revertChanges();
  Map<String, String> get ingredientIdToName;
  List<String> get allIngredientIds;
  List<String> get allIngredientNames;
  IngredientMetadata? getByName(String name);
  IngredientMetadata? getByIdCaseInsensitive(String id);
  List<String> get allIngredientTypeIds;
  void stageIngredient(IngredientMetadata ingredient);
  Future<void> saveStagedIngredients();
  void discardStagedIngredients();
  IngredientMetadata? getById(String id);
  bool stageIfNew({required String id, required String name});
  Future<List<OnboardingValidationIssue>> validate({
    List<String>? validTypeIds,
    List<String>? referencedIngredientIds,
  });
}
