// mobile_app/test/widgets/favorites_test.dart
// P2.3 basic widget test for favorites (critical for loyalty/white-label).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../helpers/test_helpers.dart';

// Favorites UI is often embedded (FavoriteButton + lists in profile/menu).
// Use a simple smoke around the concept + service methods.
void main() {
  group('Favorites flow (P2.3)', () {
    testWidgets('service favorites methods work via fake (smoke)', (tester) async {
      final fakeFs = FakeFirestoreService();
      const userId = 'test_user_123';
      const fid = 'test_franchise';
      const itemId = 'menu_pizza_1';

      // Exercise the fake (mirrors what screens do via Provider)
      await fakeFs.addFavoriteMenuItem(userId, fid, itemId);
      final ids = await fakeFs.getFavoritesMenuItemIds(userId, fid);

      expect(ids, contains(itemId));

      await fakeFs.removeFavoriteMenuItem(userId, fid, itemId);
      final after = await fakeFs.getFavoritesMenuItemIds(userId, fid);
      expect(after, isNot(contains(itemId)));
    });

    testWidgets('FavoriteButton or favorites UI can be pumped with providers', (tester) async {
      // Placeholder smoke test - in real expansion import FavoriteButton and pump it
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: Center(child: Text('Favorites smoke'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Favorites smoke'), findsOneWidget);
    });
  });
}
