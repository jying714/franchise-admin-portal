// packages/shared_core/lib/src/core/providers/ingredient_type_provider.dart
// PURE DART INTERFACE ONLY

import '../models/ingredient_type_model.dart';
import '../models/onboarding_validation_issue.dart';

abstract class IngredientTypeProvider {
  List<IngredientType> get ingredientTypes;
  bool get loading;
  String? get error;
  bool get isLoaded;
  List<IngredientType> get stagedTypes;
  Set<String> get stagedForDelete;
  bool get hasStagedTypeChanges;
  bool get hasStagedDeletes;

  Future<void> load(
      {bool forceReloadFromFirestore = false, String? franchiseIdOverride});
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false});
  List<String> missingTypeIds(List<String> ids);
  void addOrUpdateTypes(List<IngredientType> newTypes);
  Future<void> createType(String franchiseId, IngredientType type);
  Future<void> reorderIngredientTypes(
      String franchiseId, List<IngredientType> newOrder);
  IngredientType? getById(String id);
  Future<void> addIngredientType(String franchiseId, IngredientType type);
  Future<void> updateIngredientType(
      String franchiseId, String typeId, Map<String, dynamic> updatedFields);
  Future<void> deleteIngredientType(String franchiseId, String typeId);
  Future<bool> isIngredientTypeInUse(
      {required String franchiseId, required String typeId});
  Future<String> exportTypesAsJson(String franchiseId);
  Future<void> bulkReplaceIngredientTypes(
      String franchiseId, List<IngredientType> newTypes);
  Future<void> loadTemplateIngredients(String templateId, String franchiseId);
  Map<String, String> get typeIdToName;
  List<String> get allTypeIds;
  List<String> get allTypeNames;
  IngredientType? getByName(String name);
  IngredientType? getBySystemTag(String tag);
  void stageIngredientType(IngredientType type);
  Future<void> saveStagedIngredientTypes();
  void discardStagedIngredientTypes();
  bool stageIfNew({required String id, required String name});
  void stageTypeForDelete(String id);
  void unstageTypeForDelete(String id);
  void clearStagedDeletes();
  Future<void> commitStagedDeletes(String franchiseId);
  Future<List<OnboardingValidationIssue>> validate(
      {List<String>? referencedTypeIds});
}
