import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  late Map<String, dynamic> dump;

  setUpAll(() async {
    final file = File('test_resources/doughboyspizzeria_dump.json');
    final content = await file.readAsString();
    dump = json.decode(content) as Map<String, dynamic>;
  });

  test('Distinct menu item categories include pizza and calzones', () {
    final menuItems = dump['menu_items'] as Map<String, dynamic>;
    final categories = menuItems.values
        .map((e) => (e['category'] as String).toLowerCase().trim())
        .toSet();
    expect(categories.contains('pizza'), isTrue, reason: '“pizza” not found');
    expect(categories.contains('calzones'), isTrue,
        reason: '“calzones” not found');
  });

  test('Filtering menu_items by category “pizza” yields results', () {
    final menuItems = dump['menu_items'] as Map<String, dynamic>;
    final pizzaItems = menuItems.values.where((e) {
      return (e['category'] as String).toLowerCase().trim() == 'pizza';
    }).toList();
    expect(pizzaItems.isNotEmpty, isTrue, reason: 'No “pizza” items');
  });

  test('Filtering menu_items by category “calzones” yields results', () {
    final menuItems = dump['menu_items'] as Map<String, dynamic>;
    final calzoneItems = menuItems.values.where((e) {
      return (e['category'] as String).toLowerCase().trim() == 'calzones';
    }).toList();
    expect(calzoneItems.isNotEmpty, isTrue, reason: 'No “calzones” items');
  });

  test('Every menu_item category matches a valid category document ID', () {
    final categoriesMap = dump['categories'] as Map<String, dynamic>;
    final validCategoryIds =
        categoriesMap.keys.map((id) => id.toLowerCase().trim()).toSet();

    final menuItems = dump['menu_items'] as Map<String, dynamic>;
    final menuItemCategories = menuItems.values
        .map((e) => (e['category'] as String).toLowerCase().trim())
        .toSet();

    final invalid = menuItemCategories.difference(validCategoryIds);
    expect(invalid.isEmpty, isTrue,
        reason:
            'Found menu_item categories not matching any category ID: $invalid');
  });
}
