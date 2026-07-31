/// Kitchen / station print job. [clientJobId] is the idempotency key.
class PrintJob {
  final String id;
  final String franchiseId;
  final String orderId;

  /// Caller-generated unique id; duplicate submit with same id is a no-op.
  final String clientJobId;

  /// Menu category id used for printer routing (null → default printer).
  final String? categoryId;

  /// Target printer id (resolved by routing; may be default).
  final String? printerId;

  /// pending | printing | printed | failed
  final String status;
  final String? errorMessage;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Optional ticket payload snapshot (lines text or structured map).
  final Map<String, dynamic>? payload;

  PrintJob({
    required this.id,
    required this.franchiseId,
    required this.orderId,
    required this.clientJobId,
    this.categoryId,
    this.printerId,
    this.status = 'pending',
    this.errorMessage,
    this.attemptCount = 0,
    DateTime? createdAt,
    this.completedAt,
    this.payload,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PrintJob.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseTime(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return PrintJob(
      id: id,
      franchiseId: data['franchiseId'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      clientJobId: data['clientJobId'] as String? ?? '',
      categoryId: data['categoryId'] as String?,
      printerId: data['printerId'] as String?,
      status: data['status'] as String? ?? 'pending',
      errorMessage: data['errorMessage'] as String?,
      attemptCount: data['attemptCount'] as int? ?? 0,
      createdAt: parseTime(data['createdAt']),
      completedAt:
          data['completedAt'] != null ? parseTime(data['completedAt']) : null,
      payload: data['payload'] is Map
          ? Map<String, dynamic>.from(data['payload'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'orderId': orderId,
      'clientJobId': clientJobId,
      if (categoryId != null) 'categoryId': categoryId,
      if (printerId != null) 'printerId': printerId,
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'attemptCount': attemptCount,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (payload != null) 'payload': payload,
    };
  }

  PrintJob copyWith({
    String? id,
    String? franchiseId,
    String? orderId,
    String? clientJobId,
    String? categoryId,
    String? printerId,
    String? status,
    String? errorMessage,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? payload,
  }) {
    return PrintJob(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      orderId: orderId ?? this.orderId,
      clientJobId: clientJobId ?? this.clientJobId,
      categoryId: categoryId ?? this.categoryId,
      printerId: printerId ?? this.printerId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      payload: payload ?? this.payload,
    );
  }

  static const String statusPending = 'pending';
  static const String statusPrinting = 'printing';
  static const String statusPrinted = 'printed';
  static const String statusFailed = 'failed';
}
