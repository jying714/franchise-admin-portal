// packages/shared_core/lib/src/core/repositories/labor_firestore_repository.dart
//
// Thin adapter over LaborFirestoreService. Zero behavior change.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shift.dart';
import '../models/time_entry.dart';
import '../services/labor_firestore_service.dart';
import 'labor_repository.dart';

class LaborFirestoreRepository implements LaborRepository {
  LaborFirestoreRepository({
    FirebaseFirestore? firestore,
    LaborFirestoreService? service,
  }) : _service = service ?? LaborFirestoreService(firestore: firestore);

  final LaborFirestoreService _service;

  @override
  Stream<List<Shift>> streamShiftsInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) =>
      _service.streamShiftsInRange(
        franchiseId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

  @override
  Future<List<Shift>> getShiftsInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool fromServer = false,
  }) =>
      _service.getShiftsInRange(
        franchiseId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        fromServer: fromServer,
      );

  @override
  Future<Shift> saveShift(Shift shift) => _service.saveShift(shift);

  @override
  Future<void> cancelShift(String franchiseId, String shiftId) =>
      _service.cancelShift(franchiseId, shiftId);

  @override
  Future<void> deleteShift(String franchiseId, String shiftId) =>
      _service.deleteShift(franchiseId, shiftId);

  @override
  Future<Shift?> findCurrentShiftForStaff(
    String franchiseId,
    String staffId, {
    DateTime? at,
    Duration grace = const Duration(minutes: 15),
  }) =>
      _service.findCurrentShiftForStaff(
        franchiseId,
        staffId,
        at: at,
        grace: grace,
      );

  @override
  Stream<List<TimeEntry>> streamOpenEntries(String franchiseId) =>
      _service.streamOpenEntries(franchiseId);

  @override
  Future<TimeEntry?> getOpenEntryForStaff(
    String franchiseId,
    String staffId,
  ) =>
      _service.getOpenEntryForStaff(franchiseId, staffId);

  @override
  Future<List<TimeEntry>> getEntriesInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    String? staffId,
  }) =>
      _service.getEntriesInRange(
        franchiseId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        staffId: staffId,
      );

  @override
  Future<TimeEntry> clockIn({
    required String franchiseId,
    required String staffId,
    required String staffName,
    String? shiftId,
    String source = 'pos',
    String? actedByStaffId,
  }) =>
      _service.clockIn(
        franchiseId: franchiseId,
        staffId: staffId,
        staffName: staffName,
        shiftId: shiftId,
        source: source,
        actedByStaffId: actedByStaffId,
      );

  @override
  Future<TimeEntry> clockOut({
    required String franchiseId,
    required String staffId,
    String? actedByStaffId,
  }) =>
      _service.clockOut(
        franchiseId: franchiseId,
        staffId: staffId,
        actedByStaffId: actedByStaffId,
      );
}
