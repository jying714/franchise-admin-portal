import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/models/restaurant_type.dart';

class RestaurantTypeProvider with ChangeNotifier {
  List<RestaurantType> _types = [];
  List<RestaurantType> get types => _types;

  Future<void> loadTypes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('restaurant_types').get();
    _types =
        snapshot.docs.map((doc) => RestaurantType.fromFirestore(doc)).toList();
    notifyListeners();
  }
}
