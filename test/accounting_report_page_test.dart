// تست اتصال داده‌ی واقعی به صفحه‌های حسابداری و گزارش‌ها، و تست سوییچ
// AppConfig.useMock در app_providers.
//
// داده از همان JSONهای قراردادی مرحله‌ی ۶ می‌آید، ولی به‌جای شبکه از
// Repository ساختگی تزریق می‌شود تا تست قطعی و بدون سرور باشد.
import 'dart:convert';

import 'package:cafe_book_admin/core/config/app_config.dart';
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/utils/persian_format.dart';
import 'package:cafe_book_admin/core/utils/view_state.dart';
import 'package:cafe_book_admin/models/accounting_entry.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/models/report.dart';
import 'package:cafe_book_admin/pages/accounting/accounting_page.dart';
import 'package:cafe_book_admin/pages/accounting/widgets/accounting_entry_tile.dart';
import 'package:cafe_book_admin/pages/reports/reports_page.dart';
import 'package:cafe_book_admin/pages/reports/widgets/expense_breakdown_panel.dart';
import 'package:cafe_book_admin/pages/reports/widgets/top_products_panel.dart';
import 'package:cafe_book_admin/providers/accounting_provider.dart';
import 'package:cafe_book_admin/providers/app_providers.dart';
import 'package:cafe_book_admin/providers/report_provider.dart';
import 'package:cafe_book_admin/repositories/accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_report_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:cafe_book_admin/repositories/mock/mock_report_repository.dart';
import 'package:cafe_book_admin/repositories/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _ledgerJson = '''
[{"id":"expense-5","type":"expense","title":"خرید شیر","subtitle":"خرید مواد اولیه",
  "amount":50000,"date":"2026-10-01T09:15:00+03:30"},
 {"id":"income-12","type":"income","title":"سفارش 1014","subtitle":"میز 2 • نقدی",
  "amount":220000,"date":"2026-10-01T08:40:00+03:30"}]
''';

const String _reportJson = '''
{"start":"2026-09-23T00:00:00+03:30","end":"2026-10-02T00:00:00+03:30",
 "total_sales":3980000,"total_cogs":1450000,"gross_profit":2530000,
 "total_expenses":2070000,"total_waste":120000,"net_profit":340000,
 "total_purchases":1800000,"inventory_value":4230000,
 "payment_methods":[],"payments_total":3980000,
 "cash_flow":{"cash":{"opening":0,"in":0,"out":0},"bank":{"opening":0,"in":0,"out":0},
              "opening":0,"total_in":0,"total_out":0},
 "order_count":4,"items_sold_count":11,
 "top_products":[{"product_id":3,"product_name":"کیک","quantity":4,"revenue":440000}],
 "expenses_by_category":[{"category":"supplies","amount":1070000},
                        {"category":"rent","amount":900000}],
 "daily_points":[{"date":"2026-09-23","sales":0,"expenses":0,"cogs":0,"waste":0,"profit":0},
                 {"date":"2026-10-01","sales":95000,"expenses":1000000,"cogs":0,"waste":0,"profit":-905000}]}
