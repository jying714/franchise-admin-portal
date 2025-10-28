import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingInterval; // e.g. 'monthly', 'annual'
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
    print('[DEBUG][PlatformPlan.fromMap] Raw data for $id: $data');
    return PlatformPlan(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      billingInterval: data['billingInterval'] ?? 'monthly',
      features: (() {
        if (data['includedFeatures'] is List) {
          return List<String>.from(data['includedFeatures']);
        } else if (data['features'] is List) {
          return List<String>.from(data['features']);
        } else {
          return <String>[];
        }
      })(),
      active: data['active'] ?? false,
      isCustom: data['isCustom'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      planVersion: data['planVersion'] ?? 'v1',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
  }

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

  /// ✅ Derived property: should not be stored
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
