import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingInterval; // e.g. 'monthly', 'annual'
  final List<String> includedFeatures;
  final bool active;
  final bool isCustom;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlatformPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingInterval,
    required this.includedFeatures,
    required this.active,
    required this.isCustom,
    this.createdAt,
    this.updatedAt,
  });

  factory PlatformPlan.fromMap(String id, Map<String, dynamic> data) {
    return PlatformPlan(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      billingInterval: data['billingInterval'] ?? 'monthly',
      includedFeatures: List<String>.from(data['includedFeatures'] ?? []),
      active: data['active'] ?? false,
      isCustom: data['isCustom'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'billingInterval': billingInterval,
      'includedFeatures': includedFeatures,
      'active': active,
      'isCustom': isCustom,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PlatformPlan copyWith({
    String? name,
    String? description,
    double? price,
    String? currency,
    String? billingInterval,
    List<String>? includedFeatures,
    bool? active,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlatformPlan(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingInterval: billingInterval ?? this.billingInterval,
      includedFeatures: includedFeatures ?? this.includedFeatures,
      active: active ?? this.active,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
