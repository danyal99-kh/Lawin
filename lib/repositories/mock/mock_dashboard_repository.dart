import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../core/utils/date_ranges.dart';
import '../../models/dashboard_summary.dart';
import '../../models/enums.dart';
import '../dashboard_repository.dart';
import 'mock_database.dart';

/// پیاده‌سازی Mock: خلاصه را از MockDatabase محاسبه می‌کند.
class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository(this._db);

  final MockDatabase _db;

  @override
  Future<Result<DashboardSummary>> getSummary() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return Success(buildSummary(DateTime.now()));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  /// عمومی برای تست‌پذیری با زمان ثابت.
  DashboardSummary buildSummary(DateTime now) {
    final dayStart = DateRanges.startOfDay(now);
    final dayEnd = DateRanges.endOfDay(now);
    final monthStart = DateRanges.startOfJalaliMonth(now);

    final paid = _db.orders.where((o) => o.status == OrderStatus.paid);
    int sales(DateTime from) => paid
        .where((o) => DateRanges.inRange(o.paidAt ?? o.createdAt, from, dayEnd))
        .fold(0, (s, o) => s + o.total);
    int expenses(DateTime from) => _db.expenses
        .where((e) => DateRanges.inRange(e.date, from, dayEnd))
        .fold(0, (s, e) => s + e.amount);

    // ضایعات و بهای تمام‌شده را Mock نمی‌تواند حساب کند چون تاریخچه‌ی
    // مصرف/ضایعات در MockDatabase نیست (هر repository تاریخچه‌ی خودش را جدا
    // نگه می‌دارد) — پس صفر می‌مانند و سود ناخالص برابر سود خالص می‌شود.
    // برای داده‌ی واقعی، بک‌اند از دفتر مرکزی این اعداد را می‌فرستد.

    final todayOrders = _db.orders.where((o) =>
        o.status != OrderStatus.cancelled &&
        DateRanges.inRange(o.createdAt, dayStart, dayEnd));

    final lowStock = _db.inventoryItems.where((i) => i.isLow).toList()
      ..sort((a, b) =>
          (a.currentStock / a.minStock).compareTo(b.currentStock / b.minStock));

    final recentOrders = [..._db.orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentExpenses = [..._db.expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSummary(
      todaySales: sales(dayStart),
      monthSales: sales(monthStart),
      todayExpenses: expenses(dayStart),
      monthExpenses: expenses(monthStart),
      // در Mock صفر است؛ توضیح بالای این بخش را ببینید.
      todayWaste: 0,
      monthWaste: 0,
      todayProfit: sales(dayStart) - expenses(dayStart),
      monthProfit: sales(monthStart) - expenses(monthStart),
      todayGrossProfit: sales(dayStart),
      monthGrossProfit: sales(monthStart),
      todayOrderCount: todayOrders.length,
      tables: List.unmodifiable(_db.tables),
      lowStockItems: lowStock,
      recentOrders: recentOrders.take(6).toList(),
      recentExpenses: recentExpenses.take(5).toList(),
      receivablesBalance: 470000,
    );
  }
}
