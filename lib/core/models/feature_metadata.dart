// File: lib/core/models/feature_metadata.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/models/feature_module.dart';

class FeatureState {
  final Map<String, FeatureModule> modules;

  FeatureState({required this.modules});

  factory FeatureState.fromMap(Map<String, dynamic> data) {
    final parsedModules = <String, FeatureModule>{};

    for (final entry in data.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedModules[entry.key] = FeatureModule.fromMap(entry.value);
      }
    }

    return FeatureState(modules: parsedModules);
  }

  Map<String, dynamic> toMap() {
    return modules.map((key, module) => MapEntry(key, module.toMap()));
  }

  factory FeatureState.fromFirestore(DocumentSnapshot doc) {
    return FeatureState.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toFirestore() => toMap();
}
