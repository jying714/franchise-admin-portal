// lib/core/utils/schema_templates.dart

const List<Map<String, dynamic>> pizzaShopIngredientMetadataTemplate = [
  {
    "id": "cheese_mozzarella",
    "name": "Mozzarella",
    "typeId": "cheese",
    "type": "Cheese",
    "allergens": ["dairy"],
    "removable": true,
    "supportsExtra": true,
    "sidesAllowed": false,
    "notes": "Classic mozzarella cheese",
    "outOfStock": false,
    "imageUrl": null,
    "amountSelectable": true,
    "amountOptions": ["Light", "Regular", "Extra"]
  },
  {
    "id": "meat_pepperoni",
    "name": "Pepperoni",
    "typeId": "meat",
    "type": "Meat",
    "allergens": [],
    "removable": true,
    "supportsExtra": true,
    "sidesAllowed": true,
    "notes": "Spicy pepperoni slices",
    "outOfStock": false,
    "imageUrl": null,
    "amountSelectable": true,
    "amountOptions": ["Light", "Regular", "Extra"]
  },
  // Add more ingredient metadata entries here...
];

const List<Map<String, dynamic>> pizzaShopIngredientTypesTemplate = [
  {
    "name": "Cheese",
    "description": "All cheese types used in pizzas and other items.",
    "sortOrder": 1,
    "systemTag": "cheese",
    "visibleInApp": true,
  },
  {
    "name": "Sauce",
    "description": "Various pizza sauces.",
    "sortOrder": 2,
    "systemTag": "sauce",
    "visibleInApp": true,
  },
  {
    "name": "Meat",
    "description": "Meat toppings including pepperoni, sausage, etc.",
    "sortOrder": 3,
    "systemTag": "meat",
    "visibleInApp": true,
  },
  {
    "name": "Veggies",
    "description": "Vegetable toppings such as onions, peppers, mushrooms.",
    "sortOrder": 4,
    "systemTag": "vegetable",
    "visibleInApp": true,
  },
  {
    "name": "Specialty",
    "description": "Specialty or unique ingredient types.",
    "sortOrder": 5,
    "systemTag": "specialty",
    "visibleInApp": true,
  },
  // Add more ingredient type entries as needed...
];

const List<Map<String, dynamic>> pizzaShopCategoriesTemplate = [
  {
    "id": "pizza",
    "name": "Pizza",
    "description":
        "Our signature pizzas including build-your-own and specialties.",
    "sortOrder": 0
  },
  {
    "id": "calzones",
    "name": "Calzones",
    "description": "Stuffed calzones with various fillings.",
    "sortOrder": 1
  },
  {
    "id": "salads",
    "name": "Salads",
    "description": "Fresh salads with a variety of toppings and dressings.",
    "sortOrder": 2
  },
  {
    "id": "drinks",
    "name": "Drinks",
    "description": "Fountain drinks, bottled beverages, and more.",
    "sortOrder": 3
  },
  {
    "id": "desserts",
    "name": "Desserts",
    "description": "Sweet treats to complete your meal.",
    "sortOrder": 4
  },
];
