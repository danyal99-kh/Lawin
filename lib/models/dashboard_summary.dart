import 'cafe_table.dart';
import 'enums.dart';
import 'expense.dart';
import 'inventory_item.dart';
import 'order.dart';

/// خلاصه‌ی داشبورد. در آینده مستقیماً از `GET /api/v1/dashboard/summary/` می‌آید.
/// سود در حال حاضر «درآمد − هزینه» است؛ برای افزودن هزینه‌ی مواد مصرفی در آینده
/// فقط محاسبه‌ی Backend (یا یک فیلد جدید) تغییر می‌کند.
class DashboardSummary {
  const DashboardSummary({
    required this.todaySales,
    required this.monthSales,
    required this.todayExpenses,
    required this.monthExpenses,
    required this.todayOrderCount,
    required this.tables,
    required this.lowStockItems,
    required this.recentOrders,
    required this.recentExpenses,
  });

  final int todaySales;
  final int monthSales;
  final int todayExpenses;
  final int monthExpenses;
  final int todayOrderCount;
  final List<CafeTable> tables;
  final List<InventoryItem> lowStockItems;
  final List<Order> recentOrders;
  final List<Expense> recentExpenses;

  int get todayProfit => todaySales - todayExpenses;
  int get monthProfit => monthSales - monthExpenses;

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
      todaySales: json['today_sales'] as int,
      monthSales: json['month_sales'] as int,
      todayExpenses: json['today_expenses'] as int,
      monthExpenses: json['month_expenses'] as int,
      todayOrderCount: json['today_order_count'] as int,
      tables: list('tables', CafeTable.fromJson),
      lowStockItems: list('low_stock_items', InventoryItem.fromJson),
      recentOrders: list('recent_orders', Order.fromJson),
      recentExpenses: list('recent_expenses', Expense.fromJson),
    );
  }
}
