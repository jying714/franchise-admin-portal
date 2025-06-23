import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory {
  final String id;
  final String name;
  final String sku; // Stock Keeping Unit
  final double stock; // The actual count in inventory
  final double threshold; // Low-stock warning threshold
  final String unitType; // e.g., "lbs", "pieces"
  final DateTime lastUpdated;
  final double quantity; // For legacy/alias compatibility—mirrors stock
  final bool available; // True if in stock or as logic requires

  Inventory({
    required this.id,
    required this.name,
    required this.sku,
    required this.stock,
    required this.threshold,
    required this.unitType,
    required this.lastUpdated,
    double? quantity, // Defaults to stock for compatibility
    bool? available, // Defaults to (stock > 0)
  })  : quantity = quantity ?? stock,
        available = available ?? (stock > 0);

  /// Factory constructor from Firestore data (map + doc ID)
  factory Inventory.fromFirestore(Map<String, dynamic> data, String id) {
    final stockVal = (data['stock'] ?? 0.0);
    final double parsedStock =
        stockVal is int ? stockVal.toDouble() : (stockVal as num).toDouble();

    return Inventory(
      id: id,
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      stock: parsedStock,
      threshold: (data['threshold'] ?? 0.0).toDouble(),
      unitType: data['unitType'] ?? '',
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      quantity: (data['quantity'] ?? parsedStock).toDouble(),
      available: data['available'] ?? (parsedStock > 0),
    );
  }

  /// For Firestore updates/writes
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sku': sku,
      'stock': stock,
      'threshold': threshold,
      'unitType': unitType,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'quantity': quantity,
      'available': available,
    };
  }

  /// For easy, immutable state updates
  Inventory copyWith({
    String? id,
    String? name,
    String? sku,
    double? stock,
    double? threshold,
    String? unitType,
    DateTime? lastUpdated,
    double? quantity,
    bool? available,
  }) {
    final double stockVal = stock ?? this.stock;
    return Inventory(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      stock: stockVal,
      threshold: threshold ?? this.threshold,
      unitType: unitType ?? this.unitType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      quantity: quantity ?? stockVal,
      available: available ?? (stockVal > 0),
    );
  }
}
