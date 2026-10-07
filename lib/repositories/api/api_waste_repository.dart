import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/waste.dart';
import '../waste_repository.dart';

class ApiWasteRepository implements WasteRepository {
  ApiWasteRepository(this._api);
  final ApiClient _api;

  static Waste _waste(dynamic j) => Waste.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<Waste>>> getWastes() => _api.get(
        ApiEndpoints.wastes,
        (j) => (j as List).map(_waste).toList(),
      );

  @override
  Future<Result<Waste>> create(WasteDraft draft) => _api.post(
        ApiEndpoints.wastes,
        _waste,
        body: {
          'item_id': draft.itemId,
          'quantity': draft.quantity,
          'reason': draft.reason.apiValue,
          'note': draft.note ?? '',
        },
      );

  @override
  Future<Result<Waste>> update(int id, WasteDraft draft) => _api.patch(
        ApiEndpoints.waste(id),
        _waste,
        // مثل خرید، کالای ضایعات را جابه‌جا نمی‌کنیم؛ فقط مقدار، دلیل و یادداشت.
        body: {
          'quantity': draft.quantity,
          'reason': draft.reason.apiValue,
          'note': draft.note ?? '',
        },
      );

  @override
  Future<Result<void>> delete(int id) => _api.delete(ApiEndpoints.waste(id));
}
