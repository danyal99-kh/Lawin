// قرارداد بین پاسخ واقعی Django و مدل‌های Flutter.
// JSONهای این تست عیناً شکل پاسخ core/accounting_api.py هستند
// (GET /api/v1/accounting/transactions/ و GET /api/v1/reports/).
import 'dart:convert';

import 'package:cafe_book_admin/models/accounting_entry.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/models/report.dart';
import 'package:flutter_test/flutter_test.dart';

/// پاسخ دفتر حسابداری: یک لیست ساده (نه paginated)، جدیدترین اول.
const String transactionsJson = '''
[{"id":"expense-5","type":"expense","title":"خرید شیر","subtitle":"خرید مواد اولیه",
  "amount":50000,"date":"2026-10-01T09:15:00+03:30"},
 {"id":"income-12","type":"income","title":"سفارش 1014","subtitle":"میز 2 • نقدی",
  "amount":220000,"date":"2026-10-01T08:40:00+03:30"}]
''';

/// پاسخ گزارش ماه جاری؛ مجموع‌ها و تفکیک‌ها همه در Backend و از دفتر حسابداری
/// مرکزی حساب شده‌اند.
const String reportJson = '''
{"start":"2026-09-23T00:00:00+03:30","end":"2026-10-02T00:00:00+03:30",
 "total_sales":3980000,"total_cogs":1450000,"gross_profit":2530000,
 "total_expenses":2070000,"total_waste":120000,"net_profit":340000,
 "total_purchases":1800000,"inventory_value":4230000,
 "payment_methods":[{"method":"cash","label":"نقدی","amount":2480000},
                    {"method":"card_transfer","label":"کارت‌به‌کارت","amount":1500000}],
 "payments_total":3980000,
 "cash_flow":{"cash":{"opening":500000,"in":2480000,"out":2600000},
              "bank":{"opening":1200000,"in":1500000,"out":300000},
              "opening":1700000,"total_in":3980000,"total_out":2900000},
 "order_count":4,"items_sold_count":11,
 "top_products":[{"product_id":3,"product_name":"کیک","quantity":4,"revenue":440000},
                 {"product_id":7,"product_name":"آیس آمریکانو","quantity":7,"revenue":315000}],
 "expenses_by_category":[{"category":"supplies","amount":1070000},
                        {"category":"rent","amount":900000},
                        {"category":"salary","amount":100000}],
 "daily_points":[{"date":"2026-09-23","sales":0,"expenses":0,"cogs":0,"waste":0,"profit":0},
                 {"date":"2026-10-01","sales":95000,"expenses":1070000,"cogs":350000,"waste":50000,"profit":-995000}]}
''';

/// همان ساختار، اما برای بازه‌ای که هیچ داده‌ای ندارد: Backend صفر و لیست
/// خالی می‌فرستد، نه null و نه خطا.
const String emptyReportJson = '''
{"start":"2026-01-01T00:00:00+03:30","end":"2026-01-02T00:00:00+03:30",
 "total_sales":0,"total_cogs":0,"gross_profit":0,"total_expenses":0,
 "total_waste":0,"net_profit":0,"total_purchases":0,"inventory_value":0,
 "payment_methods":[],"payments_total":0,
 "cash_flow":{"cash":{"opening":0,"in":0,"out":0},"bank":{"opening":0,"in":0,"out":0},
              "opening":0,"total_in":0,"total_out":0},
 "order_count":0,"items_sold_count":0,
 "top_products":[],"expenses_by_category":[],
 "daily_points":[{"date":"2026-01-01","sales":0,"expenses":0,"cogs":0,"waste":0,"profit":0}]}
''';

