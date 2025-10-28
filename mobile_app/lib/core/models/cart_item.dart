import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single item in the user's cart.
/// Mirrors fields stored in Firestore under `cart/{userId}` documents.
class CartItem {
  /// The display name of the item (e.g., "Meat Lovers Pizza").
  final String name;

  /// Price per unit of the item.
  final double price;

  /// Quantity the user has added to the cart.
  final int quantity;

  /// Customizations: toppings, addOns, sauces, comboSignature, etc.
  /// Structure:
  /// {
  ///   "toppings": List<String>,
  ///   "addOns": List<Map<String, dynamic>> (with {name, price}),
  ///   "comboSignature": String (optional, for analytics),
  ///   ...other fields as needed
  /// }
  final Map<String, dynamic> customizations;

  /// Optional URL to an image for the item.
  final String? image;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.customizations,
    this.image,
  });

  /// Constructs a CartItem from a Firestore map (e.g., a nested `items` array entry).
  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] as int? ?? 1,
      customizations: data['customizations'] != null
          ? Map<String, dynamic>.from(data['customizations'] as Map)
          : <String, dynamic>{},
      image: data['image'] as String?,
    );
  }

  /// Serializes this CartItem into a map suitable for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'customizations': customizations,
      'image': image,
    };
  }

  /// Optional convenience: build directly from a DocumentSnapshot.
  factory CartItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CartItem.fromMap(data);
  }

  /// Example: get toppings list (null if not present)
  List<String> get toppings =>
      (customizations['toppings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  /// Example: get addOns list (null if not present)
  List<Map<String, dynamic>> get addOns =>
      (customizations['addOns'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  /// Example: combo signature for analytics
  String? get comboSignature => customizations['comboSignature'] as String?;
}
