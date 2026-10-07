import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/cafe_status.dart';
import '../cafe_status_repository.dart';

/// وضعیت کافه روی Django: `GET /api/v1/cafe/status/` برای خواندن و
/// `POST` با `action` برای باز/بسته کردن. فقط ادمین مجاز است (در Backend).
class ApiCafeStatusRepository implements CafeStatusRepository {
  ApiCafeStatusRepository(this._api);
  final ApiClient _api;

  static CafeStatus _status(dynamic j) =>
      CafeStatus.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<CafeStatus>> getStatus() =>
      _api.get(ApiEndpoints.cafeStatus, _status);

  @override
  Future<Result<CafeStatus>> open() =>
      _api.post(ApiEndpoints.cafeStatus, _status, body: {'action': 'open'});

  @override
  Future<Result<CafeStatus>> close() =>
      _api.post(ApiEndpoints.cafeStatus, _status, body: {'action': 'close'});
}
