import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/core/models/alert_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';

class AlertsRepository {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;
  final AppConfig? _appConfig;

  AlertsRepository({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
    AppConfig? appConfig,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService(),
        _appConfig = appConfig;

  /// Stream all active alerts for the given franchise/location.
  Stream<List<AlertModel>> watchActiveAlerts({
    required String franchiseId,
    String? locationId,
    bool developerMode = false,
  }) {
    Query query = _firestore.collection('alerts');
    query = query
        .where('franchiseId.path', isEqualTo: 'franchises/$franchiseId')
        .where('dismissed_at', isNull: true);

    if (locationId != null) {
      query = query.where('locationId.path',
          isEqualTo: 'franchise_locations/$locationId');
    }

    // Hide developer/test alerts if not in dev mode
    if (!developerMode) {
      query = query.where('type', isNotEqualTo: 'developer');
    }

    return query.orderBy('created_at', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs.map(AlertModel.fromFirestore).toList();
      },
    );
  }

  /// Fetch all alert history for the given franchise/location.
  Future<List<AlertModel>> fetchAllAlerts({
    required String franchiseId,
    String? locationId,
    bool includeDismissed = true,
    bool developerMode = false,
    String? userId,
  }) async {
    try {
      Query query = _firestore.collection('alerts');
      query =
          query.where('franchiseId.path', isEqualTo: 'franchises/$franchiseId');
      if (locationId != null) {
        query = query.where('locationId.path',
            isEqualTo: 'franchise_locations/$locationId');
      }
      if (!includeDismissed) {
        query = query.where('dismissed_at', isNull: true);
      }
      if (!developerMode) {
        query = query.where('type', isNotEqualTo: 'developer');
      }
      final snapshot =
          await query.orderBy('created_at', descending: true).get();
      return snapshot.docs.map(AlertModel.fromFirestore).toList();
    } catch (e, stack) {
      await _firestoreService.logError(
        franchiseId,
        message: 'Failed to fetch all alerts: $e',
        source: 'alerts_repository_fetchAllAlerts',
        stackTrace: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'locationId': locationId,
        },
        userId: userId,
        screen: 'AlertsRepository',
        errorType: e.runtimeType.toString(),
        severity: 'error',
      );
      return [];
    }
  }

  /// Dismiss an alert (mark as dismissed for all users).
  Future<void> dismissAlert(
    String franchiseId,
    String alertId,
    String userId, {
    String? screen,
  }) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({
        'dismissed_at': FieldValue.serverTimestamp(),
        'seen_by': FieldValue.arrayUnion([userId]),
      });
    } catch (e, stack) {
      await _firestoreService.logError(
        franchiseId,
        message: 'Failed to dismiss alert: $e',
        source: 'alerts_repository_dismissAlert',
        stackTrace: stack.toString(),
        contextData: {
          'alertId': alertId,
          'userId': userId,
        },
        userId: userId,
        screen: screen ?? 'AlertsRepository',
        errorType: e.runtimeType.toString(),
        severity: 'error',
      );
    }
  }

  /// Mark alert as seen by this user.
  Future<void> markAlertSeen(
    String franchiseId,
    String alertId,
    String userId, {
    String? screen,
  }) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({
        'seen_by': FieldValue.arrayUnion([userId]),
      });
    } catch (e, stack) {
      await _firestoreService.logError(
        franchiseId,
        message: 'Failed to mark alert as seen: $e',
        source: 'alerts_repository_markAlertSeen',
        stackTrace: stack.toString(),
        contextData: {
          'alertId': alertId,
          'userId': userId,
        },
        userId: userId,
        screen: screen ?? 'AlertsRepository',
        errorType: e.runtimeType.toString(),
        severity: 'error',
      );
    }
  }
}
