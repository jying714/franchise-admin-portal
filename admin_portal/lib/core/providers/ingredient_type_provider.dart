import 'package:flutter/foundation.dart';
import 'package:admin_portal/core/models/ingredient_type_model.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:admin_portal/core/models/ingredient_metadata.dart';
import 'package:admin_portal/core/models/onboarding_validation_issue.dart';
import 'package:flutter/material.dart';

class IngredientTypeProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  String franchiseId = '';
  String? _loadedFranchiseId;
  bool _loading = false;
  String? _error;

  List<IngredientType> get ingredientTypes => _ingredientTypes;
  bool get loading => _loading;
  String? get error => _error;
  List<IngredientType> _ingredientTypes = [];

  /// Ingredient type staging for schema issue sidebar
  final List<IngredientType> _stagedTypes = [];
  List<IngredientType> get stagedTypes => List.unmodifiable(_stagedTypes);

  // NEW: Staged for delete (IDs only)
  final Set<String> _stagedForDelete = {};

  Set<String> get stagedForDelete => Set.unmodifiable(_stagedForDelete);

  // Tracks whether this provider has ever completed an initial load.
  bool _hasLoaded = false;
  bool get isLoaded => _hasLoaded;

  /// Uniform loader used by the review screen to avoid stale data.
  /// - If [forceReloadFromFirestore] is true, always hits Firestore.
  /// - Otherwise, it no-ops after the first successful load.
  Future<void> load(
      {bool forceReloadFromFirestore = false,
      String? franchiseIdOverride}) async {
    final id = (franchiseIdOverride ?? franchiseId);
    if (id.isEmpty || id == 'unknown') {
      debugPrint(
          '[IngredientTypeProvider][load] ⚠️ Skipping load: empty/unknown franchiseId.');
      return;
    }

    if (_hasLoaded && !forceReloadFromFirestore) {
      debugPrint(
          '[IngredientTypeProvider][load] 🔁 Using warm cache (types=${_ingredientTypes.length}).');
      return;
    }

    debugPrint(
        '[IngredientTypeProvider][load] 📡 Fetching ingredient types for franchise "$id"...');
    await loadIngredientTypes(id); // ← uses your existing method
    _hasLoaded = true;
    debugPrint(
        '[IngredientTypeProvider][load] ✅ Loaded (types=${_ingredientTypes.length}).');
  }

  /// Load all ingredient types for the given franchise
  Future<void> loadIngredientTypes(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider][LOAD] ⚠️ Called with blank/unknown franchiseId! Skipping load.');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: load called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    // Skip load if already loaded and not forcing refresh
    if (_hasLoaded &&
        _loadedFranchiseId == franchiseId &&
        !forceReloadFromFirestore) {
      print(
          '[IngredientTypeProvider][LOAD] ✅ Already loaded for "$franchiseId". Skipping fetch.');
      return;
    }

    try {
      print(
          '[IngredientTypeProvider][LOAD] 📡 Fetching ingredient types for franchise "$franchiseId"...');
      final fetched = await FirestoreService.getIngredientTypes(franchiseId);

      print(
          '[IngredientTypeProvider][LOAD] ✅ Fetched ${fetched.length} ingredient types.');
      for (final type in fetched) {
        print('    • id="${type.id}", name="${type.name}"');
      }

      _ingredientTypes
        ..clear()
        ..addAll(fetched);

      _hasLoaded = true;
      _loadedFranchiseId = franchiseId;

      notifyListeners();
    } catch (e, stack) {
      print(
          '[IngredientTypeProvider][LOAD][ERROR] ❌ Failed to load ingredient types: $e');
      await ErrorLogger.log(
        message: 'ingredient_type_load_error',
        stack: stack.toString(),
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  /// Reload ingredient types from Firestore (used after sidebar repair/add-new)
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider][RELOAD] ⚠️ Called with blank/unknown franchiseId! Skipping reload.');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: reload called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }

    if (forceReloadFromFirestore) {
      print(
          '[IngredientTypeProvider][RELOAD] 🔄 Forcing reload from Firestore for franchise "$franchiseId"...');
      _hasLoaded = false; // ensure load runs fresh
    } else {
      print(
          '[IngredientTypeProvider][RELOAD] ♻️ Reloading ingredient types for franchise "$franchiseId"...');
    }

    await loadIngredientTypes(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  /// Returns all type IDs missing from the current provider (for repair UI)
  List<String> missingTypeIds(List<String> ids) {
    final currentIds = allTypeIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  /// Adds or updates multiple ingredient types (for repair/add-new flows)
  void addOrUpdateTypes(List<IngredientType> newTypes) {
    for (final t in newTypes) {
      final idx = _ingredientTypes.indexWhere((e) => e.id == t.id);
      if (idx != -1) {
        _ingredientTypes[idx] = t;
      } else {
        _ingredientTypes.add(t);
      }
    }
    notifyListeners();
  }

  Future<void> createType(String franchiseId, IngredientType type) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] createType called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: createType called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'typeName': type.name},
      );
      return;
    }
    try {
      final colRef = _firestoreService.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types');
      await colRef.doc(type.id).set(type.toMap(includeTimestamps: true));
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to create ingredient type',
        stack: stack.toString(),
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'typeName': type.name,
          'errorType': e.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  /// Reorders ingredient types and persists updated sortOrder to Firestore
  /// Reorders ingredient types and updates their sortOrder in Firestore
  Future<void> reorderIngredientTypes(
    String franchiseId,
    List<IngredientType> newOrder,
  ) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] reorderIngredientTypes called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: reorder called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_management_screen',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    try {
      final updates = newOrder.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'sortOrder': entry.key,
        };
      }).toList();

      await _firestoreService.updateIngredientTypeSortOrders(
        franchiseId: franchiseId,
        sortedUpdates: updates,
      );

      // Reload local state after update
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to reorder ingredient types',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_management_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'newOrderIds': newOrder.map((e) => e.id).toList(),
        },
      );
    }
  }

  /// Get a specific type by ID
  /// Find an ingredient type by ID (searches both staged and loaded)
  IngredientType? getById(String id) {
    return _stagedTypes.firstWhereOrNull((t) => t.id == id) ??
        _ingredientTypes.firstWhereOrNull((t) => t.id == id);
  }

  /// Add a new ingredient type to Firestore and local list
  Future<void> addIngredientType(
      String franchiseId, IngredientType type) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print('[IngredientTypeProvider] Called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .add(type.toMap(includeTimestamps: true));
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to add ingredient type',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeName': type.name,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  /// Update an existing ingredient type
  /// Update specific fields of an existing ingredient type
  Future<void> updateIngredientType(
    String franchiseId,
    String typeId,
    Map<String, dynamic> updatedFields,
  ) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] updateIngredientType called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: update called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(typeId)
          .update({
        ...updatedFields,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update ingredient type (partial)',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeId': typeId,
          'updatedFields': updatedFields.keys.toList(),
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  Future<void> deleteIngredientType(String franchiseId, String typeId) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] deleteIngredientType called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: delete called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types')
          .doc(typeId)
          .delete();
      _ingredientTypes.removeWhere((t) => t.id == typeId);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to delete ingredient type',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeId': typeId,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  /// Check if the ingredient type is currently referenced by any ingredient_metadata
  Future<bool> isIngredientTypeInUse({
    required String franchiseId,
    required String typeId,
  }) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] isIngredientTypeInUse called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: isInUse called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'typeId': typeId},
      );
      return true; // Defensive: treat as "in use"
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata')
          .where('typeId', isEqualTo: typeId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to check ingredient type usage',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typeId': typeId,
          'errorType': e.runtimeType.toString(),
        },
      );
      return true; // Defensive: assume in-use if error
    }
  }

  Future<String> exportTypesAsJson(String franchiseId) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] exportTypesAsJson called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: exportTypesAsJson called with blank/unknown franchiseId',
        stack: '',
        source: 'IngredientTypeProvider',
        screen: 'ingredient_type_management_screen',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return '[]';
    }
    try {
      final exportable = types.map((type) => type.toMap()).toList();
      return const JsonEncoder.withIndent('  ').convert(exportable);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to export ingredient types as JSON',
        source: 'IngredientTypeProvider',
        screen: 'ingredient_type_management_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'typesLength': types.length,
        },
      );
      return '[]';
    }
  }

  Future<void> bulkReplaceIngredientTypes(
    String franchiseId,
    List<IngredientType> newTypes,
  ) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] bulkReplaceIngredientTypes called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: bulkReplace called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_json_import_export_dialog.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    try {
      final batch = _firestoreService.db.batch();
      final collectionRef = _firestoreService.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_types');

      // 1. Delete existing types
      final existingSnapshot = await collectionRef.get();
      for (final doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Add new types
      for (int i = 0; i < newTypes.length; i++) {
        final type = newTypes[i];
        final docRef = collectionRef.doc();
        batch.set(docRef, {
          ...type.toMap(includeTimestamps: true),
          'sortOrder': i,
        });
      }

      await batch.commit();
      await loadIngredientTypes(franchiseId);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed bulk replace of ingredient types',
        stack: stack.toString(),
        severity: 'error',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_json_import_export_dialog.dart',
        contextData: {
          'franchiseId': franchiseId,
          'newTypeCount': newTypes.length,
        },
      );
      rethrow;
    }
  }

  Future<void> loadTemplateIngredients(
    String templateId,
    String franchiseId,
  ) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] loadTemplateIngredients called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: loadTemplateIngredients called with blank/unknown franchiseId',
        stack: '',
        source: 'IngredientTypeProvider',
        screen: 'ingredient_metadata_template_picker_dialog',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'templateId': templateId},
      );
      return;
    }
    try {
      final firestoreService = FirestoreService();

      // 🔹 Load ingredient_metadata from template
      final List<IngredientMetadata> ingredients =
          await firestoreService.getIngredientMetadataTemplate(templateId);

      final batch = firestoreService.db.batch();
      final destRef = firestoreService.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata');

      for (final ingredient in ingredients) {
        final docRef = destRef.doc(ingredient.id);
        batch.set(docRef, ingredient.toMap());
      }

      await batch.commit();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'template_ingredient_metadata_import_failed',
        source: 'IngredientTypeProvider',
        stack: stack.toString(),
        severity: 'error',
        screen: 'ingredient_metadata_template_picker_dialog',
        contextData: {
          'franchiseId': franchiseId,
          'templateId': templateId,
        },
      );
      rethrow;
    }
  }

  // Aliased methods for UI usage compatibility
  Future<void> loadTypes(String franchiseId) =>
      loadIngredientTypes(franchiseId);
  List<IngredientType> get types => _ingredientTypes;

  Future<void> addType(String franchiseId, IngredientType type) =>
      addIngredientType(franchiseId, type);

  Future<void> updateType(String franchiseId, IngredientType type) =>
      updateIngredientType(
          franchiseId, type.id!, type.toMap(includeTimestamps: true));

  Future<void> deleteType(String franchiseId, String typeId) =>
      deleteIngredientType(franchiseId, typeId);

  /// Returns a map of all type IDs to names.
  Map<String, String> get typeIdToName => Map.fromEntries(
      types.where((t) => t.id != null).map((t) => MapEntry(t.id!, t.name)));

  /// Returns a list of all available type IDs.
  List<String> get allTypeIds => types
      .where((t) => t.id != null && t.id!.isNotEmpty)
      .map((t) => t.id!)
      .toList();

  /// Returns a list of all available type names.
  List<String> get allTypeNames => types.map((t) => t.name).toList();

  /// Find a type by name (case-insensitive, trimmed).
  IngredientType? getByName(String name) {
    return types.firstWhereOrNull(
        (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// Find a type by systemTag (case-insensitive).
  IngredientType? getBySystemTag(String tag) {
    return types.firstWhereOrNull((t) =>
        t.systemTag != null && t.systemTag!.toLowerCase() == tag.toLowerCase());
  }

  /// Methods for ingredient type in schema issue sidebar
  void stageIngredientType(IngredientType type) {
    final alreadyStaged = _stagedTypes.any((t) => t.id == type.id);
    final alreadyLoaded = _ingredientTypes.any((t) => t.id == type.id);

    debugPrint('[IngredientTypeProvider] stageIngredientType called: '
        'id=${type.id}, name=${type.name}, '
        'alreadyStaged=$alreadyStaged, alreadyLoaded=$alreadyLoaded');

    if (alreadyStaged || alreadyLoaded) {
      debugPrint('[IngredientTypeProvider] Not staging: already exists.');
      return;
    }

    _stagedTypes.add(type);
    _ingredientTypes.add(type); // Ensure visible in all lists/dropdowns

    debugPrint('[IngredientTypeProvider] Staged new ingredient type: '
        'id=${type.id}, name=${type.name}. '
        'StagedTypes=${_stagedTypes.length}, IngredientTypes=${_ingredientTypes.length}');
    notifyListeners();
  }

  Future<void> saveStagedIngredientTypes() async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] saveStagedIngredientTypes called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: saveStagedIngredientTypes called with blank/unknown franchiseId',
        stack: '',
        source: 'IngredientTypeProvider',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return;
    }
    final collectionRef = _firestoreService.db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_types');

    try {
      final batch = _firestoreService.db.batch();

      for (final type in _stagedTypes) {
        batch.set(
          collectionRef.doc(type.id),
          type.toMap(includeTimestamps: true),
        );
      }
      print('[IngredientTypeProvider] Persisting ${_stagedTypes.length} types');

      await batch.commit();
      _stagedTypes.clear();
      await loadIngredientTypes(franchiseId);
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_type_save_failed',
        stack: stack.toString(),
        source: 'IngredientTypeProvider',
        screen: 'ingredient_type_provider.dart',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  void discardStagedIngredientTypes() {
    _stagedTypes.clear();
    print('[ProviderName] Discarded staged items: '
        'count=${_stagedTypes.length} before clearing');
    notifyListeners();
  }

  bool get hasStagedTypeChanges => _stagedTypes.isNotEmpty;

  /// Adds the ingredient type to staging if it's not already present.
  /// Adds the ingredient type to staging if it's not already staged or in the main list
  bool stageIfNew({required String id, required String name}) {
    final alreadyExists = _ingredientTypes.any((t) => t.id == id) ||
        _stagedTypes.any((t) => t.id == id); // ✅ use _stagedTypes

    if (!alreadyExists) {
      final staged = IngredientType(
        id: id,
        name: name,
        visibleInApp: true,
      );
      _stagedTypes.add(staged); // ✅ use _stagedTypes
      notifyListeners();
      debugPrint('[IngredientTypeProvider] Staged new type: '
          'id=${staged.id}, name=${staged.name}');
      return true;
    }
    return false;
  }

  // Add/remove single or bulk
  void stageTypeForDelete(String id) {
    _stagedForDelete.add(id);
    notifyListeners();
  }

  void unstageTypeForDelete(String id) {
    _stagedForDelete.remove(id);
    notifyListeners();
  }

  void clearStagedDeletes() {
    _stagedForDelete.clear();
    notifyListeners();
  }

  bool get hasStagedDeletes => _stagedForDelete.isNotEmpty;

  // Commit staged deletes to Firestore
  Future<void> commitStagedDeletes(String franchiseId) async {
    // Defensive: Block blank or unknown franchise IDs
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print(
          '[IngredientTypeProvider] commitStagedDeletes called with blank/unknown franchiseId!');
      await ErrorLogger.log(
        message:
            'IngredientTypeProvider: commitStagedDeletes called with blank/unknown franchiseId',
        stack: '',
        source: 'ingredient_type_provider.dart',
        screen: 'ingredient_type_provider.dart',
        severity: 'warning',
        contextData: {
          'franchiseId': franchiseId,
          'ids': _stagedForDelete.toList()
        },
      );
      return;
    }
    try {
      final batch = _firestoreService.db.batch();
      for (final id in _stagedForDelete) {
        final docRef = _firestoreService.db
            .collection('franchises')
            .doc(franchiseId)
            .collection('ingredient_types')
            .doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
      _stagedForDelete.clear();
      await loadIngredientTypes(franchiseId);
      notifyListeners();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to commit staged ingredient type deletions',
        source: 'ingredient_type_provider.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'ids': _stagedForDelete.toList(),
        },
      );
      rethrow;
    }
  }

  Future<List<OnboardingValidationIssue>> validate({
    List<String>?
        referencedTypeIds, // Optionally pass in-use type IDs for orphan checks
  }) async {
    final issues = <OnboardingValidationIssue>[];
    try {
      final typeNames = <String>{};
      for (final type in _ingredientTypes) {
        // Uniqueness check
        if (!typeNames.add(type.name.trim().toLowerCase())) {
          issues.add(OnboardingValidationIssue(
            section: 'Ingredient Types',
            itemId: type.id ?? '',
            itemDisplayName: type.name,
            severity: OnboardingIssueSeverity.critical,
            code: 'DUPLICATE_TYPE_NAME',
            message:
                "Duplicate ingredient type name: '${type.name}'. Names must be unique.",
            affectedFields: ['name'],
            isBlocking: true,
            fixRoute: '/onboarding/ingredient-types',
            itemLocator: type.id,
            resolutionHint: "Change the type name to be unique.",
            actionLabel: "Fix Now",
            icon: Icons.label_important,
            detectedAt: DateTime.now(),
            contextData: {
              'type': type.toMap(),
            },
          ));
        }
      }

      // Required at least one type
      if (_ingredientTypes.isEmpty) {
        issues.add(OnboardingValidationIssue(
          section: 'Ingredient Types',
          itemId: '',
          itemDisplayName: '',
          severity: OnboardingIssueSeverity.critical,
          code: 'NO_INGREDIENT_TYPES',
          message: "At least one ingredient type must be defined.",
          affectedFields: ['ingredient_types'],
          isBlocking: true,
          fixRoute: '/onboarding/ingredient-types',
          resolutionHint: "Add an ingredient type before proceeding.",
          actionLabel: "Add Type",
          icon: Icons.add_box_outlined,
          detectedAt: DateTime.now(),
        ));
      }

      // (Optional) Orphan check: find types not referenced by any ingredient if referencedTypeIds provided
      if (referencedTypeIds != null) {
        for (final type in _ingredientTypes) {
          if (!referencedTypeIds.contains(type.id)) {
            issues.add(OnboardingValidationIssue(
              section: 'Ingredient Types',
              itemId: type.id ?? '',
              itemDisplayName: type.name,
              severity: OnboardingIssueSeverity.warning,
              code: 'UNUSED_TYPE',
              message: "Type '${type.name}' is not used by any ingredient.",
              affectedFields: [],
              isBlocking: false,
              fixRoute: '/onboarding/ingredient-types',
              itemLocator: type.id,
              resolutionHint: "Consider removing unused types.",
              actionLabel: "Review",
              icon: Icons.info_outline,
              detectedAt: DateTime.now(),
            ));
          }
        }
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_type_validate_failed',
        stack: stack.toString(),
        source: 'IngredientTypeProvider.validate',
        severity: 'error',
        contextData: {},
      );
    }
    return issues;
  }
}
