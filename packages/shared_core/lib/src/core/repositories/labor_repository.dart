// packages/shared_core/lib/src/core/repositories/labor_repository.dart
//
// Bounded-context repository for shifts + time entries.
// Authority: docs/slices/bounded-context-repos-a4-inventory-labor.md (Phase A4)
// Wraps LaborFirestoreService — does not reimplement clock/schedule logic.

import '../models/shift.dart';
import '../models/time_entry.dart';

abstract class LaborRepository {
  // --- Shifts ---
  Stream<List<Shift>> streamShiftsInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  Future<List<Shift>> getShiftsInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool fromServer = false,
  });

  Future<Shift> saveShift(Shift shift);

  Future<void> cancelShift(String franchiseId, String shiftId);

  Future<void> deleteShift(String franchiseId, String shiftId);

  Future<Shift?> findCurrentShiftForStaff(
    String franchiseId,
    String staffId, {
    DateTime? at,
    Duration grace = const Duration(minutes: 15),
  });

  // --- Time entries ---
  Stream<List<TimeEntry>> streamOpenEntries(String franchiseId);

  Future<TimeEntry?> getOpenEntryForStaff(
    String franchiseId,
    String staffId,
  );

  Future<List<TimeEntry>> getEntriesInRange(
    String franchiseId, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    String? staffId,
  });

  Future<TimeEntry> clockIn({
    required String franchiseId,
    required String staffId,
    required String staffName,
    String? shiftId,
    String source = 'pos',
    String? actedByStaffId,
  });

  Future<TimeEntry> clockOut({
    required String franchiseId,
    required String staffId,
    String? actedByStaffId,
  });
}
