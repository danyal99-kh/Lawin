import '../core/errors/result.dart';
import '../models/dashboard_summary.dart';

/// قرارداد دریافت اطلاعات داشبورد.
abstract interface class DashboardRepository {
  Future<Result<DashboardSummary>> getSummary();
}
