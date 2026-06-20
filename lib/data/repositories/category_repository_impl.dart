import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._local);

  final CategoryLocalDataSource _local;

  CategoryModel _asModel(CategoryEntity e) => CategoryModel(
    id: e.id,
    name: e.name,
    iconKey: e.iconKey,
    colorValue: e.colorValue,
    createdAt: e.createdAt,
  );

  @override
  Future<List<CategoryEntity>> getAll() => _local.getAll();

  @override
  Future<void> upsert(CategoryEntity entity) => _local.insertOrReplace(_asModel(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);
}
