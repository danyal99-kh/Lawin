// lib/repositories/payment_repository.dart
import '../core/errors/result.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/table_overview.dart';

/// ثبت پرداخت صورتحساب یک میز.
///
/// طبق قانون ۲ (نگاه کنید به MockSessionEngine)، با این عملیات همه‌ی
/// سفارش‌های باز نشست میز یکجا پرداخت‌شده می‌شوند، نشست بسته و میز آزاد می‌شود.
/// مدیریت تک‌تک سفارش‌ها (پیشبرد وضعیت/لغو/چاپ) همچنان بر عهده‌ی
/// OrderRepository است؛ این Repository فقط مسئول عملیات «پرداخت» است.
abstract interface class PaymentRepository {
  /// اگر میز نشست باز یا سفارش بازی نداشته باشد، خطای notFound/conflict برمی‌گردد.
  ///
  /// [method] پرداخت تک‌روشی است. برای پرداخت چندروشی (مثلاً نقدی + کارتخوان)
  /// از [shares] استفاده کن؛ بک‌اند هم `method` و هم `payments` را می‌پذیرد و
  /// مجموع قسط‌ها باید با مبلغ کل برابر باشد.
  Future<Result<TableOverview>> pay(int tableId,
      {required PaymentMethod method, List<PaymentShare>? shares});

  /// بازگشت کل مبلغ یک سفارش پرداخت‌شده. فقط refund کامل پشتیبانی می‌شود و
  /// موجودیِ مصرف‌شده هم به انبار برمی‌گردد.
  Future<Result<Order>> refund(String orderId);
}
