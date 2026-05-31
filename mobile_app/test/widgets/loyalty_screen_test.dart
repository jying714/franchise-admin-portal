// mobile_app/test/widgets/loyalty_screen_test.dart
// P2.3 basic widget test foundation for loyalty screen (points, rewards).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:franchise_mobile_app/features/loyalty/loyalty_screen.dart';

void main() {
  group('LoyaltyScreen (P2.3 critical flow - foundation)', () {
    testWidgets('test file structure and basic pump works (smoke)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoyaltyScreen()),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.byType(LoyaltyScreen), findsOneWidget);
    });
  });
}
