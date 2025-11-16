// web_app/lib/core/providers/ingredient_type_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

class IngredientTypeProviderImpl extends ChangeNotifier
    implements IngredientTypeProvider {
  final FirestoreService _firestoreService;
  String _franchiseId = '';
  String? _loadedFranchiseId;
  bool _loading = false;
  String? _error;
  bool _hasLoaded = false;

  List<IngredientType> _ingredientTypes = [];
  final List<IngredientType> _stagedTypes = [];
  final Set<String> _stagedForDelete = {};

  IngredientTypeProviderImpl({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  @override
  String get franchiseId => _franchiseId;
  set franchiseId(String value) {
    _franchiseId = value;
  }

  @override
  List<IngredientType> get ingredientTypes => _ingredientTypes;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  bool get isLoaded => _hasLoaded;

  @override
  List<IngredientType> get stagedTypes => List.unmodifiable(_stagedTypes);

  @override
  Set<String> get stagedForDelete => Set.unmodifiable(_stagedForDelete);

  @override
  bool get hasStagedTypeChanges => _stagedTypes.isNotEmpty;

  @override
  bool get hasStagedDeletes => _stagedForDelete.isNotEmpty;

  @override
  Future<void> load(
      {bool forceReloadFromFirestore = false,
      String? franchiseIdOverride}) async {
    final id = franchiseIdOverride ?? _franchiseId;
    if (id.isEmpty || id == 'unknown') return;

    if (_hasLoaded && !forceReloadFromFirestore && _loadedFranchiseId == id)
      return;

    await _loadIngredientTypes(id,
        forceReloadFromFirestore: forceReloadFromFirestore);
    _hasLoaded = true;
    _loadedFranchiseId = id;
  }

  @override
  Future<void> reload(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    if (forceReloadFromFirestore) _hasLoaded = false;
    await _loadIngredientTypes(franchiseId,
        forceReloadFromFirestore: forceReloadFromFirestore);
  }

  Future<void> _loadIngredientTypes(String franchiseId,
      {bool forceReloadFromFirestore = false}) async {
    _loading = true;
    notifyListeners();

    try {
      final fetched =
          await _firestoreService.fetchIngredientTypeIds(franchiseId);
      // Assuming fetchIngredientTypeIds returns List<IngredientType>
      _ingredientTypes = fetched;
    } catch (e, stack) {
      _error = e.toString();
      ErrorLogger.log(
        message: 'Failed to load ingredient types',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  List<String> missingTypeIds(List<String> ids) {
    final currentIds = allTypeIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  @override
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

  @override
  Future<void> createType(String franchiseId, IngredientType type) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestoreService.saveIngredientType(franchiseId, type);
      await reload(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create ingredient type',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> reorderIngredientTypes(
      String franchiseId, List<IngredientType> newOrder) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      final updates = newOrder
          .asMap()
          .entries
          .map((e) => {'id': e.value.id, 'sortOrder': e.key})
          .toList();
      await _firestoreService.updateIngredientTypeSortOrders(
          franchiseId: franchiseId, sortedUpdates: updates);
      await reload(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to reorder ingredient types',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
    }
  }

  @override
  IngredientType? getById(String id) {
    return _stagedTypes.firstWhereOrNull((t) => t.id == id) ??
        _ingredientTypes.firstWhereOrNull((t) => t.id == id);
  }

  @override
  Future<void> addIngredientType(
      String franchiseId, IngredientType type) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestoreService.saveIngredientType(franchiseId, type);
      await reload(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to add ingredient type',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
    }
  }

  @override
  Future<void> updateIngredientType(String franchiseId, String typeId,
      Map<String, dynamic> updatedFields) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestoreService.updateIngredientType(
          franchiseId, typeId, updatedFields);
      await reload(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update ingredient type',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
    }
  }

  @override
  Future<void> deleteIngredientType(String franchiseId, String typeId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestoreService.deleteIngredientType(franchiseId, typeId);
      _ingredientTypes.removeWhere((t) => t.id == typeId);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to delete ingredient type',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
    }
  }

  @override
  Future<bool> isIngredientTypeInUse(
      {required String franchiseId, required String typeId}) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return true;
    try {
      final query = await _firestoreService.db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata')
          .where('typeId', isEqualTo: typeId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to check ingredient type usage',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      return true;
    }
  }

  @override
  Future<String> exportTypesAsJson(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return '[]';
    try {
      final exportable = _ingredientTypes.map((t) => t.toMap()).toList();
      return const JsonEncoder.withIndent('  ').convert(exportable);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to export ingredient types as JSON',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      return '[]';
    }
  }

  @override
  Future<void> bulkReplaceIngredientTypes(
      String franchiseId, List<IngredientType> newTypes) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestoreService.replaceIngredientTypesFromJson(
          franchiseId: franchiseId, items: newTypes);
      await reload(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed bulk replace of ingredient types',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> loadTemplateIngredients(
      String templateId, String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestoreService.importIngredientMetadataTemplate(
          templateId: templateId, franchiseId: franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load template ingredients',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Map<String, String> get typeIdToName => Map.fromEntries(_ingredientTypes
      .where((t) => t.id != null)
      .map((t) => MapEntry(t.id!, t.name)));

  @override
  List<String> get allTypeIds => _ingredientTypes
      .where((t) => t.id != null && t.id!.isNotEmpty)
      .map((t) => t.id!)
      .toList();

  @override
  List<String> get allTypeNames => _ingredientTypes.map((t) => t.name).toList();

  @override
  IngredientType? getByName(String name) {
    return _ingredientTypes.firstWhereOrNull(
        (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  @override
  IngredientType? getBySystemTag(String tag) {
    return _ingredientTypes.firstWhereOrNull((t) =>
        t.systemTag != null && t.systemTag!.toLowerCase() == tag.toLowerCase());
  }

  @override
  void stageIngredientType(IngredientType type) {
    if (_stagedTypes.any((t) => t.id == type.id) ||
        _ingredientTypes.any((t) => t.id == type.id)) return;
    _stagedTypes.add(type);
    _ingredientTypes.add(type);
    notifyListeners();
  }

  @override
  Future<void> saveStagedIngredientTypes() async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      for (final type in _stagedTypes) {
        await _firestoreService.saveIngredientType(_franchiseId, type);
      }
      _stagedTypes.clear();
      await reload(_franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save staged ingredient types',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void discardStagedIngredientTypes() {
    _stagedTypes.clear();
    notifyListeners();
  }

  @override
  bool stageIfNew({required String id, required String name}) {
    if (_ingredientTypes.any((t) => t.id == id) ||
        _stagedTypes.any((t) => t.id == id)) return false;
    final staged = IngredientType(id: id, name: name, visibleInApp: true);
    _stagedTypes.add(staged);
    notifyListeners();
    return true;
  }

  @override
  void stageTypeForDelete(String id) {
    _stagedForDelete.add(id);
    notifyListeners();
  }

  @override
  void unstageTypeForDelete(String id) {
    _stagedForDelete.remove(id);
    notifyListeners();
  }

  @override
  void clearStagedDeletes() {
    _stagedForDelete.clear();
    notifyListeners();
  }

  @override
  Future<void> commitStagedDeletes(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      for (final id in _stagedForDelete) {
        await _firestoreService.deleteIngredientType(franchiseId, id);
      }
      _stagedForDelete.clear();
      await reload(franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to commit staged ingredient type deletions',
        stack: stack.toString(),
        source: 'IngredientTypeProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<List<OnboardingValidationIssue>> validate(
      {List<String>? referencedTypeIds}) async {
    final issues = <OnboardingValidationIssue>[];
    final typeNames = <String>{};

    for (final type in _ingredientTypes) {
      if (!typeNames.add(type.name.trim().toLowerCase())) {
        issues.add(OnboardingValidationIssue(
          section: 'Ingredient Types',
          itemId: type.id ?? '',
          itemDisplayName: type.name,
          severity: OnboardingIssueSeverity.critical,
          code: 'DUPLICATE_TYPE_NAME',
          message: "Duplicate ingredient type name: '${type.name}'.",
          affectedFields: ['name'],
          isBlocking: true,
          fixRoute: '/onboarding/ingredient-types',
          itemLocator: type.id,
          resolutionHint: "Change the type name to be unique.",
          actionLabel: "Fix Now",
          icon: Icons.label_important,
          detectedAt: DateTime.now(),
        ));
      }
    }

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

    return issues;
  }
}
