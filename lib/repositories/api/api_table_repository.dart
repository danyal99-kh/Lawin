import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/table_overview.dart';
import '../table_repository.dart';

class ApiTableRepository implements TableRepository {
  ApiTableRepository(this._api);
  final ApiClient _api;

  static TableOverview _one(dynamic j) =>
      TableOverview.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<TableOverview>>> getTables() =>
      _api.get(ApiEndpoints.tables, (j) => (j as List).map(_one).toList());

  @override
  Future<Result<TableOverview>> setReserved(int tableId,
          {required bool reserved}) =>
      _api.post(ApiEndpoints.tableReserve(tableId), _one,
          body: {'reserved': reserved});
}