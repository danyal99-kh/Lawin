import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/inventory_draft.dart';
import '../../models/inventory_item.dart';
import '../inventory_repository.dart';

class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository(this._api);
  final ApiClient _api;

  static InventoryItem _item(dynamic j) =>
      InventoryItem.fromJson(j as Map<String, dynamic>);

  Map<String, dynamic> _body(InventoryItemDraft d,
      {bool includeInitialStock = false}) {
    final body = <String, dynamic>{
      'name': d.name,
      'unit': d.unit.apiValue,
      'min_stock': d.minStock,
      'unit_cost': d.unitCost,
      'description': d.description ?? '',
    };
    if (includeInitialStock) body['initial_stock'] = d.initialStock;
    return body;
  }

  @override
  Future<Result<List<InventoryItem>>> getItems() => _api.get(
        ApiEndpoints.inventoryItems,
        (j) => (j as List).map(_item).toList(),
      );

  @override
  Future<Result<InventoryItem>> create(InventoryItemDraft draft) => _api.post(
        ApiEndpoints.inventoryItems,
        _item,
        body: _body(draft, includeInitialStock: true),
      );

  @override
  Future<Result<InventoryItem>> update(int id, InventoryItemDraft draft) =>
      _api.patch(
        ApiEndpoints.inventoryItem(id),
        _item,
        body: _body(draft),
      );

  @override
  Future<Result<void>> delete(int id) =>
      _api.delete(ApiEndpoints.inventoryItem(id));
}
