class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final DateTime createdAt;
}
