import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../core/utils/date_ranges.dart';
import '../../models/enums.dart';
import '../../models/report.dart';
import '../report_repository.dart';
import 'mock_database.dart';

/// محاسبه‌ی گزارش از روی MockDatabase؛ بعد از اتصال به Django همین محاسبه
/// در Backend (احتمالاً با aggregation دیتابیس) انجام می‌شود و این کلاس حذف می‌شود.
class MockReportRepository implements ReportRepository {
  MockReportRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<Result<SalesReport>> getReport(ReportPeriod period) async {
    final now = DateTime.now();
    final end = DateRanges.endOfDay(now);
    final DateTime start;
    switch (period) {
      case ReportPeriod.today:
        start = DateRanges.startOfDay(now);
      case ReportPeriod.week:
        start = DateRanges.startOfWeek(now);
      case ReportPeriod.month:
        start = DateRanges.startOfJalaliMonth(now);
      case ReportPeriod.custom:
        start =
            DateRanges.startOfDay(now); // این حالت از getCustomReport می‌آید
    }
    return _build(start, end);
  }

  @override
  Future<Result<SalesReport>> getCustomReport(
      DateTime start, DateTime end) async {
    return _build(DateRanges.startOfDay(start), DateRanges.endOfDay(end));
  }

  Future<Result<SalesReport>> _build(DateTime start, DateTime end) async {
    try {
      await _latency();

      final paidOrders = _db.orders.where((o) =>
          o.status == OrderStatus.paid &&
          DateRanges.inRange(o.paidAt ?? o.createdAt, start, end));
      final expenses =
          _db.expenses.where((e) => DateRanges.inRange(e.date, start, end));

      final totalSales = paidOrders.fold<int>(0, (s, o) => s + o.total);
      final totalExpenses = expenses.fold<int>(0, (s, e) => s + e.amount);
      final itemsSold = paidOrders.fold<int>(0, (s, o) => s + o.itemCount);

      // محصولات پرفروش
      final byProduct = <int, _ProductAcc>{};
      for (final o in paidOrders) {
        for (final item in o.items) {
          final acc = byProduct.putIfAbsent(item.productId,
              () => _ProductAcc(item.productId, item.productName));
          acc.quantity += item.quantity;
          acc.revenue += item.lineTotal;
        }
      }
      final topProducts = byProduct.values
          .map((a) => ProductSales(
              productId: a.productId,
              productName: a.productName,
              quantity: a.quantity,
              revenue: a.revenue))
          .toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      // تفکیک هزینه‌ها بر اساس دسته
      final byCategory = <ExpenseCategory, int>{};
      for (final e in expenses) {
        byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      }
      final expensesByCategory = byCategory.entries
          .map((e) => ExpenseByCategory(category: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      // روند روزانه
      final days = end.difference(start).inDays;
      final dailyPoints = <DailyPoint>[
        for (var i = 0; i < days; i++)
          _dayPoint(start, i, paidOrders, expenses),
      ];

      return Success(SalesReport(
        start: start,
        end: end,
        totalSales: totalSales,
        // Mock تاریخچه‌ی خرید/مصرف/ضایعات ندارد، پس این‌ها صفر می‌مانند؛ سود
        // ناخالص برابر فروش و سود خالص برابر فروش منهای هزینه‌های عمومی.
        totalCogs: 0,
        grossProfit: totalSales,
        totalExpenses: totalExpenses,
        totalWaste: 0,
        netProfit: totalSales - totalExpenses,
        totalPurchases: 0,
        inventoryValue: _db.inventoryItems
            .fold<int>(0, (s, i) => s + (i.currentStock * i.unitCost).round()),
        paymentMethods: [
          PaymentMethodTotal(
            method: PaymentMethod.cash,
            label: PaymentMethod.cash.label,
            amount: totalSales,
          )
        ],
        paymentsTotal: totalSales,
        cashFlow: CashFlow(
          cash: CashFlowPeriod(
              opening: 0, inflow: totalSales, outflow: totalExpenses),
          bank: const CashFlowPeriod(opening: 0, inflow: 0, outflow: 0),
          opening: 0,
          inflow: totalSales,
          outflow: totalExpenses,
        ),
        orderCount: paidOrders.length,
        itemsSoldCount: itemsSold,
        topProducts: topProducts.take(10).toList(),
        expensesByCategory: expensesByCategory,
        dailyPoints: dailyPoints,
        creditSales: 570000,
        creditCollections: 200000,
        cashReceived: totalSales - 200000,
        outstandingReceivables: 370000,
      ));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  DailyPoint _dayPoint(
      DateTime start, int i, Iterable paidOrders, Iterable expenses) {
    final dayStart = DateTime(start.year, start.month, start.day + i);
    final dayEnd = DateTime(start.year, start.month, start.day + i + 1);
    final sales = paidOrders
        .cast<dynamic>()
        .where((o) =>
            DateRanges.inRange(o.paidAt ?? o.createdAt, dayStart, dayEnd))
        .fold<int>(0, (s, o) => s + (o.total as int));
    final exp = expenses
        .cast<dynamic>()
        .where((e) => DateRanges.inRange(e.date, dayStart, dayEnd))
        .fold<int>(0, (s, e) => s + (e.amount as int));
    return DailyPoint(
      date: dayStart,
      sales: sales,
      expenses: exp,
      cogs: 0,
      waste: 0,
      profit: sales - exp,
    );
  }
}

class _ProductAcc {
  _ProductAcc(this.productId, this.productName);
  final int productId;
  final String productName;
  int quantity = 0;
  int revenue = 0;
}
