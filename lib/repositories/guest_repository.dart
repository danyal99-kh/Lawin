import '../core/errors/result.dart';
import '../models/guest.dart';

/// خواندن و مدیریت مهمان‌نوازی.
///
/// هیچ مبلغ یا وضعیتی از Client پذیرفته نمی‌شود؛ همه‌چیز را خودِ بک‌اند از
/// سفارش و دفتر محاسبه می‌کند. سمت کلاینت فقط خواندن، تغییر «نام» و لغو مجاز
/// است. ثبت مهمان از مسیر پرداخت انجام می‌شود (method: guest + guestName).
abstract interface class GuestRepository {
  /// گروه مهمان‌های فعال بر اساس نام؛ [query] روی نام جست‌وجو می‌کند.
  Future<Result<List<GuestGroup>>> getGroups({String? query});

  /// جمع کل مهمان‌نوازی فعال و تعداد ثبت‌ها.
  Future<Result<GuestSummary>> getSummary();

  /// ثبت‌های فعال یک نام مشخص، جدیدترین اول.
  Future<Result<List<Guest>>> getOrders(String name);

  /// تغییر نام یک ثبت مهمان (گروه‌بندی عوض می‌شود؛ مبلغ و دفتر دست‌نخورده).
  Future<Result<Guest>> rename(int id, String name);

  /// لغو مهمان‌نوازی: سند دفتر معکوس و موجودی سفارش برمی‌گردد.
  Future<Result<Guest>> cancel(int id);
}
