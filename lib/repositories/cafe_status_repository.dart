import '../core/errors/result.dart';
import '../models/cafe_status.dart';

/// قرارداد وضعیت باز/بسته بودن کافه.
///
/// منبع حقیقت در Backend است؛ تغییر وضعیت هم باید از همین‌جا (و از طریق API)
/// انجام شود تا هیچ تصمیمی در Flutter گرفته نشود.
abstract interface class CafeStatusRepository {
  Future<Result<CafeStatus>> getStatus();

  /// باز کردن کافه؛ زمان باز شدن را Backend ثبت می‌کند.
  Future<Result<CafeStatus>> open();

  /// بستن کافه؛ زمان بسته شدن را Backend ثبت می‌کند.
  Future<Result<CafeStatus>> close();
}
