import 'package:shared_core/src/core/models/ingredient_type_model.dart';
import 'package:shared_core/src/core/models/ingredient_metadata.dart';

/// One case-insensitive name collision among ingredient types.
class DuplicateIngredientTypeGroup {
  /// Normalized key (trimmed lower-case name).
  final String normalizedName;

  /// All types that share [normalizedName] (2+).
  final List<IngredientType> types;

  const DuplicateIngredientTypeGroup({
    required this.normalizedName,
    required this.types,
  });

  /// Prefer non-empty id; stable for UI keys.
  String get key =>
      types.map((t) => t.id ?? t.name).where((s) => s.isNotEmpty).join('|');
}

/// Dry-run result for merging duplicate ingredient types into one survivor.
class IngredientTypeMergePlan {
  final IngredientType survivor;
  final List<IngredientType> losers;
  final List<String> ingredientIdsToRetarget;
  final String normalizedName;

  const IngredientTypeMergePlan({
    required this.survivor,
    required this.losers,
    required this.ingredientIdsToRetarget,
    required this.normalizedName,
  });

  int get loserCount => losers.length;
  int get ingredientRetargetCount => ingredientIdsToRetarget.length;
}

/// Catalog health scanners (Decision 15). Detection only — no writes.
class CatalogHealth {
  CatalogHealth._();

  /// Groups ingredient types whose names collide case-insensitively
  /// (e.g. `sauces` and `Sauces`).
  static List<DuplicateIngredientTypeGroup> detectDuplicateIngredientTypes(
    List<IngredientType> types,
  ) {
    final byKey = <String, List<IngredientType>>{};
    for (final t in types) {
      final name = t.name.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      byKey.putIfAbsent(key, () => []).add(t);
    }

    final groups = <DuplicateIngredientTypeGroup>[];
    for (final e in byKey.entries) {
      if (e.value.length < 2) continue;
      final sorted = List<IngredientType>.from(e.value)
        ..sort((a, b) {
          final idA = a.id ?? '';
          final idB = b.id ?? '';
          final c = idA.compareTo(idB);
          if (c != 0) return c;
          return a.name.compareTo(b.name);
        });
      groups.add(DuplicateIngredientTypeGroup(
        normalizedName: e.key,
        types: sorted,
      ));
    }

    groups.sort((a, b) => a.normalizedName.compareTo(b.normalizedName));
    return groups;
  }

  /// Build a dry-run merge plan. Does not write Firestore.
  ///
  /// [survivorId] must be one of [group].types ids.
  /// Ingredients whose `typeId` matches a loser id are listed for retarget.
  /// Also matches ingredients whose `type` string equals a loser name
  /// (legacy rows without typeId).
  static IngredientTypeMergePlan? planIngredientTypeMerge({
    required DuplicateIngredientTypeGroup group,
    required String survivorId,
    required List<IngredientMetadata> ingredients,
  }) {
    final survivor = group.types.cast<IngredientType?>().firstWhere(
          (t) => t?.id == survivorId,
          orElse: () => null,
        );
    if (survivor == null || survivor.id == null || survivor.id!.isEmpty) {
      return null;
    }

    final losers =
        group.types.where((t) => t.id != null && t.id != survivor.id).toList();
    if (losers.isEmpty) return null;

    final loserIds = losers.map((t) => t.id!).toSet();
    final loserNames = losers.map((t) => t.name.trim().toLowerCase()).toSet();

    final retarget = <String>[];
    for (final ing in ingredients) {
      final tid = ing.typeId?.trim() ?? '';
      final tname = ing.type.trim().toLowerCase();
      final byId = tid.isNotEmpty && loserIds.contains(tid);
      final byName = tname.isNotEmpty && loserNames.contains(tname);
      if (byId || byName) {
        retarget.add(ing.id);
      }
    }

    return IngredientTypeMergePlan(
      survivor: survivor,
      losers: losers,
      ingredientIdsToRetarget: retarget,
      normalizedName: group.normalizedName,
    );
  }
}
