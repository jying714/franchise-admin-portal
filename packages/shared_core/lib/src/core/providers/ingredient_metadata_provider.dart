import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/ingredient_metadata.dart';
import '../services/firestore_service_BACKUP.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/onboarding_validation_issue.dart';

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

  final Map<String, GlobalKey> itemGlobalKeys = {};
  final Map<String, GlobalKey> fieldGlobalKeys = {};
  IngredientMetadataProvider({
    required FirestoreService firestoreService,
    required this.franchiseId,
  }) : _firestore = firestoreService;

  bool get isDirty => !listEquals(_original, _current);
  List<IngredientMetadata> get ingredients {
    print('[Provider] get ingredients: ${_current.length}');
    return _current;
  }

  // ✅ Used by widgets like MultiIngredientSelector to check loading state
  bool get isInitialized => _hasLoaded;

  /// getter for staged ingredients count
  int get stagedIngredientCount => _stagedIngredients.length;
  List<IngredientMetadata> get stagedIngredients =>
      List.unmodifiable(_stagedIngredients);

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
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
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

  /// Adds a list of validated/imported ingredients to the current working set.
  /// Will update if ID exists, add if new.
  void addImportedIngredients(List<IngredientMetadata> imported) {
    int skippedTypeId = 0;
    int skippedType = 0;
    final valid = <IngredientMetadata>[];
    for (final item in imported) {
      if (item.typeId == null || item.typeId!.isEmpty) {
        print(
            '[Provider][addImportedIngredients] SKIP: id=${item.id}, name="${item.name}" - NULL/EMPTY typeId');
        skippedTypeId++;
        continue;
      }
      if (item.type == null || item.type!.isEmpty) {
        print(
            '[Provider][addImportedIngredients] SKIP: id=${item.id}, name="${item.name}" - NULL/EMPTY type');
        skippedType++;
        continue;
      }
      print(
          '[Provider][addImportedIngredients] ADD: id=${item.id}, name="${item.name}", typeId="${item.typeId}", type="${item.type}"');
      valid.add(item);
      updateIngredient(item);
    }
    if (skippedTypeId > 0 || skippedType > 0) {
      print(
          '[Provider][addImportedIngredients] --- SUMMARY: ${skippedTypeId + skippedType} SKIPPED (typeId: $skippedTypeId, type: $skippedType), ${valid.length} ADDED ---');
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
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    await load();
  }

  /// Loads ingredient metadata from Firestore and sets as original
  Future<void> load({bool forceReloadFromFirestore = false}) async {
    print(
        '\n[IngredientMetadataProvider.load] 🚀 Starting ingredient metadata load...');
    print('   ➤ franchiseId = "$franchiseId"');
    print('   ➤ _loadedFranchiseId = "${_loadedFranchiseId ?? 'null'}"');
    print(
        '   ➤ _hasLoaded = $_hasLoaded, _current.length = ${_current.length}');
    print('   ➤ forceReloadFromFirestore = $forceReloadFromFirestore');

    // 1️⃣ Defensive: Block blank or 'unknown' franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider.load] ⚠️ Called with blank/unknown franchiseId! Skipping load.');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    // 2️⃣ Skip reload if already loaded for same franchise (unless forced)
    if (!forceReloadFromFirestore &&
        _hasLoaded &&
        _loadedFranchiseId == franchiseId) {
      print(
          '[IngredientMetadataProvider.load] ⏩ Data already loaded for this franchise. Skipping fetch.');
      return;
    }

    try {
      // 3️⃣ Clear stale in-memory data
      if (_current.isNotEmpty ||
          _original.isNotEmpty ||
          itemGlobalKeys.isNotEmpty) {
        print(
            '[IngredientMetadataProvider.load] 🧹 Clearing stale in-memory ingredient data...');
        _current.clear();
        _original.clear();
        itemGlobalKeys.clear();
        print(
            '[IngredientMetadataProvider.load]    Cleared _current, _original, and itemGlobalKeys.');
      }

      // 4️⃣ Fetch from Firestore
      print(
          '[IngredientMetadataProvider.load] 📡 Fetching ingredient metadata from Firestore...');
      final fetched = await _firestore.fetchIngredientMetadata(franchiseId);

      print(
          '[IngredientMetadataProvider.load] ✅ Fetch complete: ${fetched.length} items returned.');
      if (fetched.isEmpty) {
        print(
            '[IngredientMetadataProvider.load] ⚠️ No ingredient docs found for this franchise.');
      } else {
        for (final ing in fetched) {
          print(
              '    • id="${ing.id}", name="${ing.name}", typeId="${ing.typeId}"');
        }
      }

      // 5️⃣ Replace in-memory data
      _original = List<IngredientMetadata>.from(fetched);
      _current = List<IngredientMetadata>.from(fetched);
      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;

      // 6️⃣ Refresh keys
      for (final ing in _current) {
        itemGlobalKeys[ing.id] = GlobalKey();
      }
      print(
          '[IngredientMetadataProvider.load] 🔑 Global keys set for ${itemGlobalKeys.length} items.');

      // 7️⃣ Notify listeners
      notifyListeners();
      print('[IngredientMetadataProvider.load] 🎯 Load complete. UI notified.');
    } catch (e, stack) {
      print(
          '[IngredientMetadataProvider.load][ERROR] ❌ Failed to load ingredient metadata: $e');
      ErrorLogger.log(
        message: 'ingredient_metadata_load_error',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }

    print('[IngredientMetadataProvider.load] 🏁 Finished.\n');
  }

  Future<void> loadTemplate(String templateId) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      return;
    }
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
      ErrorLogger.log(
        message: 'template_load_error',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        severity: 'error',
        contextData: {'templateId': templateId, 'franchiseId': franchiseId},
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
        if (item.type == null || item.type!.isEmpty) {
          print(
              '[Provider][groupedIngredients] item with id=${item.id} has missing or empty type!');
          groupKey = 'Unknown';
        } else {
          groupKey = item.type!;
        }
      } else if (_groupByKey == 'typeId') {
        if (item.typeId == null || item.typeId!.isEmpty) {
          print(
              '[Provider][groupedIngredients] item with id=${item.id} has missing or empty typeId!');
          groupKey = 'Unknown';
        } else {
          groupKey = item.typeId!;
        }
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
    if (newData.typeId == null || newData.typeId!.isEmpty) {
      print(
          '[Provider][updateIngredient] SKIP: id=${newData.id}, name="${newData.name}" - NULL/EMPTY typeId!');
      return;
    }
    if (newData.type == null || newData.type!.isEmpty) {
      print(
          '[Provider][updateIngredient] SKIP: id=${newData.id}, name="${newData.name}" - NULL/EMPTY type!');
      return;
    }
    print(
        '[Provider][updateIngredient] ADD/UPDATE: id=${newData.id}, name="${newData.name}", typeId="${newData.typeId}", type="${newData.type}"');
    final index = _current.indexWhere((e) => e.id == newData.id);
    if (index != -1) {
      _current[index] = newData;
      print('[Provider][updateIngredient] Updated ingredient: ${newData.id}');
    } else {
      _current.add(newData);
      print('[Provider][updateIngredient] Added ingredient: ${newData.id}');
    }
    print(
        '[Provider][updateIngredient] isDirty after update: $isDirty, _current: ${_current.length}, _original: ${_original.length}');
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
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
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
      ErrorLogger.log(
        message: 'ingredient_metadata_save_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  Future<void> saveAllChanges(String franchiseId) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
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
      // After saving, reload from Firestore to reset _original and _current
      await load(); // <<--- Add this line!
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'ingredient_metadata_save_failed',
        stack: stack.toString(),
        source: 'ingredient_metadata_provider.dart',
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
        severity: 'error',
        stack: stack.toString(),
      );
      rethrow;
    }
  }

  /// Bulk delete all selected ingredients and commit the changes to Firestore
  Future<void> bulkDeleteIngredients(List<String> ids) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'ids': ids},
      );
      return;
    }
    try {
      _current.removeWhere((ingredient) => ids.contains(ingredient.id));
      _selectedIngredientIds.removeAll(ids);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'bulk_delete_ingredients_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        severity: 'error',
        contextData: {'ids': ids, 'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  Future<void> bulkDeleteIngredientsFromFirestore(List<String> ids) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'ids': ids},
      );
      return;
    }
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
      ErrorLogger.log(
        message: 'bulk_delete_ingredients_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
        severity: 'error',
        contextData: {'deletedCount': ids.length, 'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  /// Replace the entire current ingredient metadata list locally (does NOT write to Firestore).
  /// Marks provider as dirty to enable SaveChangesBanner.
  Future<void> bulkReplaceIngredientMetadata(
    String franchiseId,
    List<IngredientMetadata> newItems,
  ) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    print(
        '[Provider] bulkReplaceIngredientMetadata (hashCode: ${this.hashCode})');
    print(
        '[Provider] bulkReplaceIngredientMetadata: replacing with ${newItems.length} items');
    int skippedTypeId = 0;
    int skippedType = 0;
    final filtered = <IngredientMetadata>[];
    for (final item in newItems) {
      if (item.typeId == null || item.typeId!.isEmpty) {
        print(
            '[Provider][bulkReplaceIngredientMetadata] SKIP: id=${item.id}, name="${item.name}" - NULL/EMPTY typeId');
        skippedTypeId++;
        continue;
      }
      if (item.type == null || item.type!.isEmpty) {
        print(
            '[Provider][bulkReplaceIngredientMetadata] SKIP: id=${item.id}, name="${item.name}" - NULL/EMPTY type');
        skippedType++;
        continue;
      }
      print(
          '[Provider][bulkReplaceIngredientMetadata] ADD: id=${item.id}, name="${item.name}", typeId="${item.typeId}", type="${item.type}"');
      filtered.add(item);
    }
    if (skippedTypeId > 0 || skippedType > 0) {
      print(
          '[Provider][bulkReplaceIngredientMetadata] --- SUMMARY: ${skippedTypeId + skippedType} SKIPPED (typeId: $skippedTypeId, type: $skippedType), ${filtered.length} ADDED ---');
    }
    _current = List.from(filtered);
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
    if (ingredient.typeId == null || ingredient.typeId!.isEmpty) {
      print(
          '[IngredientMetadataProvider][stageIngredient] SKIP: Ingredient ${ingredient.id} (${ingredient.name}) has null or empty typeId!');
      return;
    }
    if (ingredient.type == null || ingredient.type!.isEmpty) {
      print(
          '[IngredientMetadataProvider][stageIngredient] SKIP: Ingredient ${ingredient.id} (${ingredient.name}) has null or empty type!');
      return;
    }

    final alreadyStaged = _stagedIngredients.any((e) => e.id == ingredient.id);
    final alreadyInIngredients = _ingredients.any((e) => e.id == ingredient.id);
    final alreadyInCurrent = _current.any((e) => e.id == ingredient.id);

    debugPrint('[IngredientMetadataProvider] stageIngredient called: '
        'id=${ingredient.id}, name=${ingredient.name}, '
        'alreadyStaged=$alreadyStaged, alreadyInIngredients=$alreadyInIngredients, alreadyInCurrent=$alreadyInCurrent');

    if (alreadyStaged || alreadyInIngredients || alreadyInCurrent) {
      debugPrint('[IngredientMetadataProvider] Not staging: already exists.');
      return;
    }

    _stagedIngredients.add(ingredient);
    _ingredients.add(ingredient);
    _current.add(ingredient); // Ensures presence for dropdown/save

    ingredientIdToName[ingredient.id] = ingredient.name;

    debugPrint('[IngredientMetadataProvider] Staged new ingredient: '
        'id=${ingredient.id}, name=${ingredient.name}. '
        'StagedIngredients=${_stagedIngredients.length}, '
        'Ingredients=${_ingredients.length}, Current=${_current.length}');
    notifyListeners();
  }

  /// Method to commit staged ingredients (invoked in onboarding save logic):
  Future<void> saveStagedIngredients() async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientMetadataProvider] Called with blank/unknown franchiseId!');
      ErrorLogger.log(
        message:
            'IngredientMetadataProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_metadata_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
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
      print(
          '[IngredientMetadataProvider] Persisting ${_stagedIngredients.length} ingredients');

      await batch.commit();
      _ingredients.addAll(_stagedIngredients);
      _stagedIngredients.clear();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'ingredient_metadata_batch_save_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider',
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
      print('[ProviderName] Discarded staged items: '
          'count=${_stagedIngredients.length} before clearing');

      notifyListeners();
    }
  }

  /// Returns the full Ingredient by ID from staged or loaded ingredients.
  IngredientMetadata? getById(String id) {
    return _stagedIngredients.firstWhereOrNull((e) => e.id == id) ??
        _ingredients.firstWhereOrNull((e) => e.id == id);
  }

  /// Adds the ingredient to staging if it's not already present.
  bool stageIfNew({required String id, required String name}) {
    final alreadyExists = _ingredients.any((e) => e.id == id) ||
        _stagedIngredients.any((e) => e.id == id);

    if (!alreadyExists) {
      final newIngredient = IngredientMetadata(
        id: id,
        name: name,
        type: '', // default blank, since no type available
        allergens: [],
        removable: true,
        supportsExtra: false,
        sidesAllowed: false,
        outOfStock: false,
        amountSelectable: false,
      );
      _stagedIngredients.add(newIngredient);
      notifyListeners();
      debugPrint('[IngredientMetadataProvider] Staged new ingredient: '
          'id=${newIngredient.id}, name=${newIngredient.name}, '
          'typeId=${newIngredient.typeId}, type=${newIngredient.type}');

      return true;
    }
    return false;
  }

  Future<List<OnboardingValidationIssue>> validate({
    List<String>? validTypeIds,
    List<String>? referencedIngredientIds,
  }) async {
    print('\n[IngredientMetadataProvider.validate] 🔍 Starting validation...');
    print('   ➤ validTypeIds length = ${validTypeIds?.length ?? 0}');
    print(
        '   ➤ referencedIngredientIds length = ${referencedIngredientIds?.length ?? 0}');
    print('   ➤ Current in-memory ingredient count = ${_current.length}');

    final issues = <OnboardingValidationIssue>[];

    try {
      final ingredientNames = <String>{};
      for (final ing in _current) {
        print(
            '   [CHECK] Ingredient: id="${ing.id}", name="${ing.name}", typeId="${ing.typeId}"');

        // 🔹 Duplicate name check
        final normalizedName = ing.name.trim().toLowerCase();
        if (!ingredientNames.add(normalizedName)) {
          print('    ❌ Duplicate name found: "${ing.name}"');
          issues.add(OnboardingValidationIssue(
            section: 'Ingredients',
            itemId: ing.id,
            itemDisplayName: ing.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'DUPLICATE_INGREDIENT_NAME',
            message: "Duplicate ingredient name: '${ing.name}'.",
            affectedFields: ['name'],
            isBlocking: true,
            fixRoute: '/onboarding/ingredients',
            itemLocator: ing.id,
            resolutionHint: "Make all ingredient names unique.",
            actionLabel: "Fix Now",
            icon: Icons.label_important,
            detectedAt: DateTime.now(),
            contextData: {'ingredient': ing.toMap()},
          ));
        }

        // 🔹 Missing/invalid type check
        if ((ing.typeId?.isEmpty ?? true) ||
            (validTypeIds != null && !validTypeIds.contains(ing.typeId))) {
          print(
              '    ❌ Missing or invalid type for ingredient: "${ing.name}" (typeId="${ing.typeId}")');
          issues.add(OnboardingValidationIssue(
            section: 'Ingredients',
            itemId: ing.id,
            itemDisplayName: ing.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'MISSING_INGREDIENT_TYPE',
            message: "Ingredient '${ing.name}' has no valid type assigned.",
            affectedFields: ['typeId'],
            isBlocking: true,
            fixRoute: '/onboarding/ingredients',
            itemLocator: ing.id,
            resolutionHint: "Assign a valid type to this ingredient.",
            actionLabel: "Fix Now",
            icon: Icons.link_off,
            detectedAt: DateTime.now(),
            contextData: {'ingredient': ing.toMap()},
          ));
        }
      }

      // 🔹 Orphan ingredient warning
      if (referencedIngredientIds != null) {
        for (final ing in _current) {
          if (!referencedIngredientIds.contains(ing.id)) {
            print('    ⚠️ Unused ingredient: "${ing.name}"');
            issues.add(OnboardingValidationIssue(
              section: 'Ingredients',
              itemId: ing.id,
              itemDisplayName: ing.name,
              severity: OnboardingIssueSeverity.warning,
              code: 'UNUSED_INGREDIENT',
              message: "Ingredient '${ing.name}' is not used by any menu item.",
              affectedFields: [],
              isBlocking: false,
              fixRoute: '/onboarding/ingredients',
              itemLocator: ing.id,
              resolutionHint: "Consider removing unused ingredients.",
              actionLabel: "Review",
              icon: Icons.info_outline,
              detectedAt: DateTime.now(),
            ));
          }
        }
      }

      // 🔹 At least one ingredient required
      if (_current.isEmpty) {
        print('    ❌ No ingredients defined.');
        issues.add(OnboardingValidationIssue(
          section: 'Ingredients',
          itemId: '',
          itemDisplayName: '',
          severity: OnboardingIssueSeverity.critical,
          code: 'NO_INGREDIENTS_DEFINED',
          message: "At least one ingredient must be defined.",
          affectedFields: ['ingredients'],
          isBlocking: true,
          fixRoute: '/onboarding/ingredients',
          resolutionHint: "Add at least one ingredient.",
          actionLabel: "Add Ingredient",
          icon: Icons.add_box_outlined,
          detectedAt: DateTime.now(),
        ));
      }
    } catch (e, stack) {
      print('[IngredientMetadataProvider.validate][ERROR] ❌ $e');
      ErrorLogger.log(
        message: 'ingredient_metadata_validate_failed',
        stack: stack.toString(),
        source: 'IngredientMetadataProvider.validate',
        severity: 'error',
        contextData: {},
      );
    }

    print(
        '[IngredientMetadataProvider.validate] 🏁 Finished with ${issues.length} issues.\n');
    return issues;
  }
}
