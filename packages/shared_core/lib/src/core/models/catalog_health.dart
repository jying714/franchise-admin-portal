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

/// Ingredient whose type link/label should be normalized to a foundation type.
class IngredientTypeLabelIssue {
  final IngredientMetadata ingredient;

  /// Matched foundation type, if any (case-insensitive on name or by typeId).
  final IngredientType? resolvedType;

  /// true when typeId is null/empty.
  final bool missingTypeId;

  /// true when typeId points at an unknown type.
  final bool unknownTypeId;

  /// true when type string ≠ resolved type name (e.g. "Sauces" vs "sauces").
  final bool labelMismatch;

  const IngredientTypeLabelIssue({
    required this.ingredient,
    required this.resolvedType,
    required this.missingTypeId,
    required this.unknownTypeId,
    required this.labelMismatch,
  });

  String get ingredientId => ingredient.id;
}

/// Dry-run: ingredients to rewrite with canonical typeId + type name.
class IngredientTypeLabelNormalizePlan {
  final List<IngredientTypeLabelIssue> issues;
  final Map<String, IngredientType> targetByIngredientId;

  const IngredientTypeLabelNormalizePlan({
    required this.issues,
    required this.targetByIngredientId,
  });

  int get count => issues.length;
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

  /// Resolve foundation type for an ingredient (by typeId, else by type name).
  static IngredientType? resolveIngredientType(
    IngredientMetadata ingredient,
    List<IngredientType> types,
  ) {
    final tid = ingredient.typeId?.trim() ?? '';
    if (tid.isNotEmpty) {
      for (final t in types) {
        if (t.id == tid) return t;
      }
    }
    final label = ingredient.type.trim().toLowerCase();
    if (label.isEmpty) return null;
    for (final t in types) {
      if (t.name.trim().toLowerCase() == label) return t;
      if ((t.id ?? '').trim().toLowerCase() == label) return t;
    }
    return null;
  }

  /// Ingredients missing typeId, unknown typeId, or type label ≠ type name.
  static List<IngredientTypeLabelIssue> detectIngredientTypeLabelIssues(
    List<IngredientMetadata> ingredients,
    List<IngredientType> types,
  ) {
    final byId = <String, IngredientType>{
      for (final t in types)
        if (t.id != null && t.id!.isNotEmpty) t.id!: t,
    };

    final issues = <IngredientTypeLabelIssue>[];
    for (final ing in ingredients) {
      final tid = ing.typeId?.trim() ?? '';
      final missingTypeId = tid.isEmpty;
      final unknownTypeId = tid.isNotEmpty && !byId.containsKey(tid);
      final resolved = resolveIngredientType(ing, types);

      var labelMismatch = false;
      if (resolved != null) {
        final canonical = resolved.name.trim();
        if (canonical.isNotEmpty && ing.type.trim() != canonical) {
          labelMismatch = true;
        }
        if (resolved.id != null &&
            resolved.id!.isNotEmpty &&
            tid != resolved.id) {
          // Missing or wrong typeId but name matched a type.
          labelMismatch = true;
        }
      }

      if (!missingTypeId && !unknownTypeId && !labelMismatch) {
        continue;
      }
      // No type string and no typeId and no resolve → still report missing.
      if (missingTypeId &&
          unknownTypeId == false &&
          resolved == null &&
          ing.type.trim().isEmpty) {
        issues.add(IngredientTypeLabelIssue(
          ingredient: ing,
          resolvedType: null,
          missingTypeId: true,
          unknownTypeId: false,
          labelMismatch: false,
        ));
        continue;
      }

      if (missingTypeId || unknownTypeId || labelMismatch) {
        issues.add(IngredientTypeLabelIssue(
          ingredient: ing,
          resolvedType: resolved,
          missingTypeId: missingTypeId,
          unknownTypeId: unknownTypeId,
          labelMismatch: labelMismatch,
        ));
      }
    }
    return issues;
  }

  /// Dry-run normalize: only issues that have a resolved foundation type.
  static IngredientTypeLabelNormalizePlan planNormalizeIngredientTypeLabels(
    List<IngredientMetadata> ingredients,
    List<IngredientType> types,
  ) {
    final issues = detectIngredientTypeLabelIssues(ingredients, types)
        .where((i) => i.resolvedType != null && i.resolvedType!.id != null)
        .toList();
    final targets = <String, IngredientType>{
      for (final i in issues) i.ingredientId: i.resolvedType!,
    };
    return IngredientTypeLabelNormalizePlan(
      issues: issues,
      targetByIngredientId: targets,
    );
  }
}
