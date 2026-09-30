// api_category_repository.dart
import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/product_category.dart';
import '../category_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._api);
  final ApiClient _api;

  static ProductCategory _c(dynamic j) =>
      ProductCategory.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<ProductCategory>>> getCategories() =>
      _api.get(ApiEndpoints.categories, (j) => (j as List).map(_c).toList());

  @override
  Future<Result<ProductCategory>> create(String name) =>
      _api.post(ApiEndpoints.categories, _c, body: {'name': name.trim()});

  @override
  Future<Result<ProductCategory>> update(int id, String name) =>
      _api.patch(ApiEndpoints.category(id), _c, body: {'name': name.trim()});

  @override
  Future<Result<void>> delete(int id) => _api.delete(ApiEndpoints.category(id));
}