// api_product_repository.dart
import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/product.dart';
import '../product_repository.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._api);
  final ApiClient _api;

  static Product _p(dynamic j) => Product.fromJson(j as Map<String, dynamic>);

  Map<String, dynamic> _body(ProductDraft d) => {
        'name': d.name,
        'category_id': d.categoryId,
        'price': d.price,
        'description': d.description ?? '',
        'is_active': d.isActive,
      };

  @override
  Future<Result<List<Product>>> getProducts() =>
      _api.get(ApiEndpoints.products, (j) => (j as List).map(_p).toList());

  @override
  Future<Result<Product>> create(ProductDraft d) =>
      _api.post(ApiEndpoints.products, _p, body: _body(d));

  @override
  Future<Result<Product>> update(int id, ProductDraft d) =>
      _api.patch(ApiEndpoints.product(id), _p, body: _body(d));

  @override
  Future<Result<Product>> setActive(int id, {required bool active}) =>
      _api.patch(ApiEndpoints.product(id), _p, body: {'is_active': active});

  @override
  Future<Result<void>> delete(int id) => _api.delete(ApiEndpoints.product(id));
}