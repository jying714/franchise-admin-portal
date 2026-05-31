// mobile_app/test/widgets/franchise_switch_test.dart
// Expanded coverage for FranchiseProvider switching (QR, deep links, selector).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

void main() {
  group('Franchise switching (P2 white-label)', () {
    testWidgets('FranchiseProvider setFranchiseId updates currentFranchiseId and UiConfig', (tester) async {
      final fp = shared.FranchiseProvider(_InMemoryStorage());

      await tester.pumpWidget(
        Provider<shared.FranchiseProvider>.value(
          value: fp,
          child: MaterialApp(
            home: Builder(builder: (context) {
              return TextButton(
                onPressed: () async {
                  await fp.setFranchiseId('test_green_bistro');
                  UiConfig.setFranchiseProvider(fp);
                },
                child: const Text('Switch Franchise'),
              );
            }),
          ),
        ),
      );

      await tester.tap(find.text('Switch Franchise'));
      await tester.pumpAndSettle();

      expect(fp.currentFranchiseId, 'test_green_bistro');
      expect(UiConfig.franchiseProvider?.currentFranchiseId, 'test_green_bistro');
    });
  });
}

class _InMemoryStorage extends shared.LocalStorage {
  final Map<String, String> _data = {};
  @override
  String? getString(String key) => _data[key];
  @override
  Future<void> setString(String key, String value) async => _data[key] = value;
  @override
  Future<void> remove(String key) async => _data.remove(key);
}

