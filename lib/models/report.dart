import 'api_enum.dart';
import 'enums.dart';

/// بازه‌ی زمانی گزارش. [apiValue] دقیقاً همان چیزی است که Django
/// در `GET /api/v1/reports/?period=` انتظار دارد.
enum ReportPeriod implements ApiEnum {
  today('today', 'امروز'),
  week('week', 'این هفته'),
  month('month', 'این ماه'),
  custom('custom', 'بازه‌ی دلخواه');

  const ReportPeriod(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
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

  factory ProductSales.fromJson(Map<String, dynamic> json) => ProductSales(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        revenue: json['revenue'] as int,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'revenue': revenue,
      };
}

/// جمع هزینه‌های یک دسته در بازه‌ی گزارش.
class ExpenseByCategory {
  const ExpenseByCategory({required this.category, required this.amount});

  final ExpenseCategory category;
  final int amount;

  factory ExpenseByCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseByCategory(
        category: parseApiEnum(ExpenseCategory.values, json['category'],
            fallback: ExpenseCategory.other),
        amount: json['amount'] as int,
      );

  Map<String, dynamic> toJson() => {
        'category': category.apiValue,
        'amount': amount,
      };
}

/// فروش/هزینه‌ی یک روز (برای نمودار روند).
class DailyPoint {
  const DailyPoint(
      {required this.date, required this.sales, required this.expenses});

  final DateTime date;
  final int sales;
  final int expenses;

  int get profit => sales - expenses;

  /// بک‌اند تاریخ را به شکل «روز» بدون ساعت می‌فرستد (`YYYY-MM-DD`)؛
  /// [DateTime.parse] آن را به نیمه‌شب همان روز محلی تبدیل می‌کند.
  factory DailyPoint.fromJson(Map<String, dynamic> json) => DailyPoint(
        date: DateTime.parse(json['date'] as String),
        sales: json['sales'] as int,
        expenses: json['expenses'] as int,
      );

  Map<String, dynamic> toJson() => {
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'sales': sales,
        'expenses': expenses,
      };
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

  /// همه‌ی عددها را همان‌طور که بک‌اند حساب کرده می‌گیرد؛ اینجا فقط خوانده
  /// می‌شود و هیچ محاسبه‌ی مالی تازه‌ای انجام نمی‌شود.
  ///
  /// [start] و [end] از نوع ISO با هر offset بک‌اند می‌آیند و به وقت محلی
  /// تبدیل می‌شوند؛ [end] نیمه‌باز است (شامل نمی‌شود) — همان قرارداد قبلی.
  /// لیست‌های خالی یا غایب هم به لیست خالی تبدیل می‌شوند تا بازه‌ی بدون داده
  /// پاسخ معتبر با صفر باشد، نه crash.
  factory SalesReport.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();

    return SalesReport(
      start: DateTime.parse(json['start'] as String).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
      totalSales: json['total_sales'] as int,
      totalExpenses: json['total_expenses'] as int,
      orderCount: json['order_count'] as int,
      itemsSoldCount: json['items_sold_count'] as int,
      topProducts: list('top_products', ProductSales.fromJson),
      expensesByCategory:
          list('expenses_by_category', ExpenseByCategory.fromJson),
      dailyPoints: list('daily_points', DailyPoint.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'total_sales': totalSales,
        'total_expenses': totalExpenses,
        'order_count': orderCount,
        'items_sold_count': itemsSoldCount,
        'top_products': topProducts.map((p) => p.toJson()).toList(),
        'expenses_by_category':
            expensesByCategory.map((e) => e.toJson()).toList(),
        'daily_points': dailyPoints.map((d) => d.toJson()).toList(),
      };
}
