import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/driver.dart';
import '../models/pos_settings.dart';
import '../models/pos_table_layout.dart';
import '../models/print_job.dart';
import '../models/staff.dart';
import '../models/waitress.dart';

/// Thin franchise-scoped POS data access (Decision 14 / Phase 1.9).
/// Does not replace [FirestoreService]; station code should prefer this for POS paths.
class PosFirestoreService {
  PosFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _staffCol(String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection('staff');

  CollectionReference<Map<String, dynamic>> _driversCol(String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection('drivers');

  CollectionReference<Map<String, dynamic>> _waitressesCol(
          String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection('waitresses');

  CollectionReference<Map<String, dynamic>> _printJobsCol(String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection('print_jobs');

  DocumentReference<Map<String, dynamic>> _posSettingsDoc(String franchiseId) =>
      _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('pos_settings');

  DocumentReference<Map<String, dynamic>> _tableLayoutDoc(String franchiseId) =>
      _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('table_layout');

  // --- Staff ---

  Stream<List<Staff>> streamStaff(String franchiseId) {
    return _staffCol(franchiseId).snapshots().map((snap) =>
        snap.docs.map((d) => Staff.fromFirestore(d.data(), d.id)).toList());
  }

  Future<Staff?> getStaff(String franchiseId, String staffId) async {
    final doc = await _staffCol(franchiseId).doc(staffId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Staff.fromFirestore(doc.data()!, doc.id);
  }

  /// One-shot staff list from server (PIN match must not use stale cache).
  Future<List<Staff>> getStaffList(
    String franchiseId, {
    bool fromServer = true,
  }) async {
    final snap = await _staffCol(franchiseId).get(
      fromServer
          ? const GetOptions(source: Source.server)
          : const GetOptions(source: Source.serverAndCache),
    );
    return snap.docs.map((d) => Staff.fromFirestore(d.data(), d.id)).toList();
  }

  Future<void> saveStaff(String franchiseId, Staff staff) async {
    await _staffCol(franchiseId).doc(staff.id).set(
          staff.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // --- Drivers ---

  Stream<List<Driver>> streamDrivers(String franchiseId) {
    return _driversCol(franchiseId).snapshots().map((snap) =>
        snap.docs.map((d) => Driver.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> saveDriver(String franchiseId, Driver driver) async {
    await _driversCol(franchiseId).doc(driver.id).set(
          driver.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // --- Waitresses ---

  Stream<List<Waitress>> streamWaitresses(String franchiseId) {
    return _waitressesCol(franchiseId).snapshots().map((snap) =>
        snap.docs.map((d) => Waitress.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> saveWaitress(String franchiseId, Waitress waitress) async {
    await _waitressesCol(franchiseId).doc(waitress.id).set(
          waitress.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // --- Settings ---

  Future<PosSettings> getPosSettings(String franchiseId) async {
    final doc = await _posSettingsDoc(franchiseId).get();
    if (!doc.exists || doc.data() == null) {
      return PosSettings.defaults(franchiseId);
    }
    return PosSettings.fromFirestore(doc.data()!, franchiseId);
  }

  Stream<PosSettings> streamPosSettings(String franchiseId) {
    return _posSettingsDoc(franchiseId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return PosSettings.defaults(franchiseId);
      }
      return PosSettings.fromFirestore(doc.data()!, franchiseId);
    });
  }

  Future<void> savePosSettings(PosSettings settings) async {
    await _posSettingsDoc(settings.franchiseId).set(
      settings.toFirestore(),
      SetOptions(merge: true),
    );
  }

  // --- Table layout ---

  Future<PosTableLayout> getTableLayout(String franchiseId) async {
    final doc = await _tableLayoutDoc(franchiseId).get();
    if (!doc.exists || doc.data() == null) {
      return PosTableLayout.empty(franchiseId);
    }
    return PosTableLayout.fromFirestore(doc.data()!, franchiseId);
  }

  Stream<PosTableLayout> streamTableLayout(String franchiseId) {
    return _tableLayoutDoc(franchiseId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return PosTableLayout.empty(franchiseId);
      }
      return PosTableLayout.fromFirestore(doc.data()!, franchiseId);
    });
  }

  Future<void> saveTableLayout(PosTableLayout layout) async {
    await _tableLayoutDoc(layout.franchiseId).set(
      layout.toFirestore(),
      SetOptions(merge: true),
    );
  }

  // --- Print jobs (idempotent by clientJobId) ---

  Future<PrintJob?> findPrintJobByClientId(
    String franchiseId,
    String clientJobId,
  ) async {
    final q = await _printJobsCol(franchiseId)
        .where('clientJobId', isEqualTo: clientJobId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return PrintJob.fromFirestore(d.data(), d.id);
  }

  /// Creates a job only if [clientJobId] is new. Returns existing job if duplicate.
  Future<PrintJob> enqueuePrintJob(PrintJob job) async {
    final existing =
        await findPrintJobByClientId(job.franchiseId, job.clientJobId);
    if (existing != null) return existing;

    final ref = _printJobsCol(job.franchiseId).doc();
    final toSave = job.copyWith(id: ref.id);
    await ref.set(toSave.toFirestore());
    return toSave;
  }

  Future<void> updatePrintJobStatus(
    String franchiseId,
    String jobId, {
    required String status,
    String? errorMessage,
    int? attemptCount,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (attemptCount != null) 'attemptCount': attemptCount,
      if (status == PrintJob.statusPrinted || status == PrintJob.statusFailed)
        'completedAt': DateTime.now().toIso8601String(),
    };
    await _printJobsCol(franchiseId).doc(jobId).set(
          data,
          SetOptions(merge: true),
        );
  }
}
