// web_app/lib/core/services/firestore_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';

class FirestoreServiceImpl implements FirestoreService {
  late final firestore.FirebaseFirestore _db;
  late final fb_auth.FirebaseAuth auth;
  late final FirebaseFunctions functions;

  FirestoreServiceImpl() {
    _db = firestore.FirebaseFirestore.instance;
    auth = fb_auth.FirebaseAuth.instance;
    functions = FirebaseFunctions.instance;
  }

  @override
  firestore.FirebaseFirestore get db => _db;

  @override
  List<IngredientMetadata>? _cachedIngredientMetadata;
  @override
  DateTime? _lastIngredientMetadataFetch;

  @override
  String? get currentUserId => auth.currentUser?.uid;

  @override
  firestore.CollectionReference get invitationCollection =>
      _db.collection('franchisee_invitations');

  @override
  Future<List<IngredientMetadata>> getAllIngredientMetadata(String franchiseId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedIngredientMetadata != null &&
        _lastIngredientMetadataFetch != null &&
        DateTime.now().difference(_lastIngredientMetadataFetch!).inMinutes < 15) {
      return _cachedIngredientMetadata!;
    }
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_ingredientMetadata)
        .get();
    final result = snap.docs
        .map((d) => IngredientMetadata.fromMap(d.data()))
        .toList(growable: false);
    _cachedIngredientMetadata = result;
    _lastIngredientMetadataFetch = DateTime.now();
    return result;
  }

  @override
  Future<List<IngredientMetadata>> getIngredientMetadataByIds(String franchiseId, List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final snap = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection(_ingredientMetadata)
          .where(firestore.FieldPath.documentId, whereIn: ids)
          .get();
      return snap.docs
          .map((d) => IngredientMetadata.fromMap(d.data()))
          .toList(growable: false);
    } catch (e, stack) {
      _logFirestoreError('getIngredientMetadataByIds', e, stack);
      return [];
    }
  }

  @override
  Future<Map<String, IngredientMetadata>> getIngredientMetadataMap(String franchiseId, {bool forceRefresh = false}) async {
    final all = await getAllIngredientMetadata(franchiseId, forceRefresh: forceRefresh);
    return {for (final meta in all) meta.id: meta};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchIngredientMetadataAsMaps(String franchiseId, {bool forceRefresh = false}) async {
    final all = await getAllIngredientMetadata(franchiseId, forceRefresh: forceRefresh);
    return all.map((meta) => meta.toMap()).toList();
  }

  @override
  Future<List<String>> getAllergensForIngredientIds(String franchiseId, List<String>? ingredientIds) async {
    if (ingredientIds == null || ingredientIds.isEmpty) return [];
    final metaMap = await getIngredientMetadataMap(franchiseId);
    final allergens = <String>{};
    for (final rawId in ingredientIds) {
      final id = rawId.trim();
      final meta = metaMap[id];
      if (meta != null && meta.allergens.isNotEmpty) {
        allergens.addAll(meta.allergens);
      }
    }
    return allergens.toList()..sort();
  }

  @override
  Future<List<String>> getAllergensForCustomizations(String franchiseId, List<Customization> customizations) async {
    final ingredientIds = <String>[];
    void collectIds(List<Customization> list) {
      for (final c in list) {
        if (!c.isGroup && c.ingredientId != null) {
          ingredientIds.add(c.ingredientId!);
        }
        if (c.options != null) {
          collectIds(c.options!);
        }
      }
    }
    collectIds(customizations);
    return getAllergensForIngredientIds(franchiseId, ingredientIds);
  }

  @override
  Future<Map<String, dynamic>?> getFranchiseeInvitationByToken(String token) async {
    print('[firestore_service.dart] getFranchiseeInvitationByToken called with token=$token');
    final snap = await invitationCollection.doc(token).get();
    final data = snap.data();
    if (data == null) {
      print('[firestore_service.dart] getFranchiseeInvitationByToken: No invite doc found for token=$token');
      return null;
    }
    print('[firestore_service.dart] getFranchiseeInvitationByToken: Invite doc loaded for token=$token data=$data');
    return {
      ...(data as Map<Object?, Object?>).map((k, v) => MapEntry(k.toString(), v)),
      'id': snap.id,
    };
  }

  @override
  Future<String> createFranchiseProfile({required Map<String, dynamic> franchiseData, required String invitedUserId}) async {
    try {
      String? franchiseId = franchiseData['franchiseId'];
      if (franchiseId == null || franchiseId.trim().isEmpty) {
        final name = (franchiseData['name'] ?? '') as String;
        if (name.trim().isEmpty) {
          throw Exception('Franchise name is required to generate franchiseId.');
        }
        franchiseId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      }

      final franchiseRef = _db.collection('franchises').doc(franchiseId);
      final userRef = _db.collection('users').doc(invitedUserId);

      await franchiseRef.set({
        ...franchiseData,
        'franchiseId': franchiseId,
        'ownerUserId': invitedUserId,
        'status': 'active',
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      }, firestore.SetOptions(merge: true));

      await userRef.set({
        'franchiseIds': firestore.FieldValue.arrayUnion([franchiseId]),
        'defaultFranchise': franchiseId,
      }, firestore.SetOptions(merge: true));

      return franchiseId;
    } catch (e, st) {
      print('[FirestoreService] createFranchiseProfile error: $e\n$st');
      ErrorLogger.log(
        message: 'Failed to create franchise profile: $e',
        stack: st.toString(),
        source: 'FirestoreService',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserClaims({required String uid, required List<String> franchiseIds, List<String>? roles, Map<String, dynamic>? additionalClaims}) async {
    final callable = functions.httpsCallable('updateUserClaims');
    final payload = {
      'uid': uid,
      'franchiseIds': franchiseIds,
      if (roles != null) 'roles': roles,
      if (additionalClaims != null) 'additionalClaims': additionalClaims,
    };
    print('[FirestoreService] updateUserClaims called with:');
    print('  uid=$uid');
    print('  franchiseIds=$franchiseIds');
    if (roles != null) print('  roles=$roles');
    if (additionalClaims != null) print('  additionalClaims=$additionalClaims');

    try {
      final result = await callable.call(payload);
      print('[FirestoreService] updateUserClaims success: result=${result.data}');
    } catch (e, st) {
      print('[FirestoreService] updateUserClaims ERROR: $e');
      print('[FirestoreService] Stack trace:\n$st');
      rethrow;
    }
  }

  // ... Continue implementing ALL other methods exactly as in original
  // (I will append in next message if you send more)

  @override
  Stream<List<Order>> getAllOrdersStream(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Order.fromFirestore(data, doc.id);
            }).toList());
  }

  @override
  Future<Map<String, dynamic>> getGlobalFeatureToggles() async {
    final doc = await _db.collection('config').doc('features').get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  @override
  Future<Map<String, dynamic>> getFranchiseFeatureToggles(String franchiseId) async {
    final doc = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features')
        .get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
  }

  @override
  Future<void> setFranchiseFeatureToggles(String franchiseId, Map<String, dynamic> toggles) async {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features');
    await docRef.set(toggles, firestore.SetOptions(merge: true));
  }

  @override
  Stream<Map<String, dynamic>> streamFranchiseFeatureToggles(String franchiseId) {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features');
    return docRef.snapshots().map((doc) => doc.data() ?? {});
  }

  @override
  Future<void> updateFeatureToggle(String franchiseId, String key, dynamic value) async {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('features');
    await docRef.set({key: value}, firestore.SetOptions(merge: true));
  }

  @override
  Future<void> addErrorLogGlobal(ErrorLog log) async {
    await _db.collection('error_logs').add(log.toFirestore());
  }

  @override
  Future<void> updateErrorLogGlobal(String logId, Map<String, dynamic> updates) async {
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  @override
  Future<ErrorLog?> getErrorLogGlobal(String logId) async {
    final doc = await _db.collection('error_logs').doc(logId).get();
    if (!doc.exists) return null;
    return ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Stream<List<ErrorLog>> streamErrorLogsGlobal({
    String? franchiseId,
    String? userId,
    String? severity,
    String? platform,
    String? screen,
    DateTime? start,
    DateTime? end,
    int limit = 100,
  }) {
    firestore.Query query = _db.collection('error_logs');

    if (franchiseId != null && franchiseId != 'all') {
      debugPrint('Filtering by franchiseId = $franchiseId');
      query = query.where('franchiseId', isEqualTo: franchiseId);
    } else {
      debugPrint('No franchise filter applied');
    }

    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (severity != null) query = query.where('severity', isEqualTo: severity);
    if (screen != null) query = query.where('screen', isEqualTo: screen);

    if (start != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(start));
    }
    if (end != null) {
      final adjustedEnd = end.add(const Duration(days: 1));
      query = query.where('createdAt', isLessThan: firestore.Timestamp.fromDate(adjustedEnd));
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snap) {
      final validDocs = snap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data.containsKey('createdAt') && data['createdAt'] != null;
      }).toList();

      debugPrint('Filtered ErrorLog snapshot: ${validDocs.length} logs returned');

      return validDocs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            try {
              return ErrorLog.fromMap(data, doc.id);
            } catch (e) {
              debugPrint('Failed to parse ErrorLog: ${doc.id} - $e');
              return null;
            }
          })
          .whereType<ErrorLog>()
          .toList();
    });
  }

  @override
  Future<List<ErrorLogSummary>> getErrorLogSummaries() async {
    final snap = await _db.collection('error_logs').limit(250).get();

    print('Filtered ErrorLog snapshot: ${snap.docs.length} logs returned');

    final logs = snap.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null) {
            print('Skipped log ${doc.id} – null data');
            return null;
          }
          final tsRaw = data['timestamp'] ?? data['createdAt'];
          if (tsRaw == null) {
            print('Skipped log ${doc.id} – missing timestamp/createdAt');
            return null;
          }
          if (tsRaw is! firestore.Timestamp) {
            print('Skipped log ${doc.id} – invalid timestamp type: ${tsRaw.runtimeType}');
            return null;
          }

          return ErrorLogSummary(
            id: doc.id,
            timestamp: tsRaw.toDate(),
            message: data['message'] ?? '[No message]',
            severity: data['severity'] ?? 'unknown',
            franchiseId: _extractFranchiseId(data['franchiseId']),
          );
        })
        .whereType<ErrorLogSummary>()
        .toList();

    logs.sort((a, b) {
      final cmp = _severityScore(b.severity).compareTo(_severityScore(a.severity));
      if (cmp != 0) return cmp;
      return b.timestamp.compareTo(a.timestamp);
    });

    return logs.take(5).toList();
  }

  int _severityScore(String severity) {
    switch (severity) {
      case 'fatal': return 4;
      case 'error': return 3;
      case 'warning': return 2;
      case 'info': return 1;
      default: return 0;
    }
  }

  String? _extractFranchiseId(dynamic raw) {
    if (raw is String) return raw;
    if (raw is firestore.DocumentReference) return raw.id;
    return null;
  }

  @override
  Stream<List<ErrorLog>> streamErrorLogs(
    String franchiseId, {
    int limit = 50,
    String? severity,
    String? source,
    String? screen,
    DateTime? start,
    DateTime? end,
    String? search,
    bool archived = false,
    bool? showResolved,
  }) {
    firestore.Query query = _db
        .collection('error_logs')
        .where('franchiseId', isEqualTo: franchiseId);

    if (severity != null && severity.isNotEmpty && severity != 'null' && severity != 'all') {
      query = query.where('severity', isEqualTo: severity);
    }
    if (source != null && source.isNotEmpty) {
      query = query.where('source', isEqualTo: source);
    }
    if (screen != null && screen.isNotEmpty) {
      query = query.where('screen', isEqualTo: screen);
    }

    query = query.where('archived', isEqualTo: archived);

    if (showResolved != null) {
      query = query.where('resolved', isEqualTo: showResolved);
    }

    if (start != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('timestamp', isLessThan: firestore.Timestamp.fromDate(end));
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    return query.snapshots().map((snap) => snap.docs
        .map((doc) => ErrorLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  @override
  Future<void> deleteErrorLogGlobal(String logId) async {
    await _db.collection('error_logs').doc(logId).delete();
  }

  @override
  Future<void> logSchemaError(String franchiseId, {required String message, String? templateId, String? menuItemId, String? stackTrace, String? userId}) async {
    ErrorLogger.log(
      message: message,
      stack: stackTrace,
      source: 'customization_template_resolution',
      contextData: {
        'franchiseId': franchiseId,
        if (templateId != null) 'templateId': templateId,
        if (menuItemId != null) 'menuItemId': menuItemId,
        if (userId != null) 'userId': userId,
      },
    );
  }

  @override
  Future<void> logError(
    String? franchiseId, {
    required String message,
    required String source,
    String? userId,
    String? screen,
    String? stackTrace,
    String? errorType,
    String? severity,
    Map<String, dynamic>? contextData,
    Map<String, dynamic>? deviceInfo,
    String? assignedTo,
  }) async {
    print('Logging error for franchiseId=$franchiseId, message=$message');
    try {
      final data = <String, dynamic>{
        'message': message,
        'source': source,
        if (userId != null) 'userId': userId,
        if (screen != null) 'screen': screen,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (errorType != null) 'errorType': errorType,
        if (severity != null) 'severity': severity,
        if (contextData != null && contextData.isNotEmpty) 'contextData': contextData,
        if (deviceInfo != null && deviceInfo.isNotEmpty) 'deviceInfo': deviceInfo,
        if (assignedTo != null) 'assignedTo': assignedTo,
        'timestamp': firestore.FieldValue.serverTimestamp(),
        'resolved': false,
        'archived': false,
        'comments': <Map<String, dynamic>>[],
      };
      await _db.collection('error_logs').add({
        ...data,
        'franchiseId': franchiseId,
      });
    } catch (e, stack) {
      print('[ERROR LOGGING FAILURE] $e\n$stack');
    }
  }

  @override
  Future<void> updateErrorLog(String franchiseId, String logId, Map<String, dynamic> updates) async {
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  @override
  Future<void> addCommentToErrorLog(String franchiseId, String logId, Map<String, dynamic> comment) async {
    await _db.collection('error_logs').doc(logId).update({
      'comments': firestore.FieldValue.arrayUnion([comment]),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setErrorLogStatus(String franchiseId, String logId, {bool? resolved, bool? archived}) async {
    final updates = <String, dynamic>{};
    if (resolved != null) updates['resolved'] = resolved;
    if (archived != null) updates['archived'] = archived;
    updates['updatedAt'] = firestore.FieldValue.serverTimestamp();
    await _db.collection('error_logs').doc(logId).update(updates);
  }

  @override
  Future<void> deleteErrorLog(String franchiseId, String logId) async {
    await _db.collection('error_logs').doc(logId).delete();
  }

  @override
  Future<void> addAuditLogGlobal(AuditLog log) async {
    await _db.collection('audit_logs').add(log.toFirestore());
  }

  @override
  Future<AuditLog?> getAuditLogGlobal(String logId) async {
    final doc = await _db.collection('audit_logs').doc(logId).get();
    if (!doc.exists) return null;
    return AuditLog.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Stream<List<AuditLog>> auditLogsStreamGlobal({String? franchiseId, String? userId, String? action}) {
    firestore.Query query = _db.collection('audit_logs').orderBy('timestamp', descending: true);
    if (franchiseId != null) query = query.where('franchiseId', isEqualTo: franchiseId);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (action != null) query = query.where('action', isEqualTo: action);
    return query.snapshots().map((snap) => snap.docs
        .map((doc) {
          final data = doc.data();
          if (data != null) {
            return AuditLog.fromFirestore(data as Map<String, dynamic>, doc.id);
          } else {
            return null;
          }
        })
        .where((log) => log != null)
        .cast<AuditLog>()
        .toList());
  }

  @override
  Future<void> addAuditLogFranchise(String franchiseId, AuditLog log) async {
    final data = log.toFirestore();
    data['franchiseId'] = franchiseId;
    await _db.collection('audit_logs').add(data);
  }

  @override
  Future<AuditLog?> getAuditLogFranchise(String franchiseId, String logId) async {
    final doc = await _db.collection('audit_logs').doc(logId).get();
    if (!doc.exists) return null;
    return AuditLog.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Stream<List<AuditLog>> auditLogsStreamFranchise(String franchiseId, {String? userId, String? action}) {
    firestore.Query query = _db
        .collection('audit_logs')
        .where('franchiseId', isEqualTo: franchiseId)
        .orderBy('timestamp', descending: true);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (action != null) query = query.where('action', isEqualTo: action);
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  @override
  Stream<List<app_user.User>> getStaffUsers(String franchiseId) {
    return _db
        .collection('users')
        .where('franchiseIds', arrayContains: franchiseId)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => app_user.User.fromFirestore(doc.data(), doc.id))
          .where((user) =>
              user.roles.contains('staff') ||
              user.roles.contains('manager') ||
              user.roles.contains('admin') ||
              user.roles.contains('hq_owner'))
          .toList();
    });
  }

  @override
  Future<void> addStaffUser({required String name, required String email, String? phone, required List<String> roles, required List<String> franchiseIds}) async {
    final docRef = _db.collection('users').doc();
    await docRef.set({
      'id': docRef.id,
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'roles': roles,
      'franchiseIds': franchiseIds,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  @override
  Future<void> removeStaffUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isActive': false});
  }

  @override
  Future<List<FranchiseInfo>> fetchFranchiseList() async {
    final snapshot = await _db.collection('franchises').get();
    return snapshot.docs.map((doc) {
      return FranchiseInfo.fromMap(doc.data(), doc.id);
    }).toList();
  }

  @override
  Future<List<FranchiseInfo>> getFranchisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await firestore.FirebaseFirestore.instance
        .collection('franchises')
        .where(firestore.FieldPath.documentId, whereIn: ids)
        .get();
    return snapshot.docs
        .map((doc) => FranchiseInfo.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<FranchiseInfo>> getFranchises() async {
    final query = await _db.collection('franchises').get();
    return query.docs
        .map((doc) => FranchiseInfo.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<FranchiseInfo>> getAllFranchises() async {
    final snapshot = await firestore.FirebaseFirestore.instance
        .collection('franchises')
        .get();
    return snapshot.docs
        .map((doc) => FranchiseInfo.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addOrUpdatePayout(Payout payout) async {
    await _db
        .collection('payouts')
        .doc(payout.id)
        .set(payout.toFirestore(), firestore.SetOptions(merge: true));
  }

  @override
  Future<Payout?> getPayoutById(String id) async {
    final doc = await _db.collection('payouts').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Payout.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<void> deletePayout(String id) async {
    await _db.collection('payouts').doc(id).delete();
  }

  @override
  Stream<List<Payout>> payoutsStream({String? franchiseId, String? status}) {
    firestore.Query query = _db.collection('payouts');
    if (franchiseId != null) query = query.where('franchiseId', isEqualTo: franchiseId);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => Payout.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  @override
  Future<List<Map<String, dynamic>>> getPayoutsForFranchise({required String franchiseId, String? status, String? searchQuery}) async {
    final docRef = firestore.FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId);

    firestore.Query<Map<String, dynamic>> query = firestore
        .FirebaseFirestore.instance
        .collection('payouts')
        .where('franchiseId', isEqualTo: docRef);

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    final snap = await query.orderBy('scheduled_at', descending: true).get();

    List<Map<String, dynamic>> payouts = snap.docs.map((doc) {
      final rawData = doc.data();
      final data = (rawData is Map<String, dynamic>) ? rawData : <String, dynamic>{};

      return {
        'id': doc.id,
        'status': data['status'] ?? '',
        'amount': (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
        'created_at': (data['scheduled_at'] is firestore.Timestamp)
            ? (data['scheduled_at'] as firestore.Timestamp).toDate()
            : null,
        'sent_at': (data['sent_at'] is firestore.Timestamp)
            ? (data['sent_at'] as firestore.Timestamp).toDate()
            : null,
        'failed_at': (data['failed_at'] is firestore.Timestamp)
            ? (data['failed_at'] as firestore.Timestamp).toDate()
            : null,
        'method': data['method'] is String ? data['method'] as String : '',
        'bank_account_last4': data['bank_account_last4']?.toString() ?? '',
        'notes': data['notes'] is String ? data['notes'] as String : '',
      };
    }).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      payouts = payouts.where((p) {
        return (p['id'] ?? '').toString().toLowerCase().contains(q) ||
            (p['status'] ?? '').toString().toLowerCase().contains(q) ||
            (p['amount']?.toString() ?? '').toLowerCase().contains(q) ||
            (p['method'] ?? '').toString().toLowerCase().contains(q) ||
            (p['bank_account_last4'] ?? '').toString().toLowerCase().contains(q) ||
            (p['notes'] ?? '').toString().toLowerCase().contains(q) ||
            (p['created_at'] != null && p['created_at'].toString().toLowerCase().contains(q)) ||
            (p['sent_at'] != null && p['sent_at'].toString().toLowerCase().contains(q)) ||
            (p['failed_at'] != null && p['failed_at'].toString().toLowerCase().contains(q));
      }).toList();
    }

    return payouts;
  }

  @override
  Future<List<Payout>> fetchPayouts({
    String? franchiseId,
    String? status,
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? sortBy,
    bool descending = true,
    int?...

    firestore.DocumentSnapshot? startAfter,
  }) async {
    firestore.Query query = _db.collection('payouts');
    if (franchiseId != null) {
      query = query.where('franchiseId',
          isEqualTo: _db.collection('franchises').doc(franchiseId));
    }
    if (status != null && status != 'all') query = query.where('status', isEqualTo: status);
    if (locationId != null) {
      query = query.where('locationId',
          isEqualTo: _db.collection('franchise_locations').doc(locationId));
    }
    if (startDate != null) query = query.where('scheduled_at',
        isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(startDate));
    if (endDate != null) query = query.where('scheduled_at',
        isLessThanOrEqualTo: firestore.Timestamp.fromDate(endDate));
    if (search != null && search.isNotEmpty) {
      query = query
          .where('notes', isGreaterThanOrEqualTo: search)
          .where('notes', isLessThan: search + 'z');
    }
    if (sortBy != null) query = query.orderBy(sortBy, descending: descending);
    else query = query.orderBy('scheduled_at', descending: descending);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    if (limit != null) query = query.limit(limit);
    final snap = await query.get();
    return snap.docs
        .map((doc) => Payout.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getPayoutDetailsWithAudit(String payoutId) async {
    final doc = await _db.collection('payouts').doc(payoutId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final auditTrail = List<Map<String, dynamic>>.from(data['audit_trail'] ?? []);
    return {...data, 'id': doc.id, 'audit_trail': auditTrail};
  }

  @override
  Future<void> addPayoutAuditEvent(String payoutId, Map<String, dynamic> event) async {
    await _db.collection('payouts').doc(payoutId).update({
      'audit_trail': firestore.FieldValue.arrayUnion([event]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addAttachmentToPayout(String payoutId, Map<String, dynamic> attachment) async {
    await _db.collection('payouts').doc(payoutId).update({
      'attachments': firestore.FieldValue.arrayUnion([attachment]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeAttachmentFromPayout(String payoutId, Map<String, dynamic> attachment) async {
    await _db.collection('payouts').doc(payoutId).update({
      'attachments': firestore.FieldValue.arrayRemove([attachment]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> bulkUpdatePayoutStatus(List<String> payoutIds, String status) async {
    final batch = _db.batch();
    for (final id in payoutIds) {
      batch.update(_db.collection('payouts').doc(id), {
        'status': status,
        'updated_at': firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> addPayoutComment(String payoutId, Map<String, dynamic> comment) async {
    await _db.collection('payouts').doc(payoutId).update({
      'comments': firestore.FieldValue.arrayUnion([comment]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPayoutComments(String payoutId) async {
    final doc = await _db.collection('payouts').doc(payoutId).get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    final comments = data['comments'] as List? ?? [];
    return List<Map<String, dynamic>>.from(comments);
  }

  @override
  Future<void> removePayoutComment(String payoutId, Map<String, dynamic> comment) async {
    await _db.collection('payouts').doc(payoutId).update({
      'comments': firestore.FieldValue.arrayRemove([comment]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markPayoutSent(String payoutId, {DateTime? sentAt}) async {
    await _db.collection('payouts').doc(payoutId).update({
      'status': 'sent',
      'sent_at': firestore.FieldValue.serverTimestamp(),
      if (sentAt != null) 'sent_at': firestore.Timestamp.fromDate(sentAt),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPayoutStatus(String payoutId, String newStatus) async {
    await _db.collection('payouts').doc(payoutId).update({
      'status': newStatus,
      'failed_at': newStatus == 'failed' ? firestore.FieldValue.serverTimestamp() : null,
      'sent_at': newStatus == 'sent' ? firestore.FieldValue.serverTimestamp() : null,
      if (newStatus != 'failed') ...{
        'error_message': '',
        'error_code': '',
      },
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markPayoutFailed(String payoutId, {String? errorMsg, String? errorCode}) async {
    await _db.collection('payouts').doc(payoutId).update({
      'status': 'failed',
      'failed_at': firestore.FieldValue.serverTimestamp(),
      if (errorMsg != null) 'error_message': errorMsg,
      if (errorCode != null) 'error_code': errorCode,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> retryPayout(String payoutId) async {
    await _db.collection('payouts').doc(payoutId).update({
      'status': 'pending',
      'error_message': '',
      'error_code': '',
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<AuditLog>> getAuditLogsForPayout(String payoutId) async {
    final snap = await _db
        .collection('audit_logs')
        .where('targetId', isEqualTo: payoutId)
        .get();
    return snap.docs
        .map((doc) => AuditLog.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<String> exportPayoutsToCsv({
    String? franchiseId,
    String? status,
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? sortBy,
    bool descending = true,
    int? limit,
  }) async {
    final payouts = await fetchPayouts(
      franchiseId: franchiseId,
      status: status,
      locationId: locationId,
      startDate: startDate,
      endDate: endDate,
      search: search,
      sortBy: sortBy,
      descending: descending,
      limit: limit,
    );

    final csv = StringBuffer();
    csv.writeln('ID,Amount,Currency,Status,Method,Scheduled At,Sent At,Failed At,Bank Account Last4,Notes,Failure Reason,Error Code,Error Message');

    for (final p in payouts) {
      String formatDate(DateTime? dt) => dt != null ? dt.toIso8601String() : '';
      String escape(String? value) => value == null ? '' : value.replaceAll('"', '""');

      csv.writeln('${p.id},'
          '${p.amount},'
          '${p.currency},'
          '${p.status},'
          '${escape(p.method)},'
          '${formatDate(p.scheduledAt)},'
          '${formatDate(p.sentAt)},'
          '${formatDate(p.failedAt)},'
          '${escape(p.bankAccountLast4)},'
          '"${escape(p.notes)}",'
          '"${escape(p.failureReason)}",'
          '"${escape(p.errorCode)}",'
          '"${escape(p.errorMessage)}"');
    }
    return csv.toString();
  }

  @override
  Future<Map<String, dynamic>> getInvoiceStatsForFranchise(String franchiseId) async {
    try {
      final querySnapshot = await _db
          .collection('invoices')
          .where('franchiseId', isEqualTo: _db.collection('franchises').doc(franchiseId))
          .get();

      final invoices = querySnapshot.docs
          .map((doc) => Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final totalInvoices = invoices.length;
      final openStatuses = {InvoiceStatus.open, InvoiceStatus.sent, InvoiceStatus.viewed, InvoiceStatus.draft};
      final openInvoices = invoices.where((inv) => openStatuses.contains(inv.status)).toList();
      final overdueInvoices = invoices.where((inv) => inv.status == InvoiceStatus.overdue).toList();
      final paidInvoices = invoices.where((inv) => inv.status == InvoiceStatus.paid).toList();

      final totalOverdue = overdueInvoices.fold<double>(0.0, (sum, inv) => sum + inv.total);
      final outstandingBalance = invoices.fold<double>(0.0, (sum, inv) => sum + inv.outstanding);

      DateTime? lastInvoiceDate;
      if688(invoices.isNotEmpty) {
        invoices.sort((a, b) => b.issuedAt?.compareTo(a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0)) ?? 0);
        lastInvoiceDate = invoices.first.issuedAt;
      }

      return {
        'totalInvoices': totalInvoices,
        'openInvoiceCount': openInvoices.length,
        'overdueInvoiceCount': overdueInvoices.length,
        'overdueAmount': totalOverdue,
        'paidInvoiceCount': paidInvoices.length,
        'outstandingBalance': outstandingBalance,
        'lastInvoiceDate': lastInvoiceDate,
      };
    } catch (e, stackTrace) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stackTrace.toString(),
        source: 'FirestoreService',
        severity: 'error',
      );
      rethrow;
    }
  }

  // ... Continue implementing ALL other methods exactly as in original
  // (I will append in next message if you send more)

  @override
  Future<List<Customization>> getMenuItemCustomizations(String franchiseId, String menuItemId) async {
    final doc = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_menuItems)
        .doc(menuItemId)
        .get();
    if (!doc.exists || doc.data() == null) return [];
    final data = doc.data()!;
    if (data['customizations'] == null) return [];
    return (data['customizations'] as List<dynamic>)
        .map((e) => Customization.fromFirestore(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  List<Customization> getCustomizationGroups(MenuItem item) {
    return item.customizations.where((c) => c.isGroup).toList();
  }

  @override
  List<Customization> getPreselectedCustomizations(MenuItem item) {
    List<Customization> flatten(List<Customization> list) {
      return list
          .expand((c) => c.isGroup && c.options != null ? flatten(c.options!) : [c])
          .toList();
    }
    return flatten(item.customizations).where((c) => c.isDefault).toList();
  }

  @override
  Customization? findCustomizationOption(List<Customization> groups, String idOrName) {
    for (final group in groups) {
      if (group.id == idOrName || group.name == idOrName) return group;
      if (group.options != null) {
        final found = findCustomizationOption(group.options!, idOrName);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  Future<void> addInventory(String franchiseId, Inventory inventory) async {
    final doc = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .doc();
    await doc.set(inventory.copyWith(id: doc.id).toFirestore());
  }

  @override
  Future<void> updateInventory(String franchiseId, Inventory inventory) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .doc(inventory.id)
        .update(inventory.toFirestore());
  }

  @override
  Future<void> deleteInventory(String franchiseId, String id) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .doc(id)
        .delete();
  }

  @override
  Stream<List<Inventory>> getInventory(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_inventory)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Inventory.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<Map<String, dynamic>?> getCashFlowForecast(String franchiseId) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('cash_flow_forecasts')
        .orderBy('period', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  @override
  Future<Map<String, dynamic>> getFranchiseAnalyticsSummary(String franchiseId) async {
    final snap = await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('analytics_summaries')
        .orderBy('period', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return {};
    return snap.docs.first.data();
  }

  @override
  Future<double> getOutstandingInvoices(String franchiseId) async {
    final snap = await _db
        .collection('invoices')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('status', isEqualTo: 'sent')
        .get();

    double total = 0.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['paid_at'] == null) {
        total += (data['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  @override
  Future<Map<String, dynamic>> getLastPayout(String franchiseId) async {
    final snap = await _db
        .collection('payouts')
        .where('franchiseId', isEqualTo: franchiseId)
        .orderBy('scheduled_at', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return {};
    final data = snap.docs.first.data();
    return {
      'amount': data['amount'],
      'date': data['scheduled_at']?.toDate()?.toIso8601String(),
    };
  }

  @override
  Future<Map<String, int>> getPayoutStatsForFranchise(String franchiseId) async {
    try {
      final query = firestore.FirebaseFirestore.instance
          .collection('payouts')
          .where('franchiseId', isEqualTo: franchiseId);

      final snapshot = await query.get();

      int pending = 0;
      int sent = 0;
      int failed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        if (status == 'pending') {
          pending++;
        } else if (status == 'sent') {
          sent++;
        } else if (status == 'failed') {
          failed++;
        }
      }

      return {
        'pending': pending,
        'sent': sent,
        'failed': failed,
      };
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'getPayoutStatsForFranchise failed: $e',
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return {
        'pending': 0,
        'sent': 0,
        'failed': 0,
      };
    }
  }

  @override
  Future<void> addPromo(String franchiseId, Promo promo) async => _db
      .collection('franchises')
      .doc(franchiseId)
      .collection('promotions')
      .doc(promo.id)
      .set(promo.toFirestore());

  @override
  Stream<List<Promo>> getPromos(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('promotions')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Promo.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Future<void> updatePromo(String franchiseId, Promo promo) async => _db
      .collection('franchises')
      .doc(franchiseId)
      .collection('promotions')
      .doc(promo.id)
      .update(promo.toFirestore());

  @override
  Future<void> deletePromo(String franchiseId, String promoId) async => _db
      .collection('franchises')
      .doc(franchiseId)
      .collection('promotions')
      .doc(promoId)
      .delete();

  @override
  Stream<List<feedback_model.FeedbackEntry>> getFeedbackEntries(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_feedback)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => feedback_model.FeedbackEntry.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<void> deleteFeedbackEntry(String franchiseId, String id) async {
    await _db
        .collection('franchises')
        .doc(franchiseId)
        .collection(_feedback)
        .doc(id)
        .delete();
  }

  @override
  Future<firestore.DocumentReference> addSupportRequest(Map<String, dynamic> data) async {
    final now = firestore.FieldValue.serverTimestamp();
    data['created_at'] ??= now;
    data['updated_at'] ??= now;
    return await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .add(data);
  }

  @override
  Future<void> updateSupportRequest(String requestId, Map<String, dynamic> updates) async {
    updates['updated_at'] = firestore.FieldValue.serverTimestamp();
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update(updates);
  }

  @override
  Future<Map<String, dynamic>?> getSupportRequestById(String requestId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  @override
  Stream<List<Map<String, dynamic>>> supportRequestsStream({
    String? franchiseId,
    String? locationId,
    String? status,
    String? type,
    String? assignedTo,
    String? openedBy,
    int limit = 50,
  }) {
    firestore.Query query = firestore.FirebaseFirestore.instance.collection('support_requests');
    if (franchiseId != null) query = query.where('franchiseId', isEqualTo: franchiseId);
    if (locationId != null) query = query.where('locationId', isEqualTo: locationId);
    if (status != null) query = query.where('status', isEqualTo: status);
    if (type != null) query = query.where('type', isEqualTo: type);
    if (assignedTo != null) query = query.where('assigned_to', isEqualTo: assignedTo);
    if (openedBy != null) query = query.where('opened_by', isEqualTo: openedBy);
    query = query.orderBy('created_at', descending: true).limit(limit);

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Future<void> addMessageToSupportRequest(String requestId, Map<String, dynamic> message) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update({
      'messages': firestore.FieldValue.arrayUnion([message]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteSupportRequest(String requestId) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .delete();
  }

  @override
  Future<void> addSupportNote(String requestId, Map<String, dynamic> note) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update({
      'support_notes': firestore.FieldValue.arrayUnion([note]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateSupportType(String requestId, String type) async {
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update({
      'type': type,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> linkEntitiesToSupportRequest(String requestId, {String? invoiceId, String? paymentId}) async {
    final update = <String, dynamic>{};
    if (invoiceId != null) update['invoiceId'] = invoiceId;
    if (paymentId != null) update['paymentId'] = paymentId;
    update['updated_at'] = firestore.FieldValue.serverTimestamp();

    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update(update);
  }

  @override
  Future<void> updateSupportRequestStatus(String requestId, {required String status, String? lastUpdatedBy, String? resolutionNotes}) async {
    final update = <String, dynamic>{
      'status': status,
      'updated_at': firestore.FieldValue.serverTimestamp(),
    };
    if (lastUpdatedBy != null) update['last_updated_by'] = lastUpdatedBy;
    if (resolutionNotes != null) update['resolution_notes'] = resolutionNotes;
    if (status == 'closed' || status == 'resolved') {
      update['closed_at'] = firestore.FieldValue.serverTimestamp();
    }
    await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .update(update);
  }

  @override
  Future<List<Map<String, dynamic>>> getSupportNotes(String requestId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    final notes = data['support_notes'] as List<dynamic>? ?? [];
    return notes.cast<Map<String, dynamic>>();
  }

  @override
  Stream<List<Map<String, dynamic>>> supportRequestsByTypeOrStatus({String? type, String? status, int limit = 50}) {
    var query = firestore.FirebaseFirestore.instance
        .collection('support_requests')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (type != null) query = query.where('type', isEqualTo: type);
    if (status != null) query = query.where('status', isEqualTo: status);

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Future<firestore.DocumentReference> addTaxReport(Map<String, dynamic> data) async {
    final now = firestore.FieldValue.serverTimestamp();
    data['created_at'] ??= now;
    data['updated_at'] ??= now;
    return await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .add(data);
  }

  @override
  Future<void> updateTaxReport(String reportId, Map<String, dynamic> updates) async {
    updates['updated_at'] = firestore.FieldValue.serverTimestamp();
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .update(updates);
  }

  @override
  Future<Map<String, dynamic>?> getTaxReportById(String reportId) async {
    final doc = await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  @override
  Stream<List<Map<String, dynamic>>> taxReportsStream({
    String? franchiseId,
    String? brandId,
    String? reportType,
    String? status,
    String? taxAuthority,
    DateTime? filedAfter,
    DateTime? filedBefore,
    int limit = 100,
  }) {
    var query = firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (franchiseId != null) query = query.where('franchiseId', isEqualTo: franchiseId);
    if (brandId != null) query = query.where('brandId', isEqualTo: brandId);
    if (reportType != null) query = query.where('report_type', isEqualTo: reportType);
    if (status != null) query = query.where('status', isEqualTo: status);
    if (taxAuthority != null) query = query.where('tax_authority', isEqualTo: taxAuthority);
    if (filedAfter != null) {
      query = query.where('date_filed', isGreaterThanOrEqualTo: filedAfter.toUtc());
    }
    if (filedBefore != null) {
      query = query.where('date_filed', isLessThanOrEqualTo: filedBefore.toUtc());
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Future<void> deleteTaxReport(String reportId) async {
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .delete();
  }

  @override
  Future<void> addTaxReportReminder(String reportId, Map<String, dynamic> reminder) async {
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .update({
      'reminders_sent': firestore.FieldValue.arrayUnion([reminder]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addTaxReportAttachment(String reportId, Map<String, dynamic> attachment) async {
    await firestore.FirebaseFirestore.instance
        .collection('tax_reports')
        .doc(reportId)
        .update({
      'attached_files': firestore.FieldValue.arrayUnion([attachment]),
      'updated_at': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<FranchiseeInvitation>> fetchInvitations({String? status, String? inviterUserId, String? email}) async {
    try {
      firestore.Query query = invitationCollection;
      if (status != null) query = query.where('status', isEqualTo: status);
      if (inviterUserId != null) query = query.where('inviterUserId', isEqualTo: inviterUserId);
      if (email != null) query = query.where('email', isEqualTo: email);
      final snap = await query.orderBy('createdAt', descending: true).get();
      return snap.docs.map((doc) => FranchiseeInvitation.fromDoc(doc)).toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch invitations',
        stack: stack.toString(),
        source: 'FirestoreService.fetchInvitations',
        contextData: {'exception': e.toString()},
      );
      rethrow;
    }
  }

  @override
  Stream<List<FranchiseeInvitation>> invitationStream({String? status, String? inviterUserId}) {
    firestore.Query query = invitationCollection;
    if (status != null) query = query.where('status', isEqualTo: status);
    if (inviterUserId != null) query = query.where('inviterUserId', isEqualTo: inviterUserId);
    return query.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs.map((doc) => FranchiseeInvitation.fromDoc(doc)).toList());
  }

  @override
  Future<FranchiseeInvitation?> fetchInvitationById(String id) async {
    try {
      final doc = await invitationCollection.doc(id).get();
      if (!doc.exists) return null;
      return FranchiseeInvitation.fromDoc(doc);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch invitation by id',
        stack: stack.toString(),
        source: 'FirestoreService.fetchInvitationById',
        contextData: {'exception': e.toString(), 'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateInvitation(String id, Map<String, dynamic> data) async {
    try {
      await invitationCollection.doc(id).update(data);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update invitation',
        stack: stack.toString(),
        source: 'FirestoreService.updateInvitation',
        contextData: {'exception': e.toString(), 'id': id, 'data': data},
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelInvitation(String id, {String? revokedByUserId}) async {
    try {
      await invitationCollection.doc(id).update({
        'status': 'revoked',
        if (revokedByUserId != null) 'revokedByUserId': revokedByUserId,
        'revokedAt': firestore.Timestamp.now(),
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to cancel/revoke invitation',
        stack: stack.toString(),
        source: 'FirestoreService.cancelInvitation',
        contextData: {
          'exception': e.toString(),
          'id': id,
          'revokedBy': revokedByUserId
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteInvitation(String id) async {
    try {
      await invitationCollection.doc(id).delete();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to delete invitation',
        stack: stack.toString(),
        source: 'FirestoreService.deleteInvitation',
        contextData: {'exception': e.toString(), 'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> expireInvitation(String id) async {
    try {
      await invitationCollection.doc(id).update({
        'status': 'expired',
        'expiredAt': firestore.Timestamp.now(),
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to expire invitation',
        stack: stack.toString(),
        source: 'FirestoreService.expireInvitation',
        contextData: {'exception': e.toString(), 'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<void> markInvitationResent(String id) async {
    try {
      await invitationCollection.doc(id).update({
        'status': 'sent',
        'lastSentAt': firestore.Timestamp.now(),
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to mark invitation as resent',
        stack: stack.toString(),
        source: 'FirestoreService.markInvitationResent',
        contextData: {'exception': e.toString(), 'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<PlatformRevenueOverview> fetchPlatformRevenueOverview() async {
    try {
      final now = DateTime.now();
      final ytdStart = DateTime(now.year, 1, 1);

      final query = _db.collection('invoices').where('period_start',
          isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(ytdStart));

      final invoices = await query.get();

      double totalRevenueYtd = 0;
      double subscriptionRevenue = 0;
      double royaltyRevenue = 0;
      double overdueAmount = 0;

      for (var doc in invoices.docs) {
        final data = doc.data();
        final amountDue = ((data['amount_due'] ?? 0) as num).toDouble();
        final status = data['status']?.toString();
        final type = data['type']?.toString()?.toLowerCase() ?? '';

        totalRevenueYtd += amountDue;
        if (type == 'subscription') {
          subscriptionRevenue += amountDue;
        } else if (type == 'royalty') {
          royaltyRevenue += amountDue;
        }

        if (status == 'overdue' || status == 'unpaid') {
          overdueAmount += amountDue;
        }
      }

      return PlatformRevenueOverview(
        totalRevenueYtd: totalRevenueYtd,
        subscriptionRevenue: subscriptionRevenue,
        royaltyRevenue: royaltyRevenue,
        overdueAmount: overdueAmount,
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<PlatformFinancialKpis> fetchPlatformFinancialKpis() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final subQuery = _db
          .collection('invoices')
          .where('type', isEqualTo: 'subscription')
          .where('period_start',
              isGreaterThanOrEqualTo:
                  firestore.Timestamp.fromDate(startOfMonth));
      final subInvoices = await subQuery.get();

      double mrr = 0;
      final activeFranchiseIds = <String>{};
      for (var doc in subInvoices.docs) {
        final data = doc.data();
        mrr += ((data['amount_due'] ?? 0) as num).toDouble();
        final franchiseId = data['franchiseId']?.toString();
        if (franchiseId != null && franchiseId.isNotEmpty) {
          activeFranchiseIds.add(franchiseId);
        }
      }
      double arr = mrr * 12;

      final recentPayouts =
          await PayoutService().sumRecentPlatformPayouts(days: 30);

      return PlatformFinancialKpis(
        mrr: mrr,
        arr: arr,
        activeFranchises: activeFranchiseIds.length,
        recentPayouts: recentPayouts,
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Stream<List<PlatformInvoice>> platformInvoicesStream({required String franchiseeId, String? status}) {
    try {
      firestore.Query query = _db
          .collection('platform_invoices')
          .where('franchiseeId', isEqualTo: franchiseeId);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      return query
          .orderBy('dueDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return PlatformInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              } catch (e, stack) {
                ErrorLogger.log(
                  message: 'Failed to parse PlatformInvoice from Firestore: $e',
                  stack: stack.toString(),
                  source: 'FirestoreService',
                  contextData: {'docId': doc.id},
                );
                return null;
              }
            })
            .whereType<PlatformInvoice>()
            .toList();
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Exception in platformInvoicesStream: $e',
        stack: stack.toString(),
        source: 'FirestoreService',
        contextData: {'franchiseeId': franchiseeId, 'status': status},
      );
      return const Stream.empty();
    }
  }

  @override
  Future<List<PlatformInvoice>> getPlatformInvoicesForUser(String userId) async {
    try {
      debugPrint('[FirestoreService] getPlatformInvoicesForUser called for userId=$userId');

      final querySnapshot = await _db
          .collection('platform_invoices')
          .where('franchiseeId', isEqualTo: userId)
          .orderBy('dueDate', descending: true)
          .get();

      final invoices = querySnapshot.docs
          .map((doc) {
            try {
              return PlatformInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            } catch (e, stack) {
              ErrorLogger.log(
                message: 'Failed to parse invoice doc: $e',
                stack: stack.toString(),
                source: 'FirestoreService.getPlatformInvoicesForUser',
                contextData: {'invoiceId': doc.id},
              );
              return null;
            }
          })
          .whereType<PlatformInvoice>()
          .toList();

      debugPrint('[FirestoreService] Loaded ${invoices.length} invoices for user $userId');
      return invoices;
    } catch (e, stack) {
      debugPrint('[FirestoreService] ERROR in getPlatformInvoicesForUser: $e');
      ErrorLogger.log(
        message: 'Failed to load platform invoices: $e',
        stack: stack.toString(),
        source: 'FirestoreService.getPlatformInvoicesForUser',
        severity: 'error',
        contextData: {'userId': userId},
      );
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPlatformPaymentsForUser(String userId) async {
    try {
      debugPrint('[FirestoreService] getPlatformPaymentsForUser called for userId=$userId');

      final query = await _db
          .collection('platform_payments')
          .where('franchiseeId', isEqualTo: userId)
          .get();

      final result = query.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      debugPrint('[FirestoreService] platform_payments results for $userId: ${result.length} docs');
      for (var doc in result) {
        debugPrint('[FirestoreService] Payment doc: $doc');
      }

      return result;
    } catch (e, stack) {
      debugPrint('[FirestoreService] ERROR in getPlatformPaymentsForUser: $e');
      ErrorLogger.log(
        message: 'Failed to load platform payments: $e',
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
        contextData: {'userId': userId},
      );
      return [];
    }
  }

  @override
  Future<void> savePlatformInvoiceFromWebhook(Map<String, dynamic> eventData, String invoiceId) async {
    try {
      final invoice = PlatformInvoice.fromStripeWebhook(eventData, invoiceId);
      final ref = firestore.FirebaseFirestore.instance
          .collection('platform_invoices')
          .doc(invoiceId);

      await ref.set(invoice.toMap(), firestore.SetOptions(merge: true));

      print('[FirestoreService] Invoice $invoiceId saved from webhook.');
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save platform invoice from webhook: $e',
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
        contextData: {
          'invoiceId': invoiceId,
          'eventType': eventData['type'],
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<PlatformInvoice>> getPlatformInvoicesForFranchisee(String franchiseeId) async {
    try {
      final snapshot = await _db
          .collection('platform_invoices')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('dueDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlatformInvoice.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch platform invoices for $franchiseeId: $e',
        stack: stack.toString(),
        source: 'FirestoreService.getPlatformInvoicesForFranchisee',
      );
      return [];
    }
  }

  @override
  Future<void> createPlatformInvoice(PlatformInvoice invoice) async {
    try {
      await _db
          .collection('platform_invoices')
          .doc(invoice.id)
          .set(invoice.toMap());
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create platform invoice ${invoice.id}: $e',
        stack: stack.toString(),
        source: 'FirestoreService.createPlatformInvoice',
      );
    }
  }

  @override
  Future<void> updatePlatformInvoiceStatus(String invoiceId, String newStatus) async {
    try {
      await _db
          .collection('platform_invoices')
          .doc(invoiceId)
          .update({'status': newStatus});
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update invoice status ($invoiceId -> $newStatus): $e',
        stack: stack.toString(),
        source: 'FirestoreService.updatePlatformInvoiceStatus',
      );
    }
  }

  @override
  Future<List<PlatformPayment>> getPlatformPaymentsForFranchisee(String franchiseeId) async {
    try {
      final snapshot = await _db
          .collection('platform_payments')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlatformPayment.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch platform payments for $franchiseeId: $e',
        stack: stack.toString(),
        source: 'FirestoreService.getPlatformPaymentsForFranchisee',
      );
      return [];
    }
  }

  @override
  Future<void> createPlatformPayment(PlatformPayment payment) async {
    try {
      await _db
          .collection('platform_payments')
          .doc(payment.id)
          .set(payment.toMap());
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to create platform payment ${payment.id}: $e',
        stack: stack.toString(),
        source: 'FirestoreService.createPlatformPayment',
      );
    }
  }

  @override
  Future<void> markPlatformPaymentCompleted(String paymentId) async {
    try {
      await _db
          .collection('platform_payments')
          .doc(paymentId)
          .update({'status': 'completed'});
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to mark platform payment $paymentId as completed: $e',
        stack: stack.toString(),
        source: 'FirestoreService.markPlatformPaymentCompleted',
      );
    }
  }

  @override
  Future<void> updatePlatformPaymentStatus(String paymentId, String newStatus) async {
    try {
      await _db
          .collection('platform_payments')
          .doc(paymentId)
          .update({'status': newStatus});
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update platform payment status ($paymentId -> $newStatus): $e',
        stack: stack.toString(),
        source: 'FirestoreService.updatePlatformPaymentStatus',
      );
    }
  }

  @override
  Future<void> markPlatformInvoicePaid(String invoiceId, String method) async {
    try {
      await _db.collection('platform_invoices').doc(invoiceId).update({
        'status': 'paid',
        'paidAt': firestore.FieldValue.serverTimestamp(),
        'lastPaymentMethod': method,
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to mark invoice paid: $e',
        stack: stack.toString(),
        source: 'markPlatformInvoicePaid',
      );
      rethrow;
    }
  }

  @override
  Future<List<FranchiseSubscription>> getFranchiseSubscriptions() async {
    try {
      final snap = await firestore.FirebaseFirestore.instance
          .collection("franchise_subscriptions")
          .get();

      return snap.docs
          .map((doc) => FranchiseSubscription.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch franchise subscriptions',
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
        contextData: {'exception': e.toString()},
      );
      return [];
    }
  }

  @override
  Future<FranchiseSubscription?> getFranchiseSubscription(String franchiseId) async {
    try {
      final doc = await _db
          .collection('franchise_subscriptions')
          .doc(franchiseId)
          .get();

      if (doc.exists && doc.data() != null) {
        return FranchiseSubscription.fromMap(doc.id, doc.data()!);
      } else {
        ErrorLogger.log(
          message: 'No subscription found for franchiseId: $franchiseId',
          stack: '',
          source: 'FirestoreService',
          severity: 'warning',
          contextData: {'franchiseId': franchiseId},
        );
        return null;
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Error fetching franchise subscription',
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'exception': e.toString(),
        },
      );
      return null;
    }
  }

  @override
  Future<FranchiseSubscription?> getCurrentSubscriptionForFranchise(String franchiseId) async {
    try {
      debugPrint('[FirestoreService] getCurrentSubscriptionForFranchise: franchiseId=$franchiseId');

      final query = await _db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        debugPrint('[FirestoreService] No active subscription found.');
        return null;
      }

      final doc = query.docs.first;
      debugPrint('[FirestoreService] Active subscription found: ${doc.id}');
      return FranchiseSubscription.fromMap(doc.id, doc.data());
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to load current subscription: $e',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Future<List<FranchiseSubscription>> getAllFranchiseSubscriptions() async {
    try {
      debugPrint('[FirestoreService] getAllFranchiseSubscriptions: Fetching all subscriptions...');

      final snap = await _db.collection('franchise_subscriptions').get();

      final list = snap.docs
          .map((doc) => FranchiseSubscription.fromMap(doc.id, doc.data()))
          .toList();

      debugPrint('[FirestoreService] Retrieved ${list.length} subscriptions.');
      return list;
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch all franchise subscriptions: $e',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
      );
      return [];
    }
  }

  @override
  Future<List<firestore.QueryDocumentSnapshot<Map<String, dynamic>>>> getAllFranchiseSubscriptionsRaw() async {
    final snap = await _db
        .collection('franchise_subscriptions')
        .orderBy('subscribedAt', descending: true)
        .get();
    return snap.docs;
  }

  @override
  Future<List<Map<String, dynamic>>> getStoreInvoicesForUser(String userId) async {
    final query = await _db
        .collection('store_invoices')
        .where('storeOwnerId', isEqualTo: userId)
        .get();
    return query.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Future<FranchiseInfo?> getFranchiseInfo(String franchiseId) async {
    try {
      final doc = await _db.collection('franchises').doc(franchiseId).get();
      if (!doc.exists) {
        ErrorLogger.log(
          message: 'Franchise document not found: $franchiseId',
          source: 'FirestoreService.getFranchiseInfo',
          severity: 'warning',
          contextData: {'franchiseId': franchiseId},
        );
        return null;
      }
      return FranchiseInfo.fromMap(doc.data()!, franchiseId);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch franchise info: $e',
        stack: stack.toString(),
        source: 'FirestoreService.getFranchiseInfo',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getOnboardingProgress(String franchiseId) async {
    print('[DEBUG][FirestoreService.getOnboardingProgress] Called with franchiseId="$franchiseId"');
    try {
      final doc = await _db.collection('onboarding_progress').doc(franchiseId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch onboarding progress for $franchiseId',
        stack: stack.toString(),
        source: 'FirestoreService.getOnboardingProgress',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Future<void> updateOnboardingStep({required String franchiseId, required String stepKey, required bool completed}) async {
    try {
      final docRef = _db.collection('onboarding_progress').doc(franchiseId);
      await docRef.set({
        stepKey: completed,
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      }, firestore.SetOptions(merge: true));

      if (_isFinalStep(stepKey, completed)) {
        await docRef.set({
          'completedAt': firestore.FieldValue.serverTimestamp(),
        }, firestore.SetOptions(merge: true));
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update onboarding step "$stepKey"',
        stack: stack.toString(),
        source: 'FirestoreService.updateOnboardingStep',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'stepKey': stepKey,
          'completed': completed,
        },
      );
    }
  }

  bool _isFinalStep(String key, bool completed) {
    return key == 'review' && completed == true;
  }

  @override
  Future<void> setOnboardingComplete({required String franchiseId}) async {
    try {
      await db.collection('franchises').doc(franchiseId).update({
        'onboardingStatus': 'complete',
        'onboardingCompletedAt': firestore.FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to set onboarding complete for franchise',
        stack: stack.toString(),
        source: 'FirestoreService.setOnboardingComplete',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<void> simulateWebhookEvent({
    required String invoiceId,
    required String eventType,
    String status = 'paid',
    double amount = 0.0,
    String currency = 'USD',
    String? planId,
    String? subscriptionId,
    String? receiptUrl,
    DateTime? paidAt,
    String paymentMethod = 'mock_card',
    String paymentProvider = 'developer',
  }) async {
    try {
      final timestamp = DateTime.now();
      final paidAtMillis = paidAt?.millisecondsSinceEpoch ?? timestamp.millisecondsSinceEpoch;

      final eventData = {
        'type': eventType,
        'data': {
          'object': {
            'id': invoiceId,
            'status': status,
            'amount_due': (amount * 100).toInt(),
            'currency': currency.toLowerCase(),
            'created': (timestamp.millisecondsSinceEpoch / 1000).round(),
            'due_date': (timestamp.add(const Duration(days: 30)).millisecondsSinceEpoch / 1000).round(),
            'invoice_pdf': 'https://example.com/invoices/mock_$invoiceId.pdf',
            'hosted_invoice_url': receiptUrl ?? 'https://example.com/receipt/mock_$invoiceId',
            'livemode': false,
            'metadata': {
              'franchiseeId': auth.currentUser?.uid ?? 'test_user',
              if (planId != null) 'planId': planId,
            },
            'payment_intent': 'pi_mock_$invoiceId',
            'subscription': subscriptionId,
            'payment_settings': {
              'payment_method_types': [paymentMethod],
            },
            'status_transitions': {
              'paid_at': (paidAtMillis / 1000).round(),
            },
            'number': 'MOCK-$invoiceId',
            'description': 'Simulated invoice for testing',
          }
        }
      };

      await savePlatformInvoiceFromWebhook(eventData, invoiceId);

      debugPrint('[FirestoreService] Simulated webhook event "$eventType" for invoice $invoiceId');
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to simulate webhook event: $e',
        stack: stack.toString(),
        source: 'FirestoreService.simulateWebhookEvent',
        contextData: {
          'invoiceId': invoiceId,
          'eventType': eventType,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> logSimulatedWebhookEvent(Map<String, dynamic> data) async {
    await _db.collection('simulated_webhooks').add(data);
  }

  @override
  Future<List<PlatformInvoice>> getTestPlatformInvoices({required String franchiseeId}) async {
    try {
      var query = _db
          .collection('platform_invoices')
          .where('isTest', isEqualTo: true)
          .where('franchiseeId', isEqualTo: franchiseeId);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => PlatformInvoice.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch test invoices: $e',
        stack: stack.toString(),
        source: 'FirestoreService.getTestPlatformInvoices',
      );
      return [];
    }
  }

  @override
  Future<void> copyIngredientTypesFromTemplate({required String franchiseId, required String templateId}) async {
    final firestoreService = FirestoreService();

    final sourceRef = firestoreService.db
        .collection('onboarding_templates')
        .doc(templateId)
        .collection('ingredient_types');

    final destRef = firestoreService.db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_types');

    try {
      final snapshot = await sourceRef.get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No ingredient types found in template "$templateId"');
      }

      final batch = firestoreService.db.batch();
      final now = firestore.FieldValue.serverTimestamp();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final destDoc = destRef.doc(doc.id);
        batch.set(destDoc, {
          ...data,
          'createdAt': now,
          'updatedAt': now,
        });
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'copyIngredientTypesFromTemplate failed',
        stack: stack.toString(),
        severity: 'error',
        source: 'FirestoreService.copyIngredientTypesFromTemplate',
        contextData: {
          'franchiseId': franchiseId,
          'templateId': templateId,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> updateIngredientTypeSortOrders({required String franchiseId, required List<Map<String, dynamic>> sortedUpdates}) async {
    final batch = _db.batch();

    try {
      for (final update in sortedUpdates) {
        final String? id = update['id'];
        final int? sortOrder = update['sortOrder'];

        if (id == null || sortOrder == null) {
          throw ArgumentError('Each update must include non-null "id" and "sortOrder".');
        }

        final docRef = _db
            .collection('franchises')
            .doc(franchiseId)
            .collection('ingredient_types')
            .doc(id);

        batch.update(docRef, {
          'sortOrder': sortOrder,
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to update ingredient type sort orders',
        stack: stack.toString(),
        severity: 'error',
        source: 'firestore_service.dart',
        contextData: {
          'franchiseId': franchiseId,
          'updatesAttempted': sortedUpdates,
          'errorType': e.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> replaceIngredientTypesFromJson({required String franchiseId, required List<IngredientType> items}) async {
    final batch = _db.batch();
    final collectionRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_types');

    try {
      final existingSnap = await collectionRef.get();
      for (final doc in existingSnap.docs) {
        batch.delete(doc.reference);
      }

      for (final type in items) {
        final docRef = collectionRef.doc(type.id ?? _db.collection('').doc().id);
        batch.set(docRef, type.toMap());
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to replace ingredient types from JSON',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'incomingItemCount': items.length,
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<IngredientMetadata>> getIngredientMetadataTemplate(String templateId) async {
    try {
      final snapshot = await _db
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('ingredient_metadata')
          .get();

      return snapshot.docs
          .map((doc) => IngredientMetadata.fromMap(doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'ingredient_metadata_template_load_error',
        source: 'FirestoreService',
        stack: stack.toString(),
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> importIngredientMetadataTemplate({required String templateId, required String franchiseId}) async {
    try {
      final templateDocs = await getIngredientMetadataTemplate(templateId);
      final destRef = _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata');
      final batch = _db.batch();

      for (final item in templateDocs) {
        batch.set(destRef.doc(item.id), item.toMap());
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'importIngredientMetadataTemplate_failed',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'templateId': templateId,
          'franchiseId': franchiseId,
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<IngredientMetadata>> fetchIngredientMetadata(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      print('[ERROR][fetchIngredientMetadata] Called with empty/unknown franchiseId!');
      ErrorLogger.log(
        message: 'fetchIngredientMetadata called with blank/unknown franchiseId',
        stack: '',
        source: 'FirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
    try {
      final snapshot = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('ingredient_metadata')
          .get();

      return snapshot.docs
          .map((doc) => IngredientMetadata.fromMap(doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'fetchIngredientMetadata failed',
        stack: stack.toString(),
        source: 'FirestoreService',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchIngredientTypeIds(String franchiseId) async {
    final snapshot = await db
        .collection('franchises')
        .doc(franchiseId)
        .collection('ingredient_types')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<List<model.Category>> fetchCategories(String franchiseId) async {
    try {
      print('[FirestoreService.fetchCategories] Fetching from /franchises/$franchiseId/categories');

      final snapshot = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories')
          .get();

      return snapshot.docs
          .map((doc) => model.Category.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch categories',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }

  @override
  Future<void> saveCategory(String franchiseId, model.Category category) async {
    try {
      await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('categories')
          .doc(category.id)
          .set(category.toFirestore());
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save category',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'categoryId': category.id,
          'categoryName': category.name,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> replaceAllCategories(String franchiseId, List<model.Category> categories) async {
    final batch = _db.batch();
    final colRef = _db.collection('franchises').doc(franchiseId).collection('categories');

    try {
      final existing = await colRef.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      for (final category in categories) {
        batch.set(colRef.doc(category.id), category.toFirestore());
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to bulk replace categories',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'newCount': categories.length,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> saveAllCategories(String franchiseId, List<model.Category> categories) async {
    final batch = _db.batch();
    final colRef = _db.collection('franchises').doc(franchiseId).collection('categories');

    try {
      for (final category in categories) {
        final docRef = colRef.doc(category.id);
        batch.set(docRef, category.toFirestore());
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to batch save categories',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'categoryCount': categories.length,
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<MenuItem>> fetchMenuItemsOnce(String franchiseId) async {
    try {
      final snapshot = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .orderBy('sortOrder', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return MenuItem.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch menu items',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
  }

  @override
  Future<void> saveMenuItems(String franchiseId, List<MenuItem> items) async {
    final batch = _db.batch();
    final collection = _db.collection('franchises').doc(franchiseId).collection('menu_items');

    try {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        if (item.id.isEmpty) {
          ErrorLogger.log(
            message: 'MenuItem missing ID, skipping save',
            source: 'FirestoreService',
            severity: 'warning',
            contextData: {
              'index': i,
              'franchiseId': franchiseId,
              'item': item.toMap(),
            },
          );
          continue;
        }

        final ref = collection.doc(item.id);
        final data = item.copyWith(sortOrder: i).toFirestore();
        batch.set(ref, data, firestore.SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to batch save menu items',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'itemCount': items.length},
      );
      rethrow;
    }
  }

  @override
  Future<void> reorderMenuItems(String franchiseId, List<MenuItem> ordered) async {
    final batch = _db.batch();
    final collection = _db.collection('franchises').doc(franchiseId).collection('menu_items');

    try {
      for (int i = 0; i < ordered.length; i++) {
        final item = ordered[i];
        final ref = collection.doc(item.id);
        batch.update(ref, {'sortOrder': i});
      }

      await batch.commit();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to reorder menu items',
        source: 'FirestoreService',
        severity: 'warning',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'itemCount': ordered.length,
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<MenuTemplateRef>> fetchMenuTemplateRefs({required String restaurantType}) async {
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('onboarding_templates')
          .doc(restaurantType)
          .collection('menu_items')
          .get();

      print('[DEBUG] menu_items docs found: ${snapshot.docs.length}');

      return snapshot.docs
          .map((doc) => MenuTemplateRef.fromFirestore(doc.data()))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch menu template refs',
        source: 'FirestoreService',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'restaurantType': restaurantType},
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> decodeJsonList(String input) async {
    try {
      final parsed = jsonDecode(input);
      if (parsed is! List) {
        throw FormatException('Input JSON must be a list of objects.');
      }

      return List<Map<String, dynamic>>.from(parsed);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to decode JSON input for feature/plans import',
        severity: 'error',
        stack: stack.toString(),
        source: 'FirestoreService.decodeJsonList',
        contextData: {
          'inputSnippet': input.length > 300 ? input.substring(0, 300) : input,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<SizeTemplate>> getSizeTemplatesForTemplate(String restaurantType) async {
    final snapshot = await _db
        .collection('onboarding_templates')
        .doc(restaurantType)
        .collection('sizes')
        .get();

    return snapshot.docs.map((doc) => SizeTemplate.fromFirestore(doc)).toList();
  }

  @override
  String get invitationCollectionPath => 'franchisee_invitations';

  CollectionReference get invitationCollection => 
      _db.collection(invitationCollectionPath);


  @override
  Stream<admin_user.User?> userStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data() != null
            ? admin_user.User.fromMap(doc.data()!, doc.id)
            : null);
  }
}
