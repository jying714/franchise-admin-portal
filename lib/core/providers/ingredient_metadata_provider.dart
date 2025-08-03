import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/ingredient_metadata.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientMetadataProvider extends ChangeNotifier {
  final FirestoreService _firestore;
  final String franchiseId;

  List<IngredientMetadata> _original = [];
  List<IngredientMetadata> _current = [];
  final List<IngredientMetadata> _stagedIngredients = [];
  final List<IngredientMetadata> _ingredients = [];
  bool _hasLoaded = false;
  String? _loadedFranchiseId;
  bool get hasStagedChanges => _stagedIngredients.isNotEmpty;
  final Set<String> _selectedIngredientIds = {};

  Set<String> get selectedIngredientIds =>
      Set.unmodifiable(_selectedIngredientIds);

  // --- New state for sorting and grouping ---
  String _sortKey = 'name'; // 'name', 'type', 'notes', etc.
  bool _ascending = true;
  String? _groupByKey = 'type'; // 'type', 'typeId', or null for no grouping

  IngredientMetadataProvider({
    required FirestoreService firestoreService,
    required this.franchiseId,
  }) : _firestore = firestoreService;

  bool get isDirty => !listEquals(_original, _current);
  List<IngredientMetadata> get ingredients => _current;

  // ✅ Used by widgets like MultiIngredientSelector to check loading state
  bool get isInitialized => _hasLoaded;

  // ✅ Exposes all current ingredients as read-only
  List<IngredientMetadata> get allIngredients => List.unmodifiable([
        ..._current,
        ..._stagedIngredients,
      ]);

  String get sortKey => _sortKey;
  bool get ascending => _ascending;
  String? get groupByKey => _groupByKey;

  set sortKey(String key) {
    if (key != _sortKey) {
      _sortKey = key;
      notifyListeners();
    }
  }

  set ascending(bool asc) {
    if (asc != _ascending) {
      _ascending = asc;
      notifyListeners();
    }
  }

  set groupByKey(String? key) {
    if (key != _groupByKey) {
      _groupByKey = key;
      notifyListeners();
    }
  }

  Future<void> createIngredient(IngredientMetadata newIngredient) async {
    final colRef = _firestore.db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_metadata');
    await colRef.doc(newIngredient.id).set(newIngredient.toMap());
    updateIngredient(newIngredient);
  }

  /// Adds multiple new ingredients (e.g. after mapping or create-new from sidebar)
  void addIngredients(List<IngredientMetadata> newItems) {
    for (final item in newItems) {
      updateIngredient(item);
    }
    notifyListeners();
  }

  /// Returns all ingredient IDs missing from the current provider (for repair UI)
  List<String> missingIngredientIds(List<String> ids) {
    final currentIds = allIngredientIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  /// Reloads ingredients from Firestore (useful after repair or add-new)
  Future<void> reload() async {
    await load();
  }

  /// Loads ingredient metadata from Firestore and sets as original
  Future<void> load() async {
    // Remove the early return to always fetch fresh data
    try {
      _original = await _firestore.fetchIngredientMetadata(franchiseId);
      _current = List.from(_original);
      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_metadata_load_error',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  Future<void> loadTemplate(String templateId) async {
    try {
      final snapshot = await _firestore.db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('ingredient_metadata')
          .get();

      final newItems = snapshot.docs
          .map((doc) => IngredientMetadata.fromMap(doc.data()))
          .toList();

      for (final item in newItems) {
        updateIngredient(item); // Adds to _current, marks dirty
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'template_load_error',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        contextData: {'templateId': templateId},
      );
      rethrow;
    }
  }

  // -- Sorting method --
  List<IngredientMetadata> get sortedIngredients {
    List<IngredientMetadata> sorted = List.from(_current);
    sorted.sort((a, b) {
      final aVal = _getSortValue(a, _sortKey);
      final bVal = _getSortValue(b, _sortKey);
      return _ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
    return sorted;
  }

  String _getSortValue(IngredientMetadata item, String key) {
    switch (key) {
      case 'name':
        return item.name.toLowerCase();
      case 'type':
        return (item.type ?? '').toLowerCase();
      case 'notes':
        return (item.notes ?? '').toLowerCase();
      default:
        return '';
    }
  }

  // -- Grouping method --
  Map<String, List<IngredientMetadata>> get groupedIngredients {
    if (_groupByKey == null) {
      return {'All': sortedIngredients};
    }

    final groups = <String, List<IngredientMetadata>>{};
    for (final item in sortedIngredients) {
      String groupKey;
      if (_groupByKey == 'type') {
        groupKey = item.type ?? 'Unknown';
      } else if (_groupByKey == 'typeId') {
        groupKey = item.typeId ?? 'Unknown';
      } else {
        groupKey = 'Unknown';
      }
      groups.putIfAbsent(groupKey, () => []).add(item);
    }
    return groups;
  }

  /// Inject a full list of ingredients (e.g. from template)
  void setIngredients(List<IngredientMetadata> items) {
    _current = List.from(items);
    notifyListeners();
  }

  /// Add or update a single ingredient
  void updateIngredient(IngredientMetadata newData) {
    final index = _current.indexWhere((e) => e.id == newData.id);
    if (index != -1) {
      _current[index] = newData;
    } else {
      _current.add(newData);
    }
    notifyListeners();
  }

  /// Delete by ID
  void deleteIngredient(String id) {
    _current.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Get by ID (for editing)
  IngredientMetadata? getIngredientById(String id) {
    return _current.firstWhereOrNull((e) => e.id == id);
  }

  /// Push all current data to Firestore (overwrites existing)
  Future<void> saveChanges() async {
    try {
      final batch = _firestore.db.batch();
      final colRef = _firestore.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata');

      for (final item in _current) {
        batch.set(colRef.doc(item.id), item.toMap());
      }

      await batch.commit();
      _original = List.from(_current);
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_metadata_save_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  Future<void> saveAllChanges(String franchiseId) async {
    final batch = FirebaseFirestore.instance.batch();
    final collectionRef = FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_metadata');

    try {
      for (final entry in _current) {
        if (!entry.isValid()) {
          throw Exception('Invalid ingredient: ${entry.name}');
        }
        final docRef = collectionRef.doc(entry.id);
        batch.set(docRef, entry.toMap());
      }

      await batch.commit();
      _original = List.from(_current);
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_metadata_save_failed',
        stack: stack.toString(),
        source: 'ingredient_metadata_provider',
        screen: 'onboarding_ingredients_screen',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'ingredientCount': _current.length,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// BULK DELETE METHODS
  /// Toggle selection state for an ingredient by ID
  void toggleSelection(String id) {
    try {
      if (_selectedIngredientIds.contains(id)) {
        _selectedIngredientIds.remove(id);
      } else {
        _selectedIngredientIds.add(id);
      }
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'toggleSelection failed',
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'id': id},
      );
      rethrow;
    }
  }

  /// Clear all selected ingredient IDs
  void clearSelection() {
    try {
      _selectedIngredientIds.clear();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'clearSelection failed',
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        stack: stack.toString(),
      );
      rethrow;
    }
  }

  /// Select all loaded ingredients
  void selectAll() {
    try {
      _selectedIngredientIds.clear();
      _selectedIngredientIds.addAll(_current.map((e) => e.id));
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'selectAll failed',
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        stack: stack.toString(),
      );
      rethrow;
    }
  }

  /// Bulk delete all selected ingredients locally (does NOT commit to Firestore)
  void deleteSelected() {
    try {
      _current.removeWhere(
          (ingredient) => _selectedIngredientIds.contains(ingredient.id));
      _selectedIngredientIds.clear();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'deleteSelected failed',
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        stack: stack.toString(),
      );
      rethrow;
    }
  }

  /// Bulk delete all selected ingredients and commit the changes to Firestore
  Future<void> bulkDeleteIngredients(List<String> ids) async {
    try {
      _current.removeWhere((ingredient) => ids.contains(ingredient.id));
      _selectedIngredientIds.removeAll(ids);
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'bulk_delete_ingredients_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        contextData: {'ids': ids},
      );
      rethrow;
    }
  }

  Future<void> bulkDeleteIngredientsFromFirestore(List<String> ids) async {
    try {
      final batch = _firestore.db.batch();
      final colRef = _firestore.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata');

      for (final id in ids) {
        batch.delete(colRef.doc(id));
      }

      await batch.commit();

      // After deletion, reload the ingredients
      await load();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'bulk_delete_ingredients_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        contextData: {'deletedCount': ids.length},
      );
      rethrow;
    }
  }

  /// Replace the entire current ingredient metadata list locally (does NOT write to Firestore).
  /// Marks provider as dirty to enable SaveChangesBanner.
  Future<void> bulkReplaceIngredientMetadata(
      String franchiseId, List<IngredientMetadata> newItems) async {
    _current = List.from(newItems);
    notifyListeners();
  }

  /// Revert to original snapshot
  void revertChanges() {
    _current = List.from(_original);
    notifyListeners();
  }

  /// Returns a map of all ingredient IDs to names.
  Map<String, String> get ingredientIdToName => Map.fromEntries(
      [..._current, ..._stagedIngredients].map((i) => MapEntry(i.id, i.name)));

  /// Returns a list of all available ingredient IDs.
  List<String> get allIngredientIds =>
      [..._current, ..._stagedIngredients].map((i) => i.id).toSet().toList();

  /// Returns a list of all available ingredient names.
  List<String> get allIngredientNames =>
      ingredients.map((i) => i.name).toList();

  /// Find an ingredient by name (case-insensitive, trimmed).
  IngredientMetadata? getByName(String name) {
    return ingredients.firstWhereOrNull(
        (i) => i.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// Find an ingredient by ID (case-insensitive).
  IngredientMetadata? getByIdCaseInsensitive(String id) {
    return ingredients
        .firstWhereOrNull((i) => i.id.toLowerCase() == id.toLowerCase());
  }

  /// Find all unique typeIds in the current ingredient set.
  List<String> get allIngredientTypeIds {
    final ids = <String>{};
    for (final i in ingredients) {
      if (i.typeId != null && i.typeId!.isNotEmpty) {
        ids.add(i.typeId!);
      }
    }
    return ids.toList();
  }

  /// Method to stage a new ingredient for schema issue sidebar to be added
  void stageIngredient(IngredientMetadata ingredient) {
    _stagedIngredients.add(ingredient);
    _ingredients.add(ingredient);
    ingredientIdToName[ingredient.id] = ingredient.name;
    notifyListeners();
  }

  /// Method to commit staged ingredients (invoked in onboarding save logic):
  Future<void> saveStagedIngredients() async {
    if (_stagedIngredients.isEmpty) return;

    try {
      final batch = _firestore.db.batch();
      final colRef = _firestore.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata');

      for (final ingredient in _stagedIngredients) {
        batch.set(colRef.doc(ingredient.id), ingredient.toMap());
      }

      await batch.commit();
      _ingredients.addAll(_stagedIngredients);
      _stagedIngredients.clear();
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_metadata_batch_save_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        screen: 'ingredient_metadata_provider.dart',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'stagedCount': _stagedIngredients.length,
          'stagedIds': _stagedIngredients.map((e) => e.id).toList(),
        },
      );
      rethrow;
    }
  }

  /// Optional method to revert staged ingredients:
  void discardStagedIngredients() {
    if (_stagedIngredients.isNotEmpty) {
      _stagedIngredients.clear();
      notifyListeners();
    }
  }
}
