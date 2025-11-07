// packages/shared_core/lib/src/core/models/platform_plan.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingInterval;
  final List<String> features;
  final bool active;
  final bool isCustom;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? planVersion;

  PlatformPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingInterval,
    required this.features,
    required this.active,
    required this.isCustom,
    this.createdAt,
    this.updatedAt,
    this.planVersion,
  });

  factory PlatformPlan.fromMap(String id, Map<String, dynamic> data) {
    return PlatformPlan(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      billingInterval: data['billingInterval'] as String? ?? 'monthly',
      features: _parseFeatures(data),
      active: data['active'] as bool? ?? false,
      isCustom: data['isCustom'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      planVersion: data['planVersion'] as String? ?? 'v1',
    );
  }

  static List<String> _parseFeatures(Map<String, dynamic> data) {
    final raw = data['includedFeatures'] ?? data['features'];
    if (raw is List) {
      return raw.cast<String>();
    }
    return <String>[];
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'billingInterval': billingInterval,
        'features': features,
        'active': active,
        'isCustom': isCustom,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'planVersion': planVersion ?? 'v1',
      };

  PlatformPlan copyWith({
    String? name,
    String? description,
    double? price,
    String? currency,
    String? billingInterval,
    List<String>? features,
    bool? active,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? planVersion,
  }) {
    return PlatformPlan(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingInterval: billingInterval ?? this.billingInterval,
      features: features ?? this.features,
      active: active ?? this.active,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      planVersion: planVersion ?? this.planVersion,
    );
  }

  factory PlatformPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlatformPlan.fromMap(doc.id, data);
  }

  bool get requiresPayment => !isCustom && price > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
