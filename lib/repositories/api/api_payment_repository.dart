import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/table_overview.dart';
import '../payment_repository.dart';

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<TableOverview>> pay(int tableId,
          {required PaymentMethod method, List<PaymentShare>? shares}) =>
      _api.post(
        ApiEndpoints.tablePay(tableId),
        (j) => TableOverview.fromJson(j as Map<String, dynamic>),
        // پرداخت چندروشی با `payments` می‌رود و `method` را هم می‌فرستیم تا
        // بک‌اندِ قدیمی‌تر که فقط تک‌روشی بلد است هم کار کند.
        body: {
          'method': method.apiValue,
          if (shares != null && shares.isNotEmpty)
            'payments': shares.map((s) => s.toJson()).toList(),
        },
      );

  @override
  Future<Result<Order>> refund(String orderId) => _api.post(
        ApiEndpoints.orderRefund(orderId),
        (j) => Order.fromJson(j as Map<String, dynamic>),
      );
}
