import '../core/errors/result.dart';
import '../models/report.dart';

abstract interface class ReportRepository {
  /// گزارش برای یک بازه‌ی از پیش تعریف‌شده (امروز/این هفته/این ماه).
  Future<Result<SalesReport>> getReport(ReportPeriod period);

  /// گزارش برای بازه‌ی دلخواه کاربر (هر دو روز شامل می‌شوند).
  Future<Result<SalesReport>> getCustomReport(DateTime start, DateTime end);
}
