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
///
/// [expenses] در قرارداد بک‌اند «کل هزینه‌های روز» است یعنی
/// هزینه‌های عمومی + بهای تمام‌شده + ضایعات. این جمع با [cogs] و [waste]
/// هم‌پوشانی دارد، پس برای نمودارِ سود باید از [profit] استفاده کرد نه از
/// `sales - expenses`؛ وگرنه COGS را دوبار از سود کم می‌کنیم.
class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.sales,
    required this.expenses,
    required this.cogs,
    required this.waste,
    required this.profit,
  });

  final DateTime date;

  /// درآمد ناخالص روز (فروش).
  final int sales;

  /// مجموع هزینه‌های روز از دید دفتر: عمومی + تمام‌شده + ضایعات.
  final int expenses;

  /// بهای تمام‌شده‌ی مواد مصرفی.
  final int cogs;

  /// زیان ضایعات.
  final int waste;

  /// سود خالص روز، همان‌طور که دفتر حساب کرده.
  final int profit;

  /// بک‌اند تاریخ را به شکل «روز» بدون ساعت می‌فرستد (`YYYY-MM-DD`)؛
  /// [DateTime.parse] آن را به نیمه‌شب همان روز محلی تبدیل می‌کند.
  factory DailyPoint.fromJson(Map<String, dynamic> json) => DailyPoint(
        date: DateTime.parse(json['date'] as String),
        sales: (json['sales'] as num).toInt(),
        expenses: (json['expenses'] as num).toInt(),
        cogs: (json['cogs'] as num?)?.toInt() ?? 0,
        waste: (json['waste'] as num?)?.toInt() ?? 0,
        profit: (json['profit'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'sales': sales,
        'expenses': expenses,
        'cogs': cogs,
        'waste': waste,
        'profit': profit,
      };
}

/// جمع یک روش پرداخت در بازه.
class PaymentMethodTotal {
  const PaymentMethodTotal({
    required this.method,
    required this.label,
    required this.amount,
  });

  final PaymentMethod method;

  /// برچسبی که خود بک‌اند می‌فرستد (منبع نمایش، نه ساختن برچسب در کلاینت).
  final String label;
  final int amount;

  factory PaymentMethodTotal.fromJson(Map<String, dynamic> json) =>
      PaymentMethodTotal(
        method: parseApiEnum(PaymentMethod.values, json['method'],
            fallback: PaymentMethod.cash),
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num).toInt(),
      );

  Map<String, dynamic> toJson() =>
      {'method': method.apiValue, 'label': label, 'amount': amount};
}

/// جریان نقدی صندوق و بانک در بازه. [opening] مانده‌ی اول دوره است (از
/// تنظیمات کافه)، نه صفرِ فرضی.
class CashFlowPeriod {
  const CashFlowPeriod({
    required this.opening,
    required this.inflow,
    required this.outflow,
  });

  final int opening;
  final int inflow;
  final int outflow;

  int get closing => opening + inflow - outflow;

