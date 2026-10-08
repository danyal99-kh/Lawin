// lib/repositories/mock/mock_payment_repository.dart
import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/table_overview.dart';
import '../payment_repository.dart';
import 'mock_database.dart';
import 'mock_session_engine.dart';
import 'mock_table_repository.dart';

/// پرداخت صورتحساب میز: همه‌ی سفارش‌های باز نشست را پرداخت‌شده می‌کند و طبق
/// قانون ۲ (MockSessionEngine) نشست را می‌بندد. وقتی Django آماده شد، این
/// منطق در یک تراکنش سمت Backend اجرا می‌شود و این کلاس حذف می‌شود.
class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository(this._db, this._tables)
      : _sessions = MockSessionEngine(_db);

  final MockDatabase _db;
  final MockTableRepository _tables;
  final MockSessionEngine _sessions;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<Result<TableOverview>> pay(
    int tableId, {
    required PaymentMethod method,
    List<PaymentShare>? shares,
    String? debtorName,
  }) async {
    try {
      await _latency();
      final tableIndex = _db.tables.indexWhere((t) => t.id == tableId);
      if (tableIndex == -1) return Failure(AppFailure.notFound());

      final openOrders = _db.orders
          .where((o) => o.tableId == tableId && o.status.isOpen)
          .toList();
      if (openOrders.isEmpty) {
        return Failure(
            AppFailure.conflict('سفارش بازی برای پرداخت وجود ندارد.'));
      }

      // پرداخت چندروشی: مجموع قسط‌ها باید با مبلغ کل صورتحساب بخواند،
      // وگرنه دفتر حسابداری بی‌خوان می‌ماند. مثل بک‌اند بررسی می‌کنیم.
      final total = openOrders.fold<int>(0, (s, o) => s + o.total);
      if (shares != null && shares.isNotEmpty) {
        final sum = shares.fold<int>(0, (s, sh) => s + sh.amount);
        if (sum != total) {
          return Failure(AppFailure.validation(
              'مجموع پرداخت‌های چندروشی ($sum) با مبلغ صورتحساب ($total) برابر نیست.'));
        }
      }

      final now = DateTime.now();
      // قانون ۲: پرداخت صورتحساب، نشست را می‌بندد و میز را آزاد می‌کند.
      final closedSession = _sessions.close(tableId, now);
      if (closedSession == null) {
        return Failure(AppFailure.conflict('نشست بازی برای این میز پیدا نشد.'));
      }

      for (final order in openOrders) {
        final index = _db.orders.indexWhere((o) => o.id == order.id);
        if (index == -1) continue;
        // در پرداخت چندروشی، روشِ غالب قسط اول به‌عنوان خلاصه ثبت می‌شود؛
        // در بک‌اند هم `payment_method` خلاصه است و جزئیات در جدول Payment است.
        final primary = (shares != null && shares.isNotEmpty)
            ? shares.first.method
            : method;
        // نسیه: سفارش از دید میز بسته می‌شود ولی پول وصول نشده؛ پس وضعیت
        // «نسیه» می‌ماند نه «پرداخت‌شده»، تا دفتر درآمد را از طلب جدا نگه دارد.
        _db.orders[index] = order.copyWith(
          status: OrderStatus.paid,
          paymentStatus: primary == PaymentMethod.credit
              ? PaymentStatus.credit
              : PaymentStatus.paid,
          paymentMethod: primary,
          paidAt: now,
        );
      }

      return Success(_tables.overviewFor(_db.tables[tableIndex]));
    } catch (e) {
      return Failure(AppFailure.paymentFailed());
    }
  }

  @override
  Future<Result<Order>> refund(String orderId) async {
    try {
      await _latency();
      final index = _db.orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return Failure(AppFailure.notFound());
      final order = _db.orders[index];
      if (order.status != OrderStatus.paid) {
        return Failure(
            AppFailure.conflict('فقط سفارش پرداخت‌شده را می‌توان برگشت داد.'));
      }
      final refunded = order.copyWith(
        status: OrderStatus.cancelled,
        paymentStatus: PaymentStatus.refunded,
        clearPaymentMethod: true,
        clearPaidAt: true,
      );
      _db.orders[index] = refunded;
      return Success(refunded);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
