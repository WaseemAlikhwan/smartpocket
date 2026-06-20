class DefaultCategorySeed {
  const DefaultCategorySeed({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
}

const defaultCategories = <DefaultCategorySeed>[
  DefaultCategorySeed(
    id: 'cat_seed_insurance',
    name: 'التأمينات',
    iconKey: 'shield',
    colorValue: 0xFF143D59,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_shopping',
    name: 'التسوق',
    iconKey: 'shopping_bag',
    colorValue: 0xFF0F4C75,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_accessories',
    name: 'اكسسوارات',
    iconKey: 'diamond',
    colorValue: 0xFFE67E22,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_clothes',
    name: 'ملابس',
    iconKey: 'checkroom',
    colorValue: 0xFFF4C542,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_electronics',
    name: 'الكترونيات',
    iconKey: 'phone_android',
    colorValue: 0xFFE67E22,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_shoes',
    name: 'أحذية',
    iconKey: 'hiking',
    colorValue: 0xFF16A085,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_travel',
    name: 'السفر',
    iconKey: 'flight',
    colorValue: 0xFF1F3A5F,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_cash_withdraw',
    name: 'السحب النقدي',
    iconKey: 'atm',
    colorValue: 0xFFDD6B4D,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_food',
    name: 'طعام',
    iconKey: 'restaurant',
    colorValue: 0xFFE53935,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_transport',
    name: 'مواصلات',
    iconKey: 'directions_car',
    colorValue: 0xFF1E88E5,
  ),
  DefaultCategorySeed(
    id: 'cat_seed_other',
    name: 'أخرى',
    iconKey: 'category',
    colorValue: 0xFF34495E,
  ),
];
