import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAll();
  Future<void> upsert(CategoryEntity entity);
  Future<void> delete(String id);
}
