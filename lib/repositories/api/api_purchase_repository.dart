import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/purchase.dart';
import '../purchase_repository.dart';

class ApiPurchaseRepository implements PurchaseRepository {
  ApiPurchaseRepository(this._api);
  final ApiClient _api;

  static Purchase _purchase(dynamic j) =>
      Purchase.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<Purchase>>> getPurchases() => _api.get(
        ApiEndpoints.purchases,
        (j) => (j as List).map(_purchase).toList(),
      );

  @override
  Future<Result<Purchase>> create(PurchaseDraft draft) => _api.post(
        ApiEndpoints.purchases,
        _purchase,
        body: {
          'item_id': draft.itemId,
          'quantity': draft.quantity,
          'unit_cost': draft.unitCost,
          'note': draft.note ?? '',
        },
      );
}
