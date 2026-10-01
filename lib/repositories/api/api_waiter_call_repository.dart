import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/waiter_call.dart';
import '../waiter_call_repository.dart';

class ApiWaiterCallRepository implements WaiterCallRepository {
  ApiWaiterCallRepository(this._api);

  final ApiClient _api;

  static WaiterCall _one(dynamic json) =>
      WaiterCall.fromJson(json as Map<String, dynamic>);

  @override
  Future<Result<List<WaiterCall>>> getActiveCalls() => _api.get(
        ApiEndpoints.waiterCalls,
        (json) => (json as List).map(_one).toList(),
        query: {'active': '1'},
      );

  @override
  Future<Result<WaiterCall>> acknowledge(String callId) =>
      _api.post(ApiEndpoints.waiterAck(callId), _one);

  @override
  Future<Result<WaiterCall>> complete(String callId) =>
      _api.post(ApiEndpoints.waiterComplete(callId), _one);
}
