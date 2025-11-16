// web_app/lib/core/providers/ingredient_metadata_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:collection/collection.dart';

class IngredientMetadataProviderImpl extends ChangeNotifier
    implements IngredientMetadataProvider {
  final FirestoreService _firestore;
  final String _franchiseId;

  List<IngredientMetadata> _original = [];
  List<IngredientMetadata> _current = [];
  final List<IngredientMetadata> _stagedIngredients = [];
  final List<IngredientMetadata> _ingredients = [];
  bool _hasLoaded = false;
  String? _loadedFranchiseId;
  final Set<String> _selectedIngredientIds = {};

  String _sortKey = 'name';
  bool _ascending = true;
  String? _groupByKey = 'type';

  final Map<String, GlobalKey> itemGlobalKeys = {};
  final Map<String, GlobalKey> fieldGlobalKeys = {};

  IngredientMetadataProviderImpl({
    required FirestoreService firestoreService,
    required String franchiseId,
  })  : _firestore = firestoreService,
        _franchiseId = franchiseId;

  @override
  List<IngredientMetadata> get ingredients => _current;

  @override
  bool get isInitialized => _hasLoaded;

  @override
  bool get isDirty => !listEquals(_original, _current);

  @override
  bool get hasStagedChanges => _stagedIngredients.isNotEmpty;

  @override
  int get stagedIngredientCount => _stagedIngredients.length;

  @override
  List<IngredientMetadata> get stagedIngredients =>
      List.unmodifiable(_stagedIngredients);

  @override
  List<IngredientMetadata> get allIngredients =>
      List.unmodifiable([..._current, ..._stagedIngredients]);

  @override
  Set<String> get selectedIngredientIds =>
      Set.unmodifiable(_selectedIngredientIds);

  @override
  String get sortKey => _sortKey;

  @override
  bool get ascending => _ascending;

  @override
  String? get groupByKey => _groupByKey;

  @override
  set sortKey(String key) {
    if (key != _sortKey) {
      _sortKey = key;
      notifyListeners();
    }
  }

  @override
  set ascending(bool asc) {
    if (asc != _ascending) {
      _ascending = asc;
      notifyListeners();
    }
  }

  @override
  set groupByKey(String? key) {
    if (key != _groupByKey) {
      _groupByKey = key;
      notifyListeners();
    }
  }

  @override
  List<IngredientMetadata> get sortedIngredients {
    final sorted = List<IngredientMetadata>.from(_current);
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

  @override
  Map<String, List<IngredientMetadata>> get groupedIngredients {
    if (_groupByKey == null) return {'All': sortedIngredients};

    final groups = <String, List<IngredientMetadata>>{};
    for (final item in sortedIngredients) {
      final groupKey = _groupByKey == 'type'
          ? (item.type?.isNotEmpty == true ? item.type! : 'Unknown')
          : (item.typeId?.isNotEmpty == true ? item.typeId! : 'Unknown');
      groups.putIfAbsent(groupKey, () => []).add(item);
    }
    return groups;
  }

  @override
  Future<void> load({bool forceReloadFromFirestore = false}) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;

    if (_hasLoaded &&
        !forceReloadFromFirestore &&
        _loadedFranchiseId == _franchiseId) return;

    try {
      _current.clear();
      _original.clear();
      itemGlobalKeys.clear();

      final fetched = await _firestore.fetchIngredientMetadata(_franchiseId);
      _original = List.from(fetched);
      _current = List.from(fetched);
      _hasLoaded = true;
      _loadedFranchiseId = _franchiseId;

      for (final ing in _current) {
        itemGlobalKeys[ing.id] = GlobalKey();
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load ingredient metadata',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  @override
  Future<void> reload() async => load();

  @override
  Future<void> createIngredient(IngredientMetadata newIngredient) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.saveIngredientMetadata(_franchiseId, newIngredient);
      updateIngredient(newIngredient);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create ingredient',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void addIngredients(List<IngredientMetadata> newItems) {
    for (final item in newItems) {
      updateIngredient(item);
    }
    notifyListeners();
  }

  @override
  void addImportedIngredients(List<IngredientMetadata> imported) {
    for (final item in imported) {
      if (item.typeId?.isNotEmpty != true || item.type?.isNotEmpty != true)
        continue;
      updateIngredient(item);
    }
    notifyListeners();
  }

  @override
  List<String> missingIngredientIds(List<String> ids) {
    final currentIds = allIngredientIds.toSet();
    return ids.where((id) => !currentIds.contains(id)).toList();
  }

  @override
  void updateIngredient(IngredientMetadata newData) {
    if (newData.typeId?.isNotEmpty != true || newData.type?.isNotEmpty != true)
      return;
    final index = _current.indexWhere((e) => e.id == newData.id);
    if (index != -1) {
      _current[index] = newData;
    } else {
      _current.add(newData);
    }
    notifyListeners();
  }

  @override
  void deleteIngredient(String id) {
    _current.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  @override
  Future<void> saveChanges() async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.saveIngredientMetadataBatch(_franchiseId, _current);
      _original = List.from(_current);
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save ingredient metadata',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> saveAllChanges(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestore.saveIngredientMetadataBatch(franchiseId, _current);
      await load();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save all ingredient metadata',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void toggleSelection(String id) {
    if (_selectedIngredientIds.contains(id)) {
      _selectedIngredientIds.remove(id);
    } else {
      _selectedIngredientIds.add(id);
    }
    notifyListeners();
  }

  @override
  void clearSelection() {
    _selectedIngredientIds.clear();
    notifyListeners();
  }

  @override
  void selectAll() {
    _selectedIngredientIds.addAll(_current.map((e) => e.id));
    notifyListeners();
  }

  @override
  void deleteSelected() {
    _current.removeWhere((i) => _selectedIngredientIds.contains(i.id));
    _selectedIngredientIds.clear();
    notifyListeners();
  }

  @override
  Future<void> bulkDeleteIngredients(List<String> ids) async {
    _current.removeWhere((i) => ids.contains(i.id));
    _selectedIngredientIds.removeAll(ids);
    notifyListeners();
  }

  @override
  Future<void> bulkDeleteIngredientsFromFirestore(List<String> ids) async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    try {
      await _firestore.deleteIngredientMetadataBatch(_franchiseId, ids);
      await load();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to bulk delete ingredients',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> bulkReplaceIngredientMetadata(
      String franchiseId, List<IngredientMetadata> newItems) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      await _firestore.replaceIngredientMetadataBatch(franchiseId, newItems);
      await load();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to bulk replace ingredient metadata',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void revertChanges() {
    _current = List.from(_original);
    notifyListeners();
  }

  @override
  Map<String, String> get ingredientIdToName =>
      Map.fromEntries(allIngredients.map((i) => MapEntry(i.id, i.name)));

  @override
  List<String> get allIngredientIds =>
      allIngredients.map((i) => i.id).toSet().toList();

  @override
  List<String> get allIngredientNames =>
      ingredients.map((i) => i.name).toList();

  @override
  IngredientMetadata? getByName(String name) {
    return ingredients.firstWhereOrNull(
        (i) => i.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  @override
  IngredientMetadata? getByIdCaseInsensitive(String id) {
    return ingredients
        .firstWhereOrNull((i) => i.id.toLowerCase() == id.toLowerCase());
  }

  @override
  List<String> get allIngredientTypeIds {
    final ids = <String>{};
    for (final i in ingredients) {
      if (i.typeId?.isNotEmpty == true) ids.add(i.typeId!);
    }
    return ids.toList();
  }

  @override
  void stageIngredient(IngredientMetadata ingredient) {
    if (ingredient.typeId?.isNotEmpty != true ||
        ingredient.type?.isNotEmpty != true) return;
    if (_stagedIngredients.any((e) => e.id == ingredient.id) ||
        _ingredients.any((e) => e.id == ingredient.id) ||
        _current.any((e) => e.id == ingredient.id)) return;

    _stagedIngredients.add(ingredient);
    _ingredients.add(ingredient);
    _current.add(ingredient);
    notifyListeners();
  }

  @override
  Future<void> saveStagedIngredients() async {
    if (_franchiseId.isEmpty || _franchiseId == 'unknown') return;
    if (_stagedIngredients.isEmpty) return;

    try {
      await _firestore.saveIngredientMetadataBatch(
          _franchiseId, _stagedIngredients);
      _ingredients.addAll(_stagedIngredients);
      _stagedIngredients.clear();
      notifyListeners();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save staged ingredients',
        stack: stack.toString(),
        source: 'IngredientMetadataProviderImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  void discardStagedIngredients() {
    _stagedIngredients.clear();
    notifyListeners();
  }

  @override
  IngredientMetadata? getById(String id) {
    return _stagedIngredients.firstWhereOrNull((e) => e.id == id) ??
        _ingredients.firstWhereOrNull((e) => e.id == id);
  }

  @override
  bool stageIfNew({required String id, required String name}) {
    if (_ingredients.any((e) => e.id == id) ||
        _stagedIngredients.any((e) => e.id == id)) return false;
    final newIngredient = IngredientMetadata(
      id: id,
      name: name,
      type: '',
      allergens: [],
      removable: true,
      supportsExtra: false,
      sidesAllowed: false,
      outOfStock: false,
      amountSelectable: false,
    );
    _stagedIngredients.add(newIngredient);
    notifyListeners();
    return true;
  }

  @override
  Future<List<OnboardingValidationIssue>> validate({
    List<String>? validTypeIds,
    List<String>? referencedIngredientIds,
  }) async {
    final issues = <OnboardingValidationIssue>[];
    final names = <String>{};

    for (final ing in _current) {
      final normalized = ing.name.trim().toLowerCase();
      if (!names.add(normalized)) {
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
          resolutionHint: "Make names unique.",
          actionLabel: "Fix Now",
          icon: Icons.label_important,
          detectedAt: DateTime.now(),
        ));
      }

      if ((ing.typeId?.isEmpty ?? true) ||
          (validTypeIds != null && !validTypeIds.contains(ing.typeId))) {
        issues.add(OnboardingValidationIssue(
          section: 'Ingredients',
          itemId: ing.id,
          itemDisplayName: ing.name,
          severity: OnboardingIssueSeverity.critical,
          code: 'MISSING_INGREDIENT_TYPE',
          message: "Ingredient '${ing.name}' has no valid type.",
          affectedFields: ['typeId'],
          isBlocking: true,
          fixRoute: '/onboarding/ingredients',
          itemLocator: ing.id,
          resolutionHint: "Assign a valid type.",
          actionLabel: "Fix Now",
          icon: Icons.link_off,
          detectedAt: DateTime.now(),
        ));
      }
    }

    if (_current.isEmpty) {
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
        resolutionHint: "Add an ingredient.",
        actionLabel: "Add Ingredient",
        icon: Icons.add_box_outlined,
        detectedAt: DateTime.now(),
      ));
    }

    return issues;
  }
}
