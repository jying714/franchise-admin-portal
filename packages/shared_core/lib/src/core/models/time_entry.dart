/// Append-only clock event / completed punch pair (LAB.1 / L2).
/// Path: franchises/{franchiseId}/time_entries/{id}
class TimeEntry {
  final String id;
  final String franchiseId;
  final String staffId;
  final String staffName;
  final String? shiftId;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final String source; // pos | hq | mobile
  final String? clockInByStaffId;
  final String? clockOutByStaffId;
  final String? notes;
  final bool managerAdjusted;
  final DateTime? createdAt;

  const TimeEntry({
    required this.id,
    required this.franchiseId,
    required this.staffId,
    required this.staffName,
    this.shiftId,
    required this.clockInAt,
    this.clockOutAt,
    this.source = 'pos',
    this.clockInByStaffId,
    this.clockOutByStaffId,
    this.notes,
    this.managerAdjusted = false,
    this.createdAt,
  });

  bool get isOpen => clockOutAt == null;

  Duration get workedDuration {
    final end = clockOutAt ?? DateTime.now();
    final d = end.difference(clockInAt);
    return d.isNegative ? Duration.zero : d;
  }

  double get workedHours => workedDuration.inMinutes / 60.0;

  factory TimeEntry.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      try {
        return (v as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    DateTime? parseTsOpt(dynamic v) {
      if (v == null) return null;
      return parseTs(v);
    }

    return TimeEntry(
      id: id,
      franchiseId: data['franchiseId'] as String? ?? '',
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? '',
      shiftId: data['shiftId'] as String?,
      clockInAt: parseTs(data['clockInAt']),
      clockOutAt: parseTsOpt(data['clockOutAt']),
      source: data['source'] as String? ?? 'pos',
      clockInByStaffId: data['clockInByStaffId'] as String?,
      clockOutByStaffId: data['clockOutByStaffId'] as String?,
      notes: data['notes'] as String?,
      managerAdjusted: data['managerAdjusted'] as bool? ?? false,
      createdAt: parseTsOpt(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'staffId': staffId,
      'staffName': staffName,
      if (shiftId != null) 'shiftId': shiftId,
      'clockInAt': clockInAt.toIso8601String(),
      if (clockOutAt != null) 'clockOutAt': clockOutAt!.toIso8601String(),
      'source': source,
      if (clockInByStaffId != null) 'clockInByStaffId': clockInByStaffId,
      if (clockOutByStaffId != null) 'clockOutByStaffId': clockOutByStaffId,
      if (notes != null) 'notes': notes,
      'managerAdjusted': managerAdjusted,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  TimeEntry copyWith({
    String? id,
    String? franchiseId,
    String? staffId,
    String? staffName,
    String? shiftId,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    String? source,
    String? clockInByStaffId,
    String? clockOutByStaffId,
    String? notes,
    bool? managerAdjusted,
    DateTime? createdAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      shiftId: shiftId ?? this.shiftId,
      clockInAt: clockInAt ?? this.clockInAt,
      clockOutAt: clockOutAt ?? this.clockOutAt,
      source: source ?? this.source,
      clockInByStaffId: clockInByStaffId ?? this.clockInByStaffId,
      clockOutByStaffId: clockOutByStaffId ?? this.clockOutByStaffId,
      notes: notes ?? this.notes,
      managerAdjusted: managerAdjusted ?? this.managerAdjusted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
