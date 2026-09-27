// lib/repositories/payment_repository.dart
import '../core/errors/result.dart';
import '../models/enums.dart';
import '../models/table_overview.dart';

/// ثبت پرداخت صورتحساب یک میز.
///
/// طبق قانون ۲ (نگاه کنید به MockSessionEngine)، با این عملیات همه‌ی
/// سفارش‌های باز نشست میز یکجا پرداخت‌شده می‌شوند، نشست بسته و میز آزاد می‌شود.
/// مدیریت تک‌تک سفارش‌ها (پیشبرد وضعیت/لغو/چاپ) همچنان بر عهده‌ی
/// OrderRepository است؛ این Repository فقط مسئول عملیات «پرداخت» است.
abstract interface class PaymentRepository {
  /// اگر میز نشست باز یا سفارش بازی نداشته باشد، خطای notFound/conflict برمی‌گردد.
  Future<Result<TableOverview>> pay(int tableId,
      {required PaymentMethod method});
}
