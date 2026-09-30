import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/dashboard_summary.dart';
import '../dashboard_repository.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<DashboardSummary>> getSummary() => _api.get(
        ApiEndpoints.dashboardSummary,
        (j) => DashboardSummary.fromJson(j as Map<String, dynamic>),
      );
}
