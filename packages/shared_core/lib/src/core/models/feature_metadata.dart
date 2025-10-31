// File: lib/core/models/feature_metadata.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'feature_module.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FeatureState {
  /// Map of feature modules keyed by feature ID
  final Map<String, FeatureModule> modules;

  /// Enables the Real-Time Operational Snapshot dashboard section
  final bool liveSnapshotEnabled;

  FeatureState({
    required this.modules,
    required this.liveSnapshotEnabled,
  });

  /// Factory for creating from a Map
  factory FeatureState.fromMap(Map<String, dynamic> data) {
    try {
      final parsedModules = <String, FeatureModule>{};

      for (final entry in data.entries) {
        if (entry.value is Map<String, dynamic>) {
          parsedModules[entry.key] = FeatureModule.fromMap(entry.value);
        }
      }

      final liveSnapshotFlag = data['liveSnapshotEnabled'] ?? false;

      debugPrint(
        '[FeatureState] liveSnapshotEnabled loaded: $liveSnapshotFlag',
      );

      return FeatureState(
        modules: parsedModules,
        liveSnapshotEnabled: liveSnapshotFlag,
      );
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to parse FeatureState',
        stack: st.toString(),
        source: 'FeatureState.fromMap',
        severity: 'error',
        screen: 'feature_metadata.dart',
        contextData: {'rawData': data},
      );
      rethrow;
    }
  }

  /// Converts to Map for Firestore or local storage
  Map<String, dynamic> toMap() {
    try {
      return {
        ...modules.map((key, module) => MapEntry(key, module.toMap())),
        'liveSnapshotEnabled': liveSnapshotEnabled,
      };
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to convert FeatureState toMap',
        stack: st.toString(),
        source: 'FeatureState.toMap',
        severity: 'error',
        screen: 'feature_metadata.dart',
        contextData: {
          'moduleCount': modules.length,
          'liveSnapshotEnabled': liveSnapshotEnabled,
        },
      );
      rethrow;
    }
  }

  /// Factory for creating directly from Firestore snapshot
  factory FeatureState.fromFirestore(DocumentSnapshot doc) {
    try {
      return FeatureState.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to parse FeatureState from Firestore',
        stack: st.toString(),
        source: 'FeatureState.fromFirestore',
        severity: 'error',
        screen: 'feature_metadata.dart',
        contextData: {'docId': doc.id},
      );
      rethrow;
    }
  }

  /// Converts to Firestore format
  Map<String, dynamic> toFirestore() => toMap();
}
