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
          'account': draft.account.apiValue,
          'note': draft.note ?? '',
        },
      );

  @override
  Future<Result<Purchase>> update(int id, PurchaseDraft draft) => _api.patch(
        ApiEndpoints.purchase(id),
        _purchase,
        // `item_id` عمداً نمی‌فرستیم: جابه‌جا کردن یک خرید به کالای دیگر،
        // تاریخچه‌ی انبار دو کالا را قاطی می‌کند و بک‌اند هم آن را نمی‌پذیرد.
        body: {
          'quantity': draft.quantity,
          'unit_cost': draft.unitCost,
          'account': draft.account.apiValue,
          'note': draft.note ?? '',
        },
      );

  @override
  Future<Result<void>> delete(int id) => _api.delete(ApiEndpoints.purchase(id));
}
