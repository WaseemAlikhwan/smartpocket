import '../../core/constants/db_constants.dart';
import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconKey,
    required super.colorValue,
    required super.createdAt,
  });

  factory CategoryModel.fromRow(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id']! as String,
      name: map['name']! as String,
      iconKey: map['icon_key']! as String,
      colorValue: map['color_value']! as int,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_key': iconKey,
    'color_value': colorValue,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableCategories;
}
