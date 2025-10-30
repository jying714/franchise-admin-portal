import 'package:cloud_firestore/cloud_firestore.dart';

class SizeTemplate {
  final String id;
  final String label;
  final List<SizeData> sizes;

  SizeTemplate({required this.id, required this.label, required this.sizes});

  factory SizeTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SizeTemplate(
      id: doc.id,
      label: data['label'] ?? '',
      sizes: (data['sizes'] as List<dynamic>)
          .map((size) => SizeData.fromMap(size))
          .toList(),
    );
  }
}

class SizeData {
  final String label;
  final double basePrice;
  final double toppingPrice;

  SizeData({
    required this.label,
    required this.basePrice,
    required this.toppingPrice,
  });

  factory SizeData.fromMap(Map<String, dynamic> map) {
    return SizeData(
      label: map['label'],
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      toppingPrice: (map['toppingPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'basePrice': basePrice,
      'toppingPrice': toppingPrice,
    };
  }

  SizeData copy() {
    return SizeData(
      label: label,
      basePrice: basePrice,
      toppingPrice: toppingPrice,
    );
  }

  SizeData copyWith({
    String? label,
    double? basePrice,
    double? toppingPrice,
  }) {
    return SizeData(
      label: label ?? this.label,
      basePrice: basePrice ?? this.basePrice,
      toppingPrice: toppingPrice ?? this.toppingPrice,
    );
  }
}