void main() {
  group('AccountingEntry.fromJson parses the real Django response', () {
    final entries = (jsonDecode(transactionsJson) as List)
        .map((j) => AccountingEntry.fromJson(j as Map<String, dynamic>))
        .toList();

    test('maps both the income and the expense row', () {
      expect(entries, hasLength(2));

      final income = entries.firstWhere((e) => e.isIncome);
      expect(income.id, 'income-12');
      expect(income.type, AccountingEntryType.income);
      expect(income.title, 'سفارش 1014');
      expect(income.subtitle, 'میز 2 • نقدی');
      expect(income.amount, 220000);

      final expense = entries.firstWhere((e) => !e.isIncome);
      expect(expense.id, 'expense-5');
      expect(expense.type, AccountingEntryType.expense);
      expect(expense.subtitle, 'خرید مواد اولیه');
      expect(expense.amount, 50000);
    });

    test('parses the offset datetime into local time', () {
      expect(entries.first.date.isUtc, isFalse);
      expect(
        entries.first.date.isAtSameMomentAs(
          DateTime.parse('2026-10-01T09:15:00+03:30'),
        ),
        isTrue,
      );
    });

    test('subtitle may be null', () {
      final e = AccountingEntry.fromJson({
        'id': 'income-1',
        'type': 'income',
        'title': 'سفارش 1',
        'subtitle': null,
        'amount': 1000,
        'date': '2026-10-01T08:00:00+03:30',
      });
      expect(e.subtitle, isNull);
      expect(e.isIncome, isTrue);
    });

    test('an unknown type degrades instead of crashing', () {
      final e = AccountingEntry.fromJson({
        'id': 'x-1',
        'type': 'refund',
        'title': 'بازگشت وجه',
        'amount': 1,
        'date': '2026-10-01T08:00:00+03:30',
      });
      expect(e.type, AccountingEntryType.expense); // fallback
    });

    test('round-trips through toJson', () {
      final again = AccountingEntry.fromJson(entries.last.toJson());
      expect(again.id, entries.last.id);
      expect(again.type, entries.last.type);
      expect(again.amount, entries.last.amount);
    });
  });

  group('SalesReport.fromJson parses the real Django response', () {
    final report =
        SalesReport.fromJson(jsonDecode(reportJson) as Map<String, dynamic>);

    test('reads the server numbers without recomputing them', () {
      expect(report.totalSales, 3980000);
      expect(report.totalExpenses, 2070000);
      expect(report.totalCogs, 1450000);
      expect(report.totalWaste, 120000);
      expect(report.orderCount, 4);
      expect(report.itemsSoldCount, 11);
    });

    test('profit comes from the server, not from client-side arithmetic', () {
      // سود ناخالص و خالص را دفتر حساب کرده؛ کلاینت نباید
      // `sales - expenses` را دوباره حساب کند (که COGS را از قلم می‌انداخت).
      expect(report.grossProfit, 2530000);
      expect(report.netProfit, 340000);
      // یعنی سود خالص واقعاً کمتر از ناخالص است، برخلاف محاسبه‌ی قدیمی.
      expect(report.netProfit, isNot(report.totalSales - report.totalExpenses));
      expect(report.averageOrderValue, 995000);
    });

    test('cash flow keeps opening balances instead of assuming zero', () {
      expect(report.cashFlow.opening, 1700000);
      expect(report.cashFlow.inflow, 3980000);
      expect(report.cashFlow.outflow, 2900000);
      expect(report.closingBalance, 2780000);
      expect(report.cashFlow.cash.closing, 380000);
      expect(report.cashFlow.bank.closing, 2400000);
    });

    test('payment methods come from the server with their labels', () {
      expect(report.paymentMethods, hasLength(2));
      expect(report.paymentMethods.first.method, PaymentMethod.cash);
      expect(report.paymentMethods.first.amount, 2480000);
      expect(
        report.paymentMethods.last.method,
        PaymentMethod.cardTransfer,
      );
      expect(report.paymentsTotal, 3980000);
    });

    test('range is half-open and stored in local time', () {
      expect(report.start.isUtc, isFalse);
      expect(
        report.start
            .isAtSameMomentAs(DateTime.parse('2026-09-23T00:00:00+03:30')),
        isTrue,
      );
      expect(
        report.end
            .isAtSameMomentAs(DateTime.parse('2026-10-02T00:00:00+03:30')),
        isTrue,
      );
      // همان قراردادی که UI از قبل استفاده می‌کند: end شامل نمی‌شود
      expect(report.end.subtract(const Duration(days: 1)).day, 1);
    });

    test('top products keep product id, quantity and revenue', () {
      expect(report.topProducts, hasLength(2));
      expect(report.topProducts.first.productId, 3);
      expect(report.topProducts.first.productName, 'کیک');
      expect(report.topProducts.first.quantity, 4);
      expect(report.topProducts.first.revenue, 440000);
    });

    test('expenses are grouped by category with their own labels', () {
      expect(report.expensesByCategory, hasLength(3));
      expect(
        report.expensesByCategory.map((e) => e.category),
        [
          ExpenseCategory.supplies,
          ExpenseCategory.rent,
          ExpenseCategory.salary,
        ],
      );
      expect(report.expensesByCategory.first.amount, 1070000);
      // دسته‌ی ناشناخته به «سایر» می‌افتد
      expect(
        ExpenseByCategory.fromJson({'category': 'crypto', 'amount': 5})
            .category,
        ExpenseCategory.other,
      );
    });

    test('daily trend keeps the date string and both sums', () {
      expect(report.dailyPoints, hasLength(2));
      expect(report.dailyPoints.first.sales, 0);
      final last = report.dailyPoints.last;
      expect(last.sales, 95000);
      expect(last.expenses, 1070000);
      expect(last.cogs, 350000);
      expect(last.waste, 50000);
      expect(last.profit, -995000);
      expect(last.date.year, 2026);
      expect(last.date.month, 10);
      expect(last.date.day, 1);
    });

    test('round-trips through toJson', () {
      final again = SalesReport.fromJson(report.toJson());
      expect(again.totalSales, report.totalSales);
      expect(again.netProfit, report.netProfit);
      expect(again.closingBalance, report.closingBalance);
      expect(again.topProducts.first.productName, 'کیک');
      expect(
        again.expensesByCategory.first.category,
        ExpenseCategory.supplies,
      );
      expect(again.dailyPoints.length, report.dailyPoints.length);
    });
  });

  group('empty range is valid data, not an error', () {
    final report = SalesReport.fromJson(
        jsonDecode(emptyReportJson) as Map<String, dynamic>);

    test('numbers are zero and lists are empty', () {
      expect(report.totalSales, 0);
      expect(report.totalExpenses, 0);
      expect(report.netProfit, 0);
      expect(report.orderCount, 0);
      expect(report.itemsSoldCount, 0);
      expect(report.averageOrderValue, 0);
      expect(report.topProducts, isEmpty);
      expect(report.expensesByCategory, isEmpty);
    });

    test('the backend still fills every day of the range', () {
      expect(report.dailyPoints, hasLength(1));
      expect(report.dailyPoints.first.sales, 0);
      expect(report.dailyPoints.first.expenses, 0);
    });

    test('missing list keys degrade to empty instead of throwing', () {
      final s = SalesReport.fromJson({
        'start': '2026-01-01T00:00:00+03:30',
        'end': '2026-01-02T00:00:00+03:30',
        'total_sales': 0,
        'total_expenses': 0,
        'order_count': 0,
        'items_sold_count': 0,
      });
      expect(s.topProducts, isEmpty);
      expect(s.expensesByCategory, isEmpty);
      expect(s.dailyPoints, isEmpty);
    });
  });

  group('ReportPeriod.apiValue matches what the endpoint accepts', () {
    test('the four periods of GET /reports/', () {
      expect(ReportPeriod.today.apiValue, 'today');
      expect(ReportPeriod.week.apiValue, 'week');
      expect(ReportPeriod.month.apiValue, 'month');
      expect(ReportPeriod.custom.apiValue, 'custom');
    });
  });
}
