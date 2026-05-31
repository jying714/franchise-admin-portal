// mobile_app/test/widgets/loyalty_screen_test.dart
// P2.3 basic widget test foundation for loyalty screen (points, rewards).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../helpers/test_helpers.dart';
import 'package:franchise_mobile_app/features/loyalty/loyalty_screen.dart';

void main() {
  group('LoyaltyScreen (P2.3 critical flow)', () {
    testWidgets('renders without crashing with mocked shared service', (tester) async {
      final fakeFs = FakeFirestoreService();

      await tester.pumpWidget(
        createTestApp(
          firestoreService: fakeFs,
          child: const LoyaltyScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Loyalty screen typically shows points / rewards UI
      expect(find.byType(LoyaltyScreen), findsOneWidget);
      // Expand later with specific text like "Loyalty Points", "Redeem" etc. once strings stabilized
    });

    testWidgets('loyalty data flows through service (smoke)', (tester) async {
      final fakeFs = FakeFirestoreService();
      // In expanded tests: call setLoyaltyForUser / getLoyaltyForUser and verify UI reflects
      const loyaltyData = {'points': 1250, 'tier': 'Gold'};

      // Currently the fake doesn't fully implement loyalty; this documents the intent
      // and exercises Provider wiring.
      await tester.pumpWidget(
        createTestApp(
          firestoreService: fakeFs,
          child: const LoyaltyScreen(),
        ),
      );

      expect(find.byType(LoyaltyScreen), findsOneWidget);
    });
  });
}
