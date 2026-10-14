import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/offer.dart';
import '../offer_repository.dart';

class ApiOfferRepository implements OfferRepository {
  ApiOfferRepository(this._api);

  final ApiClient _api;

  static Offer _one(dynamic j) => Offer.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<Offer>>> getOffers({
    int? productId,
    int? categoryId,
    bool? activeOnly,
  }) =>
      _api.get(
        ApiEndpoints.offers,
        (j) => (j as List).map(_one).toList(),
        query: {
          if (productId != null) 'product': '$productId',
          if (categoryId != null) 'category': '$categoryId',
          if (activeOnly != null) 'active': activeOnly ? '1' : '0',
        },
      );

  @override
  Future<Result<OfferPreview>> preview(OfferRequest request) => _api.post(
        ApiEndpoints.offersPreview,
        (j) => OfferPreview.fromJson(j as Map<String, dynamic>),
        body: request.toJson(),
      );

  @override
  Future<Result<Offer>> activate(
    OfferRequest request, {
    required String fingerprint,
    String? idempotencyKey,
  }) =>
      _api.post(
        ApiEndpoints.offersCreate,
        _one,
        body: {
          ...request.toJson(),
          'fingerprint': fingerprint,
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        },
      );

  @override
  Future<Result<Offer>> deactivate(int id) =>
      _api.post(ApiEndpoints.offerDeactivate(id), _one);
}
