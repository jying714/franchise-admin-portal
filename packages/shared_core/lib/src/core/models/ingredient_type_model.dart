import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class IngredientType {
  final String? id;
  final String name;
  final String? description;
  final int? sortOrder;
  final String? systemTag;
  final bool visibleInApp;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  IngredientType({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder,
    this.systemTag,
    this.visibleInApp = true,
    this.createdAt,
    this.updatedAt,
  });

  factory IngredientType.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        throw StateError('Missing data for IngredientType: ${doc.id}');
      }

      return IngredientType(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'],
        sortOrder: data['sortOrder'],
        systemTag: data['systemTag'],
        visibleInApp: data['visibleInApp'] ?? true,
        createdAt: data['createdAt'],
        updatedAt: data['updatedAt'],
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to parse IngredientType from Firestore',
        source: 'ingredient_type_model.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'docId': doc.id,
          'collection': doc.reference.parent.path,
          'errorType': e.runtimeType.toString(),
          'rawData': doc.data().toString(),
        },
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'sortOrder': sortOrder,
      'systemTag': systemTag,
      'visibleInApp': visibleInApp,
    };

    if (includeTimestamps) {
      map['updatedAt'] = FieldValue.serverTimestamp();
      if (createdAt == null) {
        map['createdAt'] = FieldValue.serverTimestamp();
      }
    }

    return map;
  }

  IngredientType copyWith({
    String? id,
    String? name,
    String? description,
    int? sortOrder,
    String? systemTag,
    bool? visibleInApp,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return IngredientType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      systemTag: systemTag ?? this.systemTag,
      visibleInApp: visibleInApp ?? this.visibleInApp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static IngredientType fromMap(Map<String, dynamic> map, {String? id}) {
    try {
      return IngredientType(
        id: id,
        name: map['name'] ?? '',
        description: map['description'],
        sortOrder: map['sortOrder'],
        systemTag: map['systemTag'],
        visibleInApp: map['visibleInApp'] ?? true,
        createdAt: map['createdAt'],
        updatedAt: map['updatedAt'],
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to parse IngredientType from Map',
        source: 'ingredient_type_model.dart',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'id': id,
          'errorType': e.runtimeType.toString(),
          'rawMap': map.toString(),
        },
      );
      rethrow;
    }
  }

  @override
  String toString() {
    return 'IngredientType(id: $id, name: $name, visibleInApp: $visibleInApp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientType &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  bool matchesId(String? otherId) =>
      otherId != null &&
      id != null &&
      id!.toLowerCase() == otherId.toLowerCase();

  bool matchesName(String? otherName) =>
      otherName != null &&
      name.trim().toLowerCase() == otherName.trim().toLowerCase();

  bool matchesSystemTag(String? otherTag) =>
      otherTag != null &&
      systemTag != null &&
      systemTag!.toLowerCase() == otherTag.toLowerCase();

  static IngredientType? resolveFromReference(
    List<IngredientType> types, {
    String? id,
    String? name,
    String? systemTag,
  }) {
    final byId = types.firstWhereOrNull((t) => t.matchesId(id));
    if (byId != null) return byId;

    final byName = types.firstWhereOrNull((t) => t.matchesName(name));
    if (byName != null) return byName;

    final byTag = types.firstWhereOrNull((t) => t.matchesSystemTag(systemTag));
    return byTag;
  }

  String? get schemaWarning {
    if (id == null || id!.isEmpty || name.isEmpty) {
      return "IngredientType missing required id or name: id='$id', name='$name'";
    }
    return null;
  }

  static List<String> extractIds(List<IngredientType> types) => types
      .where((t) => t.id != null && t.id!.isNotEmpty)
      .map((t) => t.id!)
      .toList();
}
