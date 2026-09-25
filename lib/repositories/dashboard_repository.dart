import '../core/errors/result.dart';
import '../models/dashboard_summary.dart';

/// قرارداد دریافت اطلاعات داشبورد. پیاده‌سازی Mock فعلی بعداً با ApiDashboardRepository
/// جایگزین می‌شود؛ Provider و UI تغییری نمی‌کنند.
abstract interface class DashboardRepository {
  Future<Result<DashboardSummary>> getSummary();
}
