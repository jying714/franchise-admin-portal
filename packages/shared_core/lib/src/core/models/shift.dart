/// Scheduled work block for one staff member (LAB.1).
/// Path: franchises/{franchiseId}/shifts/{id}
class Shift {
  final String id;
  final String franchiseId;
  final String staffId;
  final String staffName;
  final String role;
  final DateTime startAt;
  final DateTime endAt;
  final String status; // scheduled | cancelled | completed
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shift({
    required this.id,
    required this.franchiseId,
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.startAt,
    required this.endAt,
    this.status = 'scheduled',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Duration get duration {
    final d = endAt.difference(startAt);
    return d.isNegative ? Duration.zero : d;
  }

  double get durationHours => duration.inMinutes / 60.0;

  factory Shift.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      if (v is String)
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      try {
        // Firestore Timestamp
        return (v as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return Shift(
      id: id,
      franchiseId: data['franchiseId'] as String? ?? '',
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? '',
      role: data['role'] as String? ?? 'cashier',
      startAt: parseTs(data['startAt']),
      endAt: parseTs(data['endAt']),
      status: data['status'] as String? ?? 'scheduled',
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null ? parseTs(data['createdAt']) : null,
      updatedAt: data['updatedAt'] != null ? parseTs(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'staffId': staffId,
      'staffName': staffName,
      'role': role,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Shift copyWith({
    String? id,
    String? franchiseId,
    String? staffId,
    String? staffName,
    String? role,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      role: role ?? this.role,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
