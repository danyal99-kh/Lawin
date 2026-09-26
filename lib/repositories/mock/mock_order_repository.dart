import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../order_repository.dart';
import 'mock_database.dart';
import 'mock_session_engine.dart';

/// اعتبارسنجی‌ها همان قوانینی است که بعداً Backend اعمال می‌کند.
/// باز/بسته‌شدن نشست میز به‌طور کامل به [MockSessionEngine] واگذار می‌شود.
class MockOrderRepository implements OrderRepository {
  MockOrderRepository(this._db) : _sessions = MockSessionEngine(_db);

  final MockDatabase _db;
  final MockSessionEngine _sessions;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<Result<List<Order>>> getOrders() async {
    try {
      await _latency();
      final list = [..._db.orders]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Order>> create(OrderDraft draft) async {
    try {
      await _latency();
      if (draft.items.isEmpty) {
        return Failure(AppFailure.validation('حداقل یک آیتم را اضافه کنید.'));
      }
      final tableIndex = _db.tables.indexWhere((t) => t.id == draft.tableId);
      if (tableIndex == -1) return Failure(AppFailure.notFound());

      final lines = <OrderItem>[];
      for (final item in draft.items) {
        if (item.quantity <= 0) {
          return Failure(
              AppFailure.validation('تعداد آیتم باید بیشتر از صفر باشد.'));
        }
        Product? product;
        for (final p in _db.products) {
          if (p.id == item.productId) {
            product = p;
            break;
          }
        }
        if (product == null) return Failure(AppFailure.notFound());
        if (!product.isActive) {
          return Failure(AppFailure.inactiveProduct(product.name));
        }
        lines.add(OrderItem(
          productId: product.id,
          productName: product.name,
          quantity: item.quantity,
          unitPrice: product.price,
          note: item.note,
        ));
      }

      final now = DateTime.now();
      // قانون ۱ (MockSessionEngine): اولین سفارش میز، نشست را باز می‌کند
      // و میز رزروشده را با ورود مشتری فعال می‌کند.
      final session = _sessions.openIfNeeded(draft.tableId, now);
      final table = _db.tables[tableIndex];
      final number = _db.nextOrderNumber();
      final order = Order(
        id: 'order-$number',
        number: number,
        source: draft.source,
        tableId: table.id,
        tableNumber: table.number,
        sessionId: session.id,
        status: OrderStatus.newOrder,
        paymentStatus: PaymentStatus.unpaid,
        items: lines,
        createdAt: now,
        customerNote: draft.customerNote,
      );
      _db.orders.add(order);
      return Success(order);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Order>> updateStatus(String orderId, OrderStatus status) async {
    try {
      await _latency();
      final index = _db.orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return Failure(AppFailure.notFound());
      final current = _db.orders[index];
      if (!current.status.isOpen) {
        return Failure(
            AppFailure.conflict('این سفارش بسته شده و قابل تغییر نیست.'));
      }
      final updated = current.copyWith(status: status);
      _db.orders[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Order>> cancel(String orderId) async {
    try {
      await _latency();
      final index = _db.orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return Failure(AppFailure.notFound());
      final current = _db.orders[index];
      if (!current.status.isOpen) {
        return Failure(AppFailure.conflict('این سفارش قبلاً بسته شده است.'));
      }
      final updated = current.copyWith(status: OrderStatus.cancelled);
      _db.orders[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Order>> markBarPrinted(String orderId) async {
    try {
      await _latency();
      final index = _db.orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return Failure(AppFailure.notFound());
      final updated = _db.orders[index].copyWith(barPrintedAt: DateTime.now());
      _db.orders[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
