import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'order.dart' as base_order;
import 'address.dart';

class ScheduledOrder extends base_order.Order {
  final String frequency;
  final DateTime nextDate;
  final DateTime? endDate;
  final bool isPaused;

  ScheduledOrder({
    required String id,
    required String userId,
    required String storeId,
    required List<base_order.OrderItem> items,
    double subtotal = 0.0,
    double tax = 0.0,
    double deliveryFee = 0.0,
    double discount = 0.0,
    double total = 0.0,
    String deliveryType = 'pickup',
    String time = '',
    String status = 'scheduled',
    DateTime? timestamp,
    int estimatedTime = 30,
    Map<String, dynamic> timestamps = const {},
    Address? address,
    String source = 'mobile',
    this.frequency = 'weekly',
    DateTime? nextDate,
    this.endDate,
    this.isPaused = false,
  })  : nextDate = nextDate ?? DateTime.now().add(const Duration(days: 7)),
        super(
          id: id,
          userId: userId,
          storeId: storeId,
          items: items,
          subtotal: subtotal,
          tax: tax,
          deliveryFee: deliveryFee,
          discount: discount,
          total: total,
          deliveryType: deliveryType,
          time: time,
          status: status,
          timestamp: timestamp ?? DateTime.now(),
          estimatedTime: estimatedTime,
          timestamps: timestamps,
          address: address,
          source: source,
        );

  factory ScheduledOrder.fromFirestore(Map<String, dynamic> data, String id) {
    return ScheduledOrder(
      id: id,
      userId: data['userId'] ?? '',
      storeId: data['storeId'] ?? data['franchiseId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) =>
                  base_order.OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      frequency: data['frequency'] ?? 'weekly',
      nextDate: data['nextDate'] is firestore.Timestamp
          ? (data['nextDate'] as firestore.Timestamp).toDate()
          : (data['nextDate'] as DateTime?) ??
              DateTime.now().add(const Duration(days: 7)),
      endDate: data['endDate'] is firestore.Timestamp
          ? (data['endDate'] as firestore.Timestamp).toDate()
          : data['endDate'] as DateTime?,
      isPaused: data['isPaused'] ?? false,
      status: data['status'] ?? 'scheduled',
      timestamp: data['timestamp'] is firestore.Timestamp
          ? (data['timestamp'] as firestore.Timestamp).toDate()
          : DateTime.now(),
      source: (data['source'] as String?)?.trim().isNotEmpty == true
          ? (data['source'] as String).trim()
          : 'mobile',
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final base = super.toFirestore();
    return {
      ...base,
      'frequency': frequency,
      'nextDate': firestore.Timestamp.fromDate(nextDate),
      if (endDate != null) 'endDate': firestore.Timestamp.fromDate(endDate!),
      'isPaused': isPaused,
    };
  }

  @override
  ScheduledOrder copyWith({
    String? id,
    String? userId,
    String? storeId,
    List<base_order.OrderItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? discount,
    double? total,
    String? deliveryType,
    String? time,
    String? status,
    DateTime? timestamp,
    int? estimatedTime,
    Map<String, dynamic>? timestamps,
    Address? address,
    String? userName,
    String? refundStatus,
    Address? deliveryAddress,
    String? specialInstructions,
    String? customerPhone,
    String? source,
    String? frequency,
    DateTime? nextDate,
    DateTime? endDate,
    bool? isPaused,
  }) {
    return ScheduledOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryType: deliveryType ?? this.deliveryType,
      time: time ?? this.time,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      timestamps: timestamps ?? this.timestamps,
      address: address ?? this.address,
      source: source ?? this.source,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      endDate: endDate ?? this.endDate,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
