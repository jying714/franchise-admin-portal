// packages/shared_core/lib/src/core/repositories/menu_repository.dart
//
// Bounded-context repository for menu / category / ingredient surfaces.
// Authority: docs/slices/bounded-context-repos-v1.md (Phase A1)
// Does not replace FirestoreService; call sites migrate gradually.
// Zero behavior change: signatures mirror existing FirestoreService methods.

import '../models/menu_item.dart';
import '../models/category.dart' as model;
import '../models/ingredient_metadata.dart';
import '../models/ingredient_type_model.dart';
import '../models/customization.dart';

abstract class MenuRepository {
  // --- Menu items ---
  Future<void> addMenuItem(String franchiseId, MenuItem item, {String? userId});
  Future<void> updateMenuItem(String franchiseId, MenuItem item,
      {String? userId});
  Future<void> deleteMenuItem(String franchiseId, String id, {String? userId});
  Stream<List<MenuItem>> getMenuItems(String franchiseId, {String? search});
  Future<List<MenuItem>> getMenuItemsOnce(String franchiseId);
  Stream<List<MenuItem>> getMenuItemsByIds(
      String franchiseId, List<String> ids);
  Future<List<MenuItem>> fetchMenuItemsOnce(String franchiseId);
  Future<void> saveMenuItems(String franchiseId, List<MenuItem> items);
  Future<void> reorderMenuItems(String franchiseId, List<MenuItem> ordered);
  Stream<List<MenuItem>> getMenuItemsByCategory(String categoryId,
      {String? franchiseId, String? sortBy});
  Future<MenuItem?> getMenuItemById(String itemId, {String? franchiseId});

  // --- Customization helpers (existing on FirestoreService) ---
  List<Customization> getCustomizationGroups(MenuItem item);
  List<Customization> getPreselectedCustomizations(MenuItem item);

  // --- Categories ---
  Future<List<model.Category>> fetchCategories(String franchiseId);
  Stream<List<model.Category>> getCategories(String franchiseId);
  Future<void> saveCategory(String franchiseId, model.Category category);
  Future<void> addCategory({
    required String franchiseId,
    required model.Category category,
  });
  Future<void> updateCategory(String franchiseId, model.Category category);
  Future<void> deleteCategory({
    required String franchiseId,
    required String categoryId,
  });
  Future<Map<String, dynamic>?> getCategorySchema(
      String franchiseId, String categoryId);
  Future<List<String>> getAllCategorySchemaIds(String franchiseId);

  // --- Ingredient metadata ---
  Future<List<IngredientMetadata>> getAllIngredientMetadata(String franchiseId,
      {bool forceRefresh = false});
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(
      String franchiseId, List<String> ids);
  Future<Map<String, IngredientMetadata>> getIngredientMetadataMap(
      String franchiseId,
      {bool forceRefresh = false});
  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(
      String franchiseId,
      {bool forceRefresh = false});
  Future<void> saveIngredientMetadata(
      String franchiseId, IngredientMetadata ingredient);
  Future<void> saveIngredientMetadataBatch(
      String franchiseId, List<IngredientMetadata> ingredients);
  Future<void> deleteIngredientMetadataBatch(
      String franchiseId, List<String> ids);
  Future<void> replaceIngredientMetadataBatch(
      String franchiseId, List<IngredientMetadata> newItems);
  Future<List<String>> getAllergensForIngredientIds(
      String franchiseId, List<String>? ingredientIds);
  Stream<List<IngredientMetadata>> getIngredientMetadata(String franchiseId);

  // --- Ingredient types ---
  Stream<List<IngredientType>> getIngredientTypes(String franchiseId);
  Future<void> saveIngredientType(String franchiseId, IngredientType type);
  Future<void> updateIngredientType(String franchiseId, IngredientType type);
  Future<void> deleteIngredientType(String franchiseId, String typeId);
}
