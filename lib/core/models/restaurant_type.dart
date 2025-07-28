import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantType {
  final String id;
  final String name;

  RestaurantType({required this.id, required this.name});

  factory RestaurantType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantType(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}
