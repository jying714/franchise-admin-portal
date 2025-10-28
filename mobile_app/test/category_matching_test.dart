// File: test/category_matching_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category–Firestore consistency checks', () {
    late Map<String, dynamic> rawJson;
    late Map<String, dynamic> menuItems;

    setUpAll(() async {
      // 1. Adjust this path if your dump is somewhere else:
      final dumpFile = File('test_resources/doughboyspizzeria_dump.json');
      if (!await dumpFile.exists()) {
        fail('Cannot find test_resources/doughboyspizzeria_dump.json');
      }

      rawJson =
          jsonDecode(await dumpFile.readAsString()) as Map<String, dynamic>;

      if (!rawJson.containsKey('menu_items')) {
        fail('The JSON file does not contain a top‑level "menu_items" key.');
      }
      menuItems = rawJson['menu_items'] as Map<String, dynamic>;
    });

    test('“pizza” exists but “pizzas” does not', () {
      final allCategories = menuItems.values
          .map((doc) => (doc as Map<String, dynamic>)['category'] as String?)
          .whereType<String>()
          .toList();

      final hasPizza = allCategories.contains('pizza');
      final hasPizzas = allCategories.contains('pizzas');

      expect(
        hasPizza,
        isTrue,
        reason:
            'Expected at least one menu_items document with category == "pizza". Found none. '
            'Distinct categories: ${allCategories.toSet()}',
      );

      expect(
        hasPizzas,
        isFalse,
        reason:
            'Found one or more menu_items documents with category == "pizzas". '
            'Distinct categories: ${allCategories.toSet()}',
      );
    });

    test('“calzones” exists but “calzone” does not', () {
      final allCategories = menuItems.values
          .map((doc) => (doc as Map<String, dynamic>)['category'] as String?)
          .whereType<String>()
          .toList();

      final hasCalzones = allCategories.contains('calzones');
      final hasCalzone = allCategories.contains('calzone');

      expect(
        hasCalzones,
        isTrue,
        reason:
            'Expected at least one menu_items document with category == "calzones". Found none. '
            'Distinct categories: ${allCategories.toSet()}',
      );

      expect(
        hasCalzone,
        isFalse,
        reason:
            'Found one or more menu_items documents with category == "calzone". '
            'Distinct categories: ${allCategories.toSet()}',
      );
    });

    test('Print all distinct category values for manual inspection', () {
      final distinct = <String>{};
      for (var doc in menuItems.values) {
        final cat = (doc as Map<String, dynamic>)['category'];
        if (cat is String) distinct.add(cat);
      }

      // Prints to the test log so you can verify in VS Code
      //print('\n>>> Distinct category values in menu_items: $distinct\n');

      // Basic sanity: "pizza" and "calzones" should appear
      expect(
        distinct.contains('pizza'),
        isTrue,
        reason:
            'menu_items["category"] should include "pizza". Found: $distinct',
      );
      expect(
        distinct.contains('calzones'),
        isTrue,
        reason:
            'menu_items["category"] should include "calzones". Found: $distinct',
      );
    });
  });
}
