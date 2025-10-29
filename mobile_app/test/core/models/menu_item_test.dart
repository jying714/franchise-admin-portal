import 'package:flutter_test/flutter_test.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';

void main() {
  group('MenuItem Model', () {
    test('fromMap correctly parses customizationGroups', () {
      final Map<String, dynamic> data = {
        'id': 'item123',
        'name': 'Deluxe Sub',
        'category': 'subs',
        'categoryId': 'Subs',
        'price': {'Regular': 7.5},
        'availability': true,
        'description': 'A tasty sub.',
        'taxCategory': 'food',
        'customizationGroups': [
          {
            'label': 'Bread',
            'ingredientIds': ['white', 'wheat']
          },
          {
            'label': 'Cheese',
            'ingredientIds': ['cheddar', 'swiss']
          }
        ],
      };

      final item = MenuItem.fromMap(data);
      expect(item.id, 'item123');
      expect(item.customizationGroups, isNotNull);
      expect(item.customizationGroups!.length, 2);
      expect(item.customizationGroups![0]['label'], 'Bread');
    });

    test('toJson includes customizationGroups', () {
      final item = MenuItem(
        id: 'item456',
        name: 'Veggie Sub',
        category: 'subs',
        categoryId: 'Subs',
        price: 6.5,
        availability: true,
        description: 'Delicious veggie delight.',
        taxCategory: 'food',
        customizationGroups: [
          {
            'label': 'Sauce',
            'ingredientIds': ['ranch', 'bbq']
          }
        ],
      );

      final json = item.toJson();
      expect(json['customizationGroups'], isNotNull);
      expect(json['customizationGroups'][0]['label'], 'Sauce');
    });

    test('copyWith can update customizationGroups', () {
      final original = MenuItem(
        id: 'item789',
        name: 'Basic Sub',
        category: 'subs',
        categoryId: 'Subs',
        price: 6.5,
        availability: true,
        description: 'Simple and tasty.',
        taxCategory: 'food',
      );

      final updated = original.copyWith(customizationGroups: [
        {
          'label': 'Toppings',
          'ingredientIds': ['lettuce', 'tomato']
        }
      ]);

      expect(updated.customizationGroups, isNotNull);
      expect(updated.customizationGroups![0]['label'], 'Toppings');
    });
  });
}
