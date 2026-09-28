import 'enums.dart';

/// بازه‌ی زمانی گزارش.
enum ReportPeriod {
  today('امروز'),
  week('این هفته'),
  month('این ماه'),
  custom('بازه‌ی دلخواه');

  const ReportPeriod(this.label);
  final String label;
}

/// فروش یک محصول در بازه‌ی گزارش.
class ProductSales {
  const ProductSales({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  final int productId;
  final String productName;
  final int quantity;
  final int revenue;
}

/// جمع هزینه‌های یک دسته در بازه‌ی گزارش.
class ExpenseByCategory {
  const ExpenseByCategory({required this.category, required this.amount});

  final ExpenseCategory category;
  final int amount;
}

/// فروش/هزینه‌ی یک روز (برای نمودار روند).
class DailyPoint {
  const DailyPoint(
      {required this.date, required this.sales, required this.expenses});

  final DateTime date;
  final int sales;
  final int expenses;

  int get profit => sales - expenses;
}

/// خلاصه‌ی گزارش برای یک بازه‌ی زمانی مشخص. [end] نیمه‌باز است (شامل نمی‌شود).
class SalesReport {
  const SalesReport({
    required this.start,
    required this.end,
    required this.totalSales,
    required this.totalExpenses,
    required this.orderCount,
    required this.itemsSoldCount,
    required this.topProducts,
    required this.expensesByCategory,
    required this.dailyPoints,
  });

  final DateTime start;
  final DateTime end;
  final int totalSales;
  final int totalExpenses;
  final int orderCount;
  final int itemsSoldCount;
  final List<ProductSales> topProducts;
  final List<ExpenseByCategory> expensesByCategory;
  final List<DailyPoint> dailyPoints;

  int get totalProfit => totalSales - totalExpenses;
  int get averageOrderValue =>
      orderCount == 0 ? 0 : (totalSales / orderCount).round();
}
