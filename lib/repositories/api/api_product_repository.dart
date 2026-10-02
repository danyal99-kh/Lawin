// api_product_repository.dart
import 'dart:io';

import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/product.dart';
import '../product_repository.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._api);
  final ApiClient _api;

  static Product _p(dynamic j) => Product.fromJson(j as Map<String, dynamic>);

  Map<String, String> _fields(ProductDraft d) => {
        'name': d.name,
        'category_id': d.categoryId.toString(),
        'price': d.price.toString(),
        'description': d.description ?? '',
        'is_active': d.isActive.toString(),
      };

  @override
  Future<Result<List<Product>>> getProducts() =>
      _api.get(ApiEndpoints.products, (j) => (j as List).map(_p).toList());

  @override
  Future<Result<Product>> create(ProductDraft d, {File? image}) =>
      _api.multipartRequest(
        'POST',
        ApiEndpoints.products,
        _p,
        fields: _fields(d),
        files: image != null ? {'image': image} : null,
      );

  @override
  Future<Result<Product>> update(int id, ProductDraft d, {File? image}) =>
      _api.multipartRequest(
        'PATCH',
        ApiEndpoints.product(id),
        _p,
        fields: _fields(d),
        files: image != null ? {'image': image} : null,
      );

  @override
  Future<Result<Product>> setActive(int id, {required bool active}) =>
      _api.patch(ApiEndpoints.product(id), _p, body: {'is_active': active});

  @override
  Future<Result<void>> delete(int id) => _api.delete(ApiEndpoints.product(id));
}