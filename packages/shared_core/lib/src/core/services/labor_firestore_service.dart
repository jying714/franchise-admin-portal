import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shift.dart';
import '../models/time_entry.dart';

/// Franchise-scoped shifts + time entries (LAB.1).
/// HQ writes shifts; POS clocks via [clockIn] / [clockOut].
class LaborFirestoreService {
  LaborFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _shiftsCol(String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection('shifts');

  CollectionReference<Map<String, dynamic>> _entriesCol(String franchiseId) =>
      _db.collection('franchises').doc(franchiseId).collection('time_entries');

  // --- Shifts (HQ schedule) ---

  Stream<List<Shift>> streamShiftsInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return _shiftsCol(franchiseId)
        .where('startAt', isGreaterThanOrEqualTo: rangeStart.toIso8601String())
        .where('startAt', isLessThan: rangeEnd.toIso8601String())
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Shift.fromFirestore(d.data(), d.id)).toList();
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
      return list;
    });
  }

  Future<List<Shift>> getShiftsInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool fromServer = false,
  }) async {
    final snap = await _shiftsCol(franchiseId)
        .where('startAt', isGreaterThanOrEqualTo: rangeStart.toIso8601String())
        .where('startAt', isLessThan: rangeEnd.toIso8601String())
        .get(
          fromServer
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.serverAndCache),
        );
    final list =
        snap.docs.map((d) => Shift.fromFirestore(d.data(), d.id)).toList();
    list.sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  Future<Shift> saveShift(Shift shift) async {
    final col = _shiftsCol(shift.franchiseId);
    final ref = shift.id.isEmpty ? col.doc() : col.doc(shift.id);
    final now = DateTime.now();
    final toSave = shift.copyWith(
      id: ref.id,
      createdAt: shift.createdAt ?? now,
      updatedAt: now,
    );
    await ref.set(toSave.toFirestore(), SetOptions(merge: true));
    return toSave;
  }

  Future<void> cancelShift(String franchiseId, String shiftId) async {
    await _shiftsCol(franchiseId).doc(shiftId).set({
      'status': 'cancelled',
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteShift(String franchiseId, String shiftId) async {
    await _shiftsCol(franchiseId).doc(shiftId).delete();
  }

  /// Active scheduled shift covering [at] for [staffId], with optional grace.
  /// Always reads shifts from the server so POS sees HQ schedule edits live.
  Future<Shift?> findCurrentShiftForStaff(
    String franchiseId,
    String staffId, {
    DateTime? at,
    Duration grace = const Duration(minutes: 15),
  }) async {
    final now = at ?? DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final dayEnd =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
    final shifts = await getShiftsInRange(
      franchiseId,
      rangeStart: dayStart,
      rangeEnd: dayEnd,
      fromServer: true,
    );
    for (final s in shifts) {
      if (s.staffId != staffId) continue;
      if (s.status.toLowerCase() == 'cancelled') continue;
      final windowStart = s.startAt.subtract(grace);
      final windowEnd = s.endAt.add(grace);
      if (!now.isBefore(windowStart) && now.isBefore(windowEnd)) {
        return s;
      }
    }
    return null;
  }

  // --- Time entries (POS clock) ---

  Stream<List<TimeEntry>> streamOpenEntries(String franchiseId) {
    return _entriesCol(franchiseId).snapshots().map((snap) {
      return snap.docs
          .map((d) => TimeEntry.fromFirestore(d.data(), d.id))
          .where((e) => e.isOpen)
          .toList();
    });
  }

  Future<TimeEntry?> getOpenEntryForStaff(
    String franchiseId,
    String staffId,
  ) async {
    final snap = await _entriesCol(franchiseId)
        .where('staffId', isEqualTo: staffId)
        .get();
    final open = snap.docs
        .map((d) => TimeEntry.fromFirestore(d.data(), d.id))
        .where((e) => e.isOpen)
        .toList();
    if (open.isEmpty) return null;
    open.sort((a, b) => b.clockInAt.compareTo(a.clockInAt));
    return open.first;
  }

  Future<List<TimeEntry>> getEntriesInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    String? staffId,
  }) async {
    Query<Map<String, dynamic>> q = _entriesCol(franchiseId)
        .where('clockInAt',
            isGreaterThanOrEqualTo: rangeStart.toIso8601String())
        .where('clockInAt', isLessThan: rangeEnd.toIso8601String());
    if (staffId != null && staffId.isNotEmpty) {
      q = q.where('staffId', isEqualTo: staffId);
    }
    final snap = await q.get();
    final list =
        snap.docs.map((d) => TimeEntry.fromFirestore(d.data(), d.id)).toList();
    list.sort((a, b) => a.clockInAt.compareTo(b.clockInAt));
    return list;
  }

  /// Start a punch. Fails if staff already has an open entry.
  Future<TimeEntry> clockIn({
    required String franchiseId,
    required String staffId,
    required String staffName,
    String? shiftId,
    String source = 'pos',
    String? actedByStaffId,
  }) async {
    final existing = await getOpenEntryForStaff(franchiseId, staffId);
    if (existing != null) {
      throw StateError('Already clocked in (entry ${existing.id})');
    }

    final ref = _entriesCol(franchiseId).doc();
    final now = DateTime.now();
    final entry = TimeEntry(
      id: ref.id,
      franchiseId: franchiseId,
      staffId: staffId,
      staffName: staffName,
      shiftId: shiftId,
      clockInAt: now,
      source: source,
      clockInByStaffId: actedByStaffId ?? staffId,
      createdAt: now,
    );
    final data = entry.toFirestore();
    // Explicit null so open punches are queryable if needed later.
    data['clockOutAt'] = null;
    await ref.set(data);
    return entry;
  }

  /// Close the open punch for [staffId].
  Future<TimeEntry> clockOut({
    required String franchiseId,
    required String staffId,
    String? actedByStaffId,
  }) async {
    final open = await getOpenEntryForStaff(franchiseId, staffId);
    if (open == null) {
      throw StateError('No open time entry for staff $staffId');
    }

    final now = DateTime.now();
    final updated = open.copyWith(
      clockOutAt: now,
      clockOutByStaffId: actedByStaffId ?? staffId,
    );
    await _entriesCol(franchiseId).doc(open.id).set(
          updated.toFirestore(),
          SetOptions(merge: true),
        );
    return updated;
  }
}
