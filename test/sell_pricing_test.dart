import 'package:flutter_test/flutter_test.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';

SellItemModel createCompleteItem({
  String category = 'Laptop',
  String slug = 'laptop',
  String brand = 'Apple',
  String age = '2 years',
  String condition = 'Working',
  String type = 'MacBook Pro',
  int? basePrice,
}) {
  final item = SellItemModel();
  item.selectedCategoryModel = {
    'name': category,
    'slug': slug,
  };
  if (basePrice != null) {
    item.selectedCategoryModel!['basePrice'] = basePrice;
  }
  item.textValues['brand'] = brand;
  item.textValues['age'] = age;
  item.dropdownValues['condition'] = condition;
  item.textValues['type'] = type;
  return item;
}

void main() {
  group('SellItemModel Estimated Price Tests', () {
    test('Returns 0 when category is not selected', () {
      final item = SellItemModel();
      expect(item.hasAllDetails, isFalse);
      expect(item.estimatedPrice, equals(0));
      expect(item.estimatedPriceRange, equals('—'));
    });

    test('Returns 0 and "—" when details are not completely filled', () {
      final item = SellItemModel();
      item.selectedCategoryModel = {'name': 'Laptop', 'slug': 'laptop'};
      // Only category selected, no brand/age/condition/type
      expect(item.hasAllDetails, isFalse);
      expect(item.estimatedPrice, equals(0));
      expect(item.estimatedPriceRange, equals('—'));

      // Fill brand only
      item.textValues['brand'] = 'Apple';
      expect(item.hasAllDetails, isFalse);
      expect(item.estimatedPrice, equals(0));

      // Fill age
      item.textValues['age'] = '1 year';
      expect(item.hasAllDetails, isFalse);
      expect(item.estimatedPrice, equals(0));

      // Fill condition
      item.dropdownValues['condition'] = 'Working';
      expect(item.hasAllDetails, isFalse);
      expect(item.estimatedPrice, equals(0));

      // Fill type -> NOW all details are filled!
      item.textValues['type'] = 'MacBook Pro';
      expect(item.hasAllDetails, isTrue);
      expect(item.estimatedPrice, equals(8500));
      expect(item.estimatedPriceRange, isNot(equals('—')));
    });

    test('Calculates base price for Laptop (8500) after filling all details', () {
      final item = createCompleteItem(category: 'Laptop', slug: 'laptop', age: '1 year', condition: 'Working');
      expect(item.estimatedPrice, equals(8500));
    });

    test('Calculates base price for Mobile (3500) after filling all details', () {
      final item = createCompleteItem(category: 'Mobile', slug: 'mobile', age: '1 year', condition: 'Working');
      expect(item.estimatedPrice, equals(3500));
    });

    test('Calculates base price for AC (4500) after filling all details', () {
      final item = createCompleteItem(category: 'AC', slug: 'ac', age: '1 year', condition: 'Working');
      expect(item.estimatedPrice, equals(4500));
    });

    test('Applies Condition multipliers correctly for API options', () {
      // Working: 1.0x -> 8500
      final itemWorking = createCompleteItem(condition: 'Working', age: '1-2 years');
      expect(itemWorking.estimatedPrice, equals(8500));

      // Partially Working: 0.70x -> 8500 * 0.7 = 5950
      final itemPartial = createCompleteItem(condition: 'Partially Working', age: '1-2 years');
      expect(itemPartial.estimatedPrice, equals(5950));

      // Not Working: 0.40x -> 8500 * 0.4 = 3400
      final itemNotWorking = createCompleteItem(condition: 'Not Working', age: '1-2 years');
      expect(itemNotWorking.estimatedPrice, equals(3400));
    });

    test('Applies Condition multipliers for conventional ratings (Excellent, Poor)', () {
      // Excellent: 1.20x -> 3500 * 1.2 = 4200
      final itemExc = createCompleteItem(category: 'Mobile', slug: 'mobile', condition: 'Excellent', age: '1 year');
      expect(itemExc.estimatedPrice, equals(4200));

      // Poor: 0.40x -> 3500 * 0.4 = 1400
      final itemPoor = createCompleteItem(category: 'Mobile', slug: 'mobile', condition: 'Poor', age: '1 year');
      expect(itemPoor.estimatedPrice, equals(1400));

      // Fair: 0.70x -> 3500 * 0.7 = 2450
      final itemFair = createCompleteItem(category: 'Mobile', slug: 'mobile', condition: 'Fair', age: '1 year');
      expect(itemFair.estimatedPrice, equals(2450));
    });

    test('Applies Age multipliers for numeric inputs', () {
      // < 1 year: 1.15x -> 8500 * 1.15 = 9775
      expect(createCompleteItem(age: '0.5').estimatedPrice, equals(9775));

      // 1-2 years: 1.00x -> 8500
      expect(createCompleteItem(age: '1.5').estimatedPrice, equals(8500));

      // 2-3 years: 0.85x -> 8500 * 0.85 = 7225
      expect(createCompleteItem(age: '2.5').estimatedPrice, equals(7225));

      // 3-5 years: 0.65x -> 8500 * 0.65 = 5525
      expect(createCompleteItem(age: '4').estimatedPrice, equals(5525));

      // > 5 years: 0.40x -> 8500 * 0.4 = 3400
      expect(createCompleteItem(age: '6').estimatedPrice, equals(3400));
    });

    test('Applies Age multipliers for month and text range inputs', () {
      // 6 months -> 1.25x -> 3500 * 1.25 = 4375
      expect(createCompleteItem(category: 'Mobile', slug: 'mobile', age: '6 months').estimatedPrice, equals(4375));

      // Under 1 year -> 1.15x -> 3500 * 1.15 = 4025
      expect(createCompleteItem(category: 'Mobile', slug: 'mobile', age: '< 1 year').estimatedPrice, equals(4025));

      // 1 - 2 years -> 1.00x -> 3500
      expect(createCompleteItem(category: 'Mobile', slug: 'mobile', age: '1 - 2 years').estimatedPrice, equals(3500));

      // 2 - 3 years -> 0.85x -> 3500 * 0.85 = 2975
      expect(createCompleteItem(category: 'Mobile', slug: 'mobile', age: '2 - 3 years').estimatedPrice, equals(2975));

      // 3 - 5 years -> 0.65x -> 3500 * 0.65 = 2275
      expect(createCompleteItem(category: 'Mobile', slug: 'mobile', age: '3 - 5 years').estimatedPrice, equals(2275));

      // 5+ years -> 0.40x -> 3500 * 0.4 = 1400
      expect(createCompleteItem(category: 'Mobile', slug: 'mobile', age: '5+ years').estimatedPrice, equals(1400));
    });

    test('Combines both Age and Condition multipliers', () {
      // Laptop, 5+ years (0.40), Not Working (0.40) -> 8500 * 0.4 * 0.4 = 1360
      final itemOldBroken = createCompleteItem(age: '5+ years', condition: 'Not Working');
      expect(itemOldBroken.estimatedPrice, equals(1360));

      // Laptop, < 1 year (1.15), Excellent (1.20) -> 8500 * 1.15 * 1.20 = 11730
      final itemNewExc = createCompleteItem(age: '< 1 year', condition: 'Excellent');
      expect(itemNewExc.estimatedPrice, equals(11730));

      // Check estimatedPriceRange format
      expect(itemNewExc.estimatedPriceRange, contains('₹'));
      expect(itemNewExc.estimatedPriceRange, contains('–'));
    });

    test('Enforces safety floor of ₹200', () {
      final item = createCompleteItem(category: 'Old Accessory', slug: 'other', basePrice: 100, age: '10 years', condition: 'Dead / Scrap');
      expect(item.estimatedPrice, greaterThanOrEqualTo(200));
    });

    test('SellRequestModel aggregates total correctly and hides price when incomplete', () {
      final request = SellRequestModel();

      // currentItem without all details -> estimatedPrice is 0
      request.currentItem.selectedCategoryModel = {'name': 'Laptop', 'slug': 'laptop'};
      expect(request.estimatedPrice, equals(0));
      expect(request.totalEstimatedPriceRange, equals('—'));

      // Add completed items to items list
      final item1 = createCompleteItem(category: 'Laptop', slug: 'laptop', age: '1 year', condition: 'Working'); // 8500
      request.items.add(item1);

      final item2 = createCompleteItem(category: 'Mobile', slug: 'mobile', age: '2 - 3 years', condition: 'Working'); // 2975
      request.items.add(item2);

      // currentItem is incomplete, so total is item1 + item2 = 8500 + 2975 = 11475
      expect(request.estimatedPrice, equals(11475));
      expect(request.totalEstimatedPriceRange, contains('₹'));
    });
  });
}
