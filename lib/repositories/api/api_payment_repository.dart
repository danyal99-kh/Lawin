import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/enums.dart';
import '../../models/table_overview.dart';
import '../payment_repository.dart';

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<TableOverview>> pay(int tableId,
          {required PaymentMethod method}) =>
      _api.post(
        ApiEndpoints.tablePay(tableId),
        (j) => TableOverview.fromJson(j as Map<String, dynamic>),
        body: {'method': method.apiValue},
      );
}