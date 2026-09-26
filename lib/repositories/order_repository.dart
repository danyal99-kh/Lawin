import '../core/errors/result.dart';
import '../models/enums.dart';
import '../models/order.dart';

/// آیتم درخواستی برای ثبت سفارش (شناسه‌ی محصول + تعداد)؛ نام و قیمت را Repository از محصول snapshot می‌کند.
class OrderItemDraft {
  const OrderItemDraft({
    required this.productId,
    required this.quantity,
    this.note,
  });

  final int productId;
  final int quantity;
  final String? note;
}

/// داده‌ی لازم برای ثبت سفارش جدید یک میز.
class OrderDraft {
  const OrderDraft({
    required this.tableId,
    required this.items,
    this.source = OrderSource.admin,
    this.customerNote,
  });

  final int tableId;
  final List<OrderItemDraft> items;
  final OrderSource source;
  final String? customerNote;
}

abstract interface class OrderRepository {
  /// همه‌ی سفارش‌ها (شامل بسته‌شده‌ها)، جدیدترین اول.
  Future<Result<List<Order>>> getOrders();

  /// ثبت سفارش جدید؛ اگر میز نشست باز نداشته باشد، طبق قانون نشست جدید باز می‌شود.
  Future<Result<Order>> create(OrderDraft draft);

  /// پیشبرد وضعیت سفارش در روند آشپزخانه (فقط سفارش‌های باز).
  Future<Result<Order>> updateStatus(String orderId, OrderStatus status);

  /// لغو سفارش (فقط سفارش‌های باز؛ سفارش پرداخت‌شده قابل لغو نیست).
  Future<Result<Order>> cancel(String orderId);

  /// ثبت زمان چاپ سفارش بار (جلوگیری از چاپ تکراری).
  Future<Result<Order>> markBarPrinted(String orderId);
}
