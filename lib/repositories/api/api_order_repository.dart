import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../order_repository.dart';

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._api);
  final ApiClient _api;

  static Order _order(dynamic j) => Order.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<Order>>> getOrders() => _api.get(
        ApiEndpoints.orders,
        (j) => (j as List).map(_order).toList(),
      );

  @override
  Future<Result<Order>> create(OrderDraft draft) => _api.post(
        ApiEndpoints.orders,
        _order,
        body: {
          'table_id': draft.tableId,
          'customer_note': draft.customerNote,
          'items': [
            for (final i in draft.items)
              {
                'product_id': i.productId,
                'quantity': i.quantity,
                'note': i.note ?? '',
              }
          ],
        },
      );

  @override
  Future<Result<Order>> updateStatus(String orderId, OrderStatus status) =>
      _api.post(ApiEndpoints.orderStatus(orderId), _order,
          body: {'status': status.apiValue});

  @override
  Future<Result<Order>> cancel(String orderId) =>
      updateStatus(orderId, OrderStatus.cancelled);

  @override
  Future<Result<Order>> markBarPrinted(String orderId) =>
      _api.post(ApiEndpoints.orderBarPrinted(orderId), _order);

  /// دریافت افزایشی (بعد از قطع WebSocket).
  Future<Result<OrderChanges>> changes(String? cursor) => _api.get(
        ApiEndpoints.ordersChanges,
        (j) {
          final m = j as Map<String, dynamic>;
          return OrderChanges(
            orders: (m['orders'] as List).map(_order).toList(),
            cursor: m['cursor'] as String,
          );
        },
        query: cursor == null ? null : {'cursor': cursor},
      );
}

class OrderChanges {
  const OrderChanges({required this.orders, required this.cursor});
  final List<Order> orders;
  final String cursor;
}