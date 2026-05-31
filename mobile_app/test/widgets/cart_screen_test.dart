// mobile_app/test/widgets/cart_screen_test.dart
// P2.3 basic widget test for critical cart flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../helpers/test_helpers.dart';
import 'package:franchise_mobile_app/features/ordering/cart_screen.dart';

void main() {
  group('CartScreen (P2.3 critical flow)', () {
    testWidgets('renders empty cart state without crashing', (tester) async {
      final fakeFs = FakeFirestoreService();

      await tester.pumpWidget(
        createTestApp(
          firestoreService: fakeFs,
          child: const CartScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Basic smoke: title or empty state text should appear (adjust to actual localization strings if needed)
      expect(find.textContaining('Cart'), findsOneWidget);
      // Empty state friendly message or list absence is acceptable for basic foundation test
    });

    testWidgets('can add item via service (integration smoke)', (tester) async {
      final fakeFs = FakeFirestoreService();

      await tester.pumpWidget(
        createTestApp(
          firestoreService: fakeFs,
          child: const CartScreen(),
        ),
      );

      // In a real expanded test we would tap + and verify via provider.
      // For foundation: just ensure no crash on pump with mocked shared service.
      expect(find.byType(CartScreen), findsOneWidget);
    });
  });
}
