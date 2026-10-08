import 'cafe_table.dart';
import 'enums.dart';
import 'expense.dart';
import 'inventory_item.dart';
import 'order.dart';

/// خلاصه‌ی داشبورد، از `GET /api/v1/dashboard/summary/`.
///
/// **ارقام مالی را از خود بک‌اند می‌گیریم و اینجا دوباره حساب نمی‌کنیم.** قبلاً
/// [todayProfit] و [monthProfit] اینجا با `sales - expenses` ساخته می‌شدند که
/// بهای تمام‌شده‌ی مواد و ضایعات را نادیده می‌گرفت؛ حالا بک‌اند از دفتر مرکزی
/// `today_profit`/`month_profit` می‌فرستد و همین را می‌خوانیم.
class DashboardSummary {
  const DashboardSummary({
    required this.todaySales,
    required this.monthSales,
    required this.todayExpenses,
    required this.monthExpenses,
    required this.todayWaste,
    required this.monthWaste,
    required this.todayProfit,
    required this.monthProfit,
    required this.todayGrossProfit,
    required this.monthGrossProfit,
    required this.todayOrderCount,
    required this.tables,
    required this.lowStockItems,
    required this.recentOrders,
    required this.recentExpenses,
    this.receivablesBalance = 0,
  });

  final int todaySales;
  final int monthSales;

  /// هزینه‌های عمومی (بدون مواد و ضایعات).
  final int todayExpenses;
  final int monthExpenses;

  /// زیان ضایعات.
  final int todayWaste;
  final int monthWaste;

  /// سود خالص، همان‌طور که دفتر حساب کرده.
  final int todayProfit;
  final int monthProfit;

  /// سود ناخالص = درآمد − بهای تمام‌شده (پیش از هزینه‌های عمومی و ضایعات).
  final int todayGrossProfit;
  final int monthGrossProfit;

  final int todayOrderCount;
  final List<CafeTable> tables;
  final List<InventoryItem> lowStockItems;
  final List<Order> recentOrders;
  final List<Expense> recentExpenses;

  /// مانده‌ی حساب بدهکاران (نسیه‌های وصول‌نشده) از دفتر مرکزی؛ لحظه‌ای و
  /// مستقل از بازه‌ی زمانی.
  final int receivablesBalance;

  int _countTables(TableStatus s) => tables.where((t) => t.status == s).length;
  int get activeTables => _countTables(TableStatus.active);
  int get emptyTables => _countTables(TableStatus.empty);
  int get reservedTables => _countTables(TableStatus.reserved);

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    return DashboardSummary(
      todaySales: (json['today_sales'] as num).toInt(),
      monthSales: (json['month_sales'] as num).toInt(),
      todayExpenses: (json['today_expenses'] as num?)?.toInt() ?? 0,
      monthExpenses: (json['month_expenses'] as num?)?.toInt() ?? 0,
      todayWaste: (json['today_waste'] as num?)?.toInt() ?? 0,
      monthWaste: (json['month_waste'] as num?)?.toInt() ?? 0,
      todayProfit: (json['today_profit'] as num?)?.toInt() ?? 0,
      monthProfit: (json['month_profit'] as num?)?.toInt() ?? 0,
      todayGrossProfit: (json['today_gross_profit'] as num?)?.toInt() ?? 0,
      monthGrossProfit: (json['month_gross_profit'] as num?)?.toInt() ?? 0,
      todayOrderCount: json['today_order_count'] as int,
      tables: list('tables', CafeTable.fromJson),
      lowStockItems: list('low_stock_items', InventoryItem.fromJson),
      recentOrders: list('recent_orders', Order.fromJson),
      recentExpenses: list('recent_expenses', Expense.fromJson),
      receivablesBalance:
          (json['receivables_balance'] as num?)?.toInt() ?? 0,
    );
  }
}