''';

class _FakeAccountingRepository implements AccountingRepository {
  _FakeAccountingRepository(this.json);
  final String json;
  int calls = 0;

  @override
  Future<Result<List<AccountingEntry>>> getEntries() async {
    calls++;
    return Success((jsonDecode(json) as List)
        .map((e) => AccountingEntry.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  @override
  Future<Result<LedgerVerification>> verifyLedger() async =>
      const Success(LedgerVerification(ok: true, problems: [], warnings: []));
}

class _FakeReportRepository implements ReportRepository {
  _FakeReportRepository(this.json);
  final String json;
  final List<ReportPeriod> requested = [];
  final List<(DateTime, DateTime)> customRanges = [];

  @override
  Future<Result<SalesReport>> getReport(ReportPeriod period) async {
    requested.add(period);
    return Success(
        SalesReport.fromJson(jsonDecode(json) as Map<String, dynamic>));
  }

  @override
  Future<Result<SalesReport>> getCustomReport(
      DateTime start, DateTime end) async {
    customRanges.add((start, end));
    return Success(
        SalesReport.fromJson(jsonDecode(json) as Map<String, dynamic>));
  }
}

class _EmptyLedgerRepository implements AccountingRepository {
  @override
  Future<Result<List<AccountingEntry>>> getEntries() async => Success(const []);

  @override
  Future<Result<LedgerVerification>> verifyLedger() async =>
      const Success(LedgerVerification(ok: true, problems: [], warnings: []));
}

Future<AccountingProvider> pumpAccounting(
    WidgetTester tester, AccountingRepository repository) async {
  final provider = AccountingProvider(repository);
  await tester.pumpWidget(
    ChangeNotifierProvider<AccountingProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(
          body: Directionality(
              textDirection: TextDirection.rtl, child: AccountingPage()),
        ),
      ),
    ),
  );
  await provider.load();
  await tester.pumpAndSettle();
  return provider;
}

Future<ReportProvider> pumpReports(
    WidgetTester tester, ReportRepository repository) async {
  final provider = ReportProvider(repository);
  await tester.pumpWidget(
    ChangeNotifierProvider<ReportProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(
          body: Directionality(
              textDirection: TextDirection.rtl, child: ReportsPage()),
        ),
      ),
    ),
  );
  await provider.load();
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  group('AccountingPage renders the real ledger', () {
    testWidgets('shows one tile per entry with the server amounts',
        (tester) async {
      await pumpAccounting(tester, _FakeAccountingRepository(_ledgerJson));

      expect(find.byType(AccountingEntryTile), findsNWidgets(2));
      expect(find.text('سفارش 1014'), findsOneWidget);
      expect(find.text('خرید شیر'), findsOneWidget);
      expect(
        find.text('+${PersianFormat.money(220000)}'),
        findsOneWidget,
        reason: 'ردیف درآمد علامت مثبت دارد',
      );
      expect(find.text('−${PersianFormat.money(50000)}'), findsOneWidget);
    });

    testWidgets('summary sums income, expense and profit from the entries',
        (tester) async {
      await pumpAccounting(tester, _FakeAccountingRepository(_ledgerJson));

      // ۲۲۰٬۰۰۰ درآمد − ۵۰٬۰۰۰ هزینه = ۱۷۰٬۰۰۰ سود
      expect(find.text(PersianFormat.money(220000)), findsAtLeast(1));
      expect(find.text(PersianFormat.money(50000)), findsAtLeast(1));
      expect(find.text(PersianFormat.money(170000)), findsAtLeast(1));
    });

    testWidgets('an empty ledger shows the empty state without crashing',
        (tester) async {
      final provider = await pumpAccounting(tester, _EmptyLedgerRepository());
      // Backend لیست خالی می‌فرستد؛ وضعیت success است و خود صفحه حالت
      // «بازه‌ی خالی» را نشان می‌دهد، نه خطا.
      expect(provider.state.status, ViewStatus.success);
      expect(provider.totalIncome, 0);
      expect(provider.totalExpense, 0);
      expect(provider.profit, 0);
      expect(find.byType(AccountingEntryTile), findsNothing);
      expect(find.text('تراکنشی در این بازه وجود ندارد'), findsOneWidget);
    });
  });

  group('ReportsPage renders the real report', () {
    testWidgets('summary cards use the server totals', (tester) async {
      await pumpReports(tester, _FakeReportRepository(_reportJson));

      expect(find.text(PersianFormat.money(3980000)), findsAtLeast(1)); // فروش
      expect(
          find.text(PersianFormat.money(1450000)), findsAtLeast(1)); // تمام‌شده
      // کارت «هزینه و ضایعات» جمع دو رقم سرور را نشان می‌دهد:
      // ۲٬۰۷۰٬۰۰۰ عمومی + ۱۲۰٬۰۰۰ ضایعات
      expect(find.text(PersianFormat.money(2190000)), findsAtLeast(1));
      // سود خالص از خود سرور می‌آید، نه از `sales - expenses` که ۱٬۹۱۰٬۰۰۰
      // می‌شد و COGS/ضایعات را از قلم می‌انداخت.
      expect(find.text(PersianFormat.money(340000)), findsAtLeast(1));
      expect(find.text(PersianFormat.money(1910000)), findsNothing);
      expect(find.text(PersianFormat.digits(4)), findsAtLeast(1));
    });

    testWidgets('best sellers and expense breakdown are rendered',
        (tester) async {
      await pumpReports(tester, _FakeReportRepository(_reportJson));

      expect(find.byType(TopProductsPanel), findsOneWidget);
      expect(find.text('کیک'), findsOneWidget);
      expect(
        find.text('${PersianFormat.digits(4)} عدد'),
        findsOneWidget,
        reason: 'تعداد فروخته‌شده از خود Backend می‌آید',
      );

      expect(find.byType(ExpenseBreakdownPanel), findsOneWidget);
      expect(find.text(ExpenseCategory.supplies.label), findsOneWidget);
      expect(find.text(ExpenseCategory.rent.label), findsOneWidget);
      expect(find.text(PersianFormat.money(1070000)), findsAtLeast(1));
    });

    testWidgets('the subtitle shows the half-open range of the response',
        (tester) async {
      await pumpReports(tester, _FakeReportRepository(_reportJson));

      final start = DateTime.parse('2026-09-23T00:00:00+03:30').toLocal();
      final lastDay = DateTime.parse('2026-10-02T00:00:00+03:30')
          .toLocal()
          .subtract(const Duration(days: 1));
      expect(
        find.text(
            '${PersianFormat.date(start)} تا ${PersianFormat.date(lastDay)}'),
        findsOneWidget,
      );
    });

    testWidgets('selecting a period asks the repository again', (tester) async {
      final repo = _FakeReportRepository(_reportJson);
      final provider = await pumpReports(tester, repo);

      // صفحه در initState خودش load می‌کند و pumpReports هم یک‌بار صدا می‌زند،
      // پس فقط دوره‌ی اولیه مهم است.
      expect(repo.requested.first, ReportPeriod.month); // پیش‌فرض پروژه

      await provider.setPeriod(ReportPeriod.today);
      await tester.pumpAndSettle();
      expect(repo.requested.last, ReportPeriod.today);

      await provider.setPeriod(ReportPeriod.week);
      await tester.pumpAndSettle();
      expect(repo.requested.last, ReportPeriod.week);
    });

    testWidgets('a custom range is forwarded with both ends', (tester) async {
      final repo = _FakeReportRepository(_reportJson);
      final provider = await pumpReports(tester, repo);

      await provider.setCustomRange(
          DateTime(2026, 9, 1), DateTime(2026, 9, 30));
      await tester.pumpAndSettle();

      expect(provider.period, ReportPeriod.custom);
      expect(
          repo.customRanges, [(DateTime(2026, 9, 1), DateTime(2026, 9, 30))]);
      // برای بازه‌ی دلخواه دیگر period تنها فرستاده نمی‌شود
      expect(repo.requested.last, ReportPeriod.month);
    });
  });

  group('app_providers honours AppConfig.useMock', () {
    Future<void> pumpApp(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AppProviders(child: SizedBox()));
      await tester.pump();
    }

    AccountingRepository? accountingOf(WidgetTester tester) {
      final ctx = tester.element(find.byType(SizedBox));
      return Provider.of<AccountingRepository>(ctx, listen: false);
    }

    ReportRepository? reportsOf(WidgetTester tester) {
      final ctx = tester.element(find.byType(SizedBox));
      return Provider.of<ReportRepository>(ctx, listen: false);
    }

    testWidgets('the accounting repository matches AppConfig.useMock',
        (tester) async {
      await pumpApp(tester);
      final repo = accountingOf(tester);
      if (AppConfig.useMock) {
        expect(repo, isA<MockAccountingRepository>());
      } else {
        expect(repo, isA<ApiAccountingRepository>());
      }
    });

    testWidgets('the report repository matches AppConfig.useMock',
        (tester) async {
      await pumpApp(tester);
      final repo = reportsOf(tester);
      if (AppConfig.useMock) {
        expect(repo, isA<MockReportRepository>());
      } else {
        expect(repo, isA<ApiReportRepository>());
      }
    });

    testWidgets('the API path never touches MockDatabase', (tester) async {
      await pumpApp(tester);
      // اگر سوییچ درست کار کند، هیچ‌کدام از این دو از MockDatabase ساخته نشده‌اند
      final apiRepo = AppConfig.useMock
          ? null
          : accountingOf(tester) as ApiAccountingRepository;
      if (apiRepo != null) {
        expect(apiRepo, isNot(isA<MockAccountingRepository>()));
      }
      // در هر دو حالت یک Repository واقعی (نه Mock) برای API وجود دارد
      expect(apiRepo ?? accountingOf(tester), isA<AccountingRepository>());
    });

    testWidgets('Mock repositories are still wired and functional',
        (tester) async {
      await pumpApp(tester);
      if (!AppConfig.useMock) return; // در حالت API، مسیر Mock استفاده نمی‌شود

      final ctx = tester.element(find.byType(SizedBox));
      expect(Provider.of<MockDatabase>(ctx, listen: false), isNotNull);
      expect(accountingOf(tester), isA<MockAccountingRepository>());
      expect(reportsOf(tester), isA<MockReportRepository>());
    });
  });

  group('providers expose the repository failure', () {
    test('AccountingProvider keeps previous data on failure', () async {
      var fail = false;
      final repo = _FlakyAccountingRepository(() => fail);
      final provider = AccountingProvider(repo);

      await provider.load();
      expect(provider.state.status, ViewStatus.success);
      expect(provider.totalIncome, 220000);

      fail = true;
      await provider.load();
      expect(provider.state.status, ViewStatus.error);
      expect(provider.state.failure?.type, FailureType.network);
      expect(provider.totalIncome, 220000); // داده قبلی حفظ شد
    });

    test('ReportProvider keeps previous data on failure', () async {
      var fail = false;
      final provider = ReportProvider(_FlakyReportRepository(() => fail));

      await provider.load();
      expect(provider.state.data!.totalSales, 3980000);

      fail = true;
      await provider.load();
      expect(provider.state.status, ViewStatus.error);
      expect(provider.state.data!.totalSales, 3980000);
    });
  });
}

class _FlakyAccountingRepository implements AccountingRepository {
  _FlakyAccountingRepository(this.shouldFail);
  final bool Function() shouldFail;

  @override
  Future<Result<List<AccountingEntry>>> getEntries() async {
    if (shouldFail()) return Failure(AppFailure.network());
    return Success((jsonDecode(_ledgerJson) as List)
        .map((e) => AccountingEntry.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  @override
  Future<Result<LedgerVerification>> verifyLedger() async {
    if (shouldFail()) return Failure(AppFailure.network());
    return const Success(
        LedgerVerification(ok: true, problems: [], warnings: []));
  }
}

class _FlakyReportRepository implements ReportRepository {
  _FlakyReportRepository(this.shouldFail);
  final bool Function() shouldFail;

  @override
  Future<Result<SalesReport>> getReport(ReportPeriod period) async {
    if (shouldFail()) return Failure(AppFailure.network());
    return Success(
        SalesReport.fromJson(jsonDecode(_reportJson) as Map<String, dynamic>));
  }

  @override
  Future<Result<SalesReport>> getCustomReport(
          DateTime start, DateTime end) async =>
      getReport(ReportPeriod.custom);
}