  factory CashFlowPeriod.fromJson(Map<String, dynamic> json) => CashFlowPeriod(
        opening: (json['opening'] as num?)?.toInt() ?? 0,
        inflow: (json['in'] as num?)?.toInt() ?? 0,
        outflow: (json['out'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'opening': opening, 'in': inflow, 'out': outflow};
}

class CashFlow {
  const CashFlow({
    required this.cash,
    required this.bank,
    required this.opening,
    required this.inflow,
    required this.outflow,
  });

  final CashFlowPeriod cash;
  final CashFlowPeriod bank;

  /// جمع صندوق و بانک.
  final int opening;
  final int inflow;
  final int outflow;

  int get closing => opening + inflow - outflow;

  factory CashFlow.fromJson(Map<String, dynamic> json) {
    final rawCash = json['cash'] as Map<String, dynamic>? ?? const {};
    final rawBank = json['bank'] as Map<String, dynamic>? ?? const {};
    return CashFlow(
      cash: CashFlowPeriod.fromJson(rawCash),
      bank: CashFlowPeriod.fromJson(rawBank),
      opening: (json['opening'] as num?)?.toInt() ?? 0,
      inflow: (json['total_in'] as num?)?.toInt() ?? 0,
      outflow: (json['total_out'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'cash': cash.toJson(),
        'bank': bank.toJson(),
        'opening': opening,
        'total_in': inflow,
        'total_out': outflow,
      };
}

/// خلاصه‌ی گزارش برای یک بازه‌ی زمانی مشخص. [end] نیمه‌باز است (شامل نمی‌شود).
///
/// **همه‌ی ارقام مالی از دفتر حسابداری مرکزی بک‌اند می‌آید.** این کلاس هیچ
/// محاسبه‌ی مالی تازه‌ای نمی‌کند؛ قبلاً [totalProfit] را اینجا با
/// `sales - expenses` می‌ساختیم که بهای تمام‌شده‌ی مواد و ضایعات را از سود
/// کم نمی‌کرد و با دفتر نمی‌خواند. حالا هر رقمِ سود را همان‌طور که دفتر
/// حساب کرده می‌گیریم.
class SalesReport {
  const SalesReport({
    required this.start,
    required this.end,
    required this.totalSales,
    required this.totalCogs,
    required this.grossProfit,
    required this.totalExpenses,
    required this.totalWaste,
    required this.netProfit,
    required this.totalPurchases,
    required this.inventoryValue,
    required this.paymentMethods,
    required this.paymentsTotal,
    required this.cashFlow,
    required this.orderCount,
    required this.itemsSoldCount,
    required this.topProducts,
    required this.expensesByCategory,
    required this.dailyPoints,
    required this.creditSales,
    required this.creditCollections,
    required this.cashReceived,
    required this.outstandingReceivables,
  });

  final DateTime start;
  final DateTime end;

  /// درآمد ناخالص = فروش.
  final int totalSales;

  /// بهای تمام‌شده‌ی مواد مصرفی‌شده.
  final int totalCogs;

  /// سود ناخالص = درآمد − بهای تمام‌شده.
  final int grossProfit;

  /// هزینه‌های عمومی (بدون مواد و ضایعات).
  final int totalExpenses;

  /// زیان ضایعات.
  final int totalWaste;

  /// سود خالص = سود ناخالص − هزینه‌های عمومی − ضایعات.
  final int netProfit;

  /// پولی که در این بازه صرف خرید کالا شده (هزینه نیست تا وقتی مصرف شود).
  final int totalPurchases;

  /// ارزش لحظه‌ای موجودی انبار، مستقل از این بازه.
  final int inventoryValue;

  final List<PaymentMethodTotal> paymentMethods;
  final int paymentsTotal;
  final CashFlow cashFlow;
  final int orderCount;
  final int itemsSoldCount;
  final List<ProductSales> topProducts;
  final List<ExpenseByCategory> expensesByCategory;
  final List<DailyPoint> dailyPoints;

  /// نسیه‌ها
  final int creditSales;
  final int creditCollections;
  final int cashReceived;
  final int outstandingReceivables;

  int get averageOrderValue =>
      orderCount == 0 ? 0 : (totalSales / orderCount).round();

  /// مانده‌ی نقدی کل (صندوق + بانک) در پایان بازه.
  int get closingBalance => cashFlow.closing;

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
      totalSales: (json['total_sales'] as num).toInt(),
      totalCogs: (json['total_cogs'] as num?)?.toInt() ?? 0,
      grossProfit: (json['gross_profit'] as num?)?.toInt() ?? 0,
      totalExpenses: (json['total_expenses'] as num).toInt(),
      totalWaste: (json['total_waste'] as num?)?.toInt() ?? 0,
      netProfit: (json['net_profit'] as num?)?.toInt() ?? 0,
      totalPurchases: (json['total_purchases'] as num?)?.toInt() ?? 0,
      inventoryValue: (json['inventory_value'] as num?)?.toInt() ?? 0,
      paymentMethods: list('payment_methods', PaymentMethodTotal.fromJson),
      paymentsTotal: (json['payments_total'] as num?)?.toInt() ?? 0,
      cashFlow: CashFlow.fromJson(
          json['cash_flow'] as Map<String, dynamic>? ?? const {}),
      orderCount: json['order_count'] as int,
      itemsSoldCount: json['items_sold_count'] as int,
      topProducts: list('top_products', ProductSales.fromJson),
      expensesByCategory:
          list('expenses_by_category', ExpenseByCategory.fromJson),
      dailyPoints: list('daily_points', DailyPoint.fromJson),
      creditSales: (json['credit_sales'] as num?)?.toInt() ?? 0,
      creditCollections: (json['credit_collections'] as num?)?.toInt() ?? 0,
      cashReceived: (json['cash_received'] as num?)?.toInt() ?? 0,
      outstandingReceivables:
          (json['outstanding_receivables'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'total_sales': totalSales,
        'total_cogs': totalCogs,
        'gross_profit': grossProfit,
        'total_expenses': totalExpenses,
        'total_waste': totalWaste,
        'net_profit': netProfit,
        'total_purchases': totalPurchases,
        'inventory_value': inventoryValue,
        'payment_methods': paymentMethods.map((p) => p.toJson()).toList(),
        'payments_total': paymentsTotal,
        'cash_flow': cashFlow.toJson(),
        'order_count': orderCount,
        'items_sold_count': itemsSoldCount,
        'top_products': topProducts.map((p) => p.toJson()).toList(),
        'expenses_by_category':
            expensesByCategory.map((e) => e.toJson()).toList(),
        'daily_points': dailyPoints.map((d) => d.toJson()).toList(),
      };
}
