import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/report.dart';
import '../report_repository.dart';

/// گزارش‌ها از Django: بازه را Backend با تقویم و منطقه‌ی زمانی خودش
/// (Asia/Tehran، هفته از شنبه، ماه شمسی) حساب می‌کند و همه‌ی اعداد مالی را
/// برمی‌گرداند. اینجا فقط query ساخته و JSON نگاشت می‌شود.
class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._api);
  final ApiClient _api;

  /// بک‌اند تاریخ بدون ساعت می‌خواهد (`YYYY-MM-DD`) و validate می‌کند؛
  /// `start`/`end` هر دو شامل می‌شوند.
  static String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<Result<SalesReport>> getReport(ReportPeriod period) => _api.get(
        ApiEndpoints.reports,
        (j) => SalesReport.fromJson(j as Map<String, dynamic>),
        query: {'period': period.apiValue},
      );

  @override
  Future<Result<SalesReport>> getCustomReport(DateTime start, DateTime end) =>
      _api.get(
        ApiEndpoints.reports,
        (j) => SalesReport.fromJson(j as Map<String, dynamic>),
        query: {
          'period': ReportPeriod.custom.apiValue,
          'start': _day(start),
          'end': _day(end),
        },
      );
}
