// mobile_app/test/helpers/test_helpers.dart
// P2.3 testing foundations: common test wrappers and mocks for shared services.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

/// Simple in-memory fake FirestoreService for widget tests.
/// Extend as needed for cart/favorites/loyalty flows.
class FakeFirestoreService implements shared.FirestoreService {
  final Map<String, List<shared.OrderItem>> _carts = {};
  final Map<String, List<String>> _favorites = {};

  @override
  String? get currentUserId => 'test_user_123';

  @override
  Future<void> addToCart(shared.OrderItem item, String userId) async {
    _carts.putIfAbsent(userId, () => []).add(item);
  }

  @override
  Future<shared.Cart> getCart(String userId, {String? franchiseId}) async {
    final items = _carts[userId] ?? [];
    return shared.Cart(
      id: 'test_cart',
      userId: userId,
      items: items,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> updateCart(shared.Cart cart) async {
    _carts[cart.userId] = cart.items;
  }

  @override
  Stream<List<String>> favoritesMenuItemIdsStream(String userId, String franchiseId) {
    return Stream.value(_favorites[userId] ?? []);
  }

  @override
  Future<List<String>> getFavoritesMenuItemIds(String userId, String franchiseId) async {
    return _favorites[userId] ?? [];
  }

  @override
  Future<void> addFavoriteMenuItem(String userId, String franchiseId, String menuItemId) async {
    _favorites.putIfAbsent(userId, () => []).add(menuItemId);
  }

  @override
  Future<void> removeFavoriteMenuItem(String userId, String franchiseId, String menuItemId) async {
    _favorites[userId]?.remove(menuItemId);
  }

  @override
  Future<Map<String, dynamic>?> getLoyaltyForUser(String userId, {String? franchiseId}) async => {'points': 0};

  @override
  Future<void> setLoyaltyForUser(String userId, Map<String, dynamic> loyalty, {String? franchiseId}) async {}

  @override
  Future<List<shared.Order>> getOrders({String? userId, String? franchiseId}) async => [];

  @override
  Stream<List<shared.Order>> getOrdersForUser(String userId, {String? franchiseId, int limit = 20}) => Stream.value([]);

  @override
  Future<bool> hasOrderFeedback(String orderId, {String? franchiseId}) async => false;

  @override
  Stream<List<shared.Banner>> getBanners({String? franchiseId}) => Stream.value([]);
}

  // Provide safe defaults for the large surface area of FirestoreService so basic widget pumps don't explode.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final member = invocation.memberName.toString();
    if (member.contains('Stream')) return Stream.value([]);
    if (member.contains('get') || member.contains('fetch')) return Future.value([]);
    if (member.contains('add') || member.contains('update') || member.contains('set') || member.contains('delete')) return Future.value();
    if (member.contains('has')) return Future.value(false);
    return null;
  }
}

/// Wraps a widget with the minimal providers needed for most customer screens (Franchise + Firestore + UiConfig).
Widget createTestApp({
  required Widget child,
  shared.FirestoreService? firestoreService,
  String franchiseId = 'test_franchise',
}) {
  final fp = shared.FranchiseProvider(shared.LocalStorage()); // in-memory for tests
  fp.setInitialFranchiseId(franchiseId); // sync set for test

  final fs = firestoreService ?? FakeFirestoreService();

  // Wire UiConfig for the test (P2 white-label pattern)
  UiConfig.setFranchiseProvider(fp);

  return MultiProvider(
    providers: [
      Provider<shared.FranchiseProvider>.value(value: fp),
      Provider<shared.FirestoreService>.value(value: fs),
      // Add other providers (Language etc.) as tests grow
    ],
    child: MaterialApp(
      home: child,
      theme: ThemeData(
        primaryColor: UiConfig.primaryColor,
        scaffoldBackgroundColor: UiConfig.backgroundColorDark,
      ),
    ),
  );
}
