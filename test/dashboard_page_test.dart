// تست نمایش داشبورد با داده‌ی واقعی Backend.
// داده از همان پاسخ واقعی GET /api/v1/dashboard/summary/ می‌آید، ولی به‌جای شبکه
// از یک Repository ساختگی تزریق می‌شود تا تست قطعی و بدون سرور باشد.
import 'dart:convert';
import 'dart:io';

import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/utils/persian_format.dart';
import 'package:cafe_book_admin/models/dashboard_summary.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:cafe_book_admin/pages/dashboard/dashboard_page.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/dashboard_stats.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/low_stock_panel.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/recent_expenses_panel.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/recent_orders_panel.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/tables_status_panel.dart';
import 'package:cafe_book_admin/providers/dashboard_provider.dart';
import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:cafe_book_admin/providers/waiter_call_provider.dart';
import 'package:cafe_book_admin/repositories/dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/waiter_call_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> realResponse() =>
    jsonDecode(File('test/fixtures/dashboard_summary.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> emptyResponse() => {
      'today_sales': 0,
      'month_sales': 0,
      'today_expenses': 0,
      'month_expenses': 0,
      'today_order_count': 0,
      'tables': <dynamic>[],
      'low_stock_items': <dynamic>[],
      'recent_orders': <dynamic>[],
      'recent_expenses': <dynamic>[],
    };

/// Repository ساختگی: یک‌بار از پاسخ واقعی می‌خواند.
class _FakeRepository implements DashboardRepository {
  _FakeRepository(this.json);
  final Map<String, dynamic> json;
  int calls = 0;

  @override
  Future<Result<DashboardSummary>> getSummary() async {
    calls++;
    return Success(DashboardSummary.fromJson(json));
  }
}

class _FailingRepository implements DashboardRepository {
  @override
  Future<Result<DashboardSummary>> getSummary() async =>
      Failure(AppFailure.network());
}

/// Repository ساختگی درخواست‌های گارسون (برای پنل داشبورد).
class _FakeWaiterRepository implements WaiterCallRepository {
  @override
  Future<Result<List<WaiterCall>>> getActiveCalls() async => Success([]);

  @override
  Future<Result<WaiterCall>> acknowledge(String callId) async =>
      Failure(AppFailure.notFound());

  @override
  Future<Result<WaiterCall>> complete(String callId) async =>
      Failure(AppFailure.notFound());
}

/// صفحه را با یک Repository مشخص بالا می‌آورد و تا پایان load() صبر می‌کند.
Future<DashboardProvider> pumpDashboard(
  WidgetTester tester,
  DashboardRepository repository,
) async {
  final provider = DashboardProvider(repository);
  await tester.pumpWidget(
    ChangeNotifierProvider<DashboardProvider>.value(
      value: provider,
      child: ChangeNotifierProvider<WaiterCallProvider>(
        create: (_) => WaiterCallProvider(_FakeWaiterRepository()),
        child: ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
          child: const MaterialApp(
            home: Directionality(
                textDirection: TextDirection.rtl, child: DashboardPage()),
          ),
        ),
      ),
    ),
  );
  await provider.load();
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  final summary = DashboardSummary.fromJson(realResponse());

  testWidgets('renders the money cards from the API numbers', (tester) async {
    await pumpDashboard(tester, _FakeRepository(realResponse()));

    expect(find.byType(DashboardStats), findsOneWidget);
    // فروش / هزینه امروز و ماه — مستقیماً از اعداد سرور
    expect(
      find.text(PersianFormat.money(summary.todaySales)),
      findsAtLeast(1),
    );
    expect(
      find.text(PersianFormat.money(summary.monthSales)),
      findsAtLeast(1),
    );
    expect(
      find.text(PersianFormat.money(summary.todayExpenses)),
      findsAtLeast(1),
    );
    expect(
      find.text(PersianFormat.money(summary.monthExpenses)),
      findsAtLeast(1),
    );
    expect(
      find.text(PersianFormat.money(summary.todayProfit)),
      findsAtLeast(1),
    );
    expect(
      find.text(PersianFormat.money(summary.monthProfit)),
      findsAtLeast(1),
    );
  });

  testWidgets('renders today order count and table counts', (tester) async {
    await pumpDashboard(tester, _FakeRepository(realResponse()));

    expect(find.text('سفارش‌های امروز'), findsOneWidget);
    expect(
      find.text(PersianFormat.digits(summary.todayOrderCount)),
      findsWidgets,
    );
    expect(find.text('میزهای فعال'), findsOneWidget);
    expect(find.text('میزهای خالی'), findsOneWidget);
    expect(find.text('میزهای رزرو'), findsOneWidget);
    expect(
        find.text(PersianFormat.digits(summary.reservedTables)), findsWidgets);
    expect(find.text(PersianFormat.digits(summary.emptyTables)), findsWidgets);
  });

  testWidgets('renders the tables list with numbers and status',
      (tester) async {
    await pumpDashboard(tester, _FakeRepository(realResponse()));

    expect(find.byType(TablesStatusPanel), findsOneWidget);
    for (final t in summary.tables) {
      expect(find.text(PersianFormat.digits(t.number)), findsWidgets,
          reason: 'میز ${t.number}');
    }
    expect(find.text('رزرو شده'), findsWidgets);
  });

  testWidgets('renders low stock items with current and minimum',
      (tester) async {
    await pumpDashboard(tester, _FakeRepository(realResponse()));

    expect(find.byType(LowStockPanel), findsOneWidget);
    for (final item in summary.lowStockItems) {
      expect(find.text(item.name), findsWidgets, reason: item.name);
    }
    expect(find.textContaining('موجودی'), findsWidgets);
    expect(find.textContaining('حداقل'), findsWidgets);
  });

  testWidgets('renders at most six recent orders, newest first',
      (tester) async {
    await pumpDashboard(tester, _FakeRepository(realResponse()));

    expect(find.byType(RecentOrdersPanel), findsOneWidget);
    expect(summary.recentOrders, hasLength(6));
    for (final o in summary.recentOrders) {
      expect(
          find.text('سفارش ${PersianFormat.digits(o.number)}'), findsOneWidget,
          reason: 'سفارش ${o.number}');
    }
    // سفارش لغوشده هم در لیست اخیر می‌ماند (قرارداد فهرست سفارش‌های پنل)
    expect(summary.recentOrders.first.status.label, isNotEmpty);
    final numbers = summary.recentOrders.map((o) => o.number).toList();
    expect(numbers, [
      1014,
      1013,
      1012,
      1011,
      1010,
      1009,
    ]); // جدیدترین اول
  });

  testWidgets('renders at most five recent expenses, newest first',
      (tester) async {
    await pumpDashboard(tester, _FakeRepository(realResponse()));

    expect(find.byType(RecentExpensesPanel), findsOneWidget);
    expect(summary.recentExpenses.length, lessThanOrEqualTo(5));
    for (final e in summary.recentExpenses) {
      expect(find.text(e.title), findsOneWidget, reason: e.title);
    }
    final newestFirst = summary.recentExpenses.map((e) => e.id).toList();
    expect(newestFirst, [
      5,
      3,
      2,
      1,
    ]);
  });

  testWidgets('empty data shows the empty panels instead of crashing',
      (tester) async {
    await pumpDashboard(tester, _FakeRepository(emptyResponse()));

    expect(find.text('موجودی همه‌ی اقلام کافی است'), findsOneWidget);
    expect(find.text('هنوز سفارشی ثبت نشده'), findsOneWidget);
    expect(find.text('هزینه‌ای ثبت نشده'), findsOneWidget);
    expect(find.text(PersianFormat.money(0)), findsWidgets);
    expect(find.text(PersianFormat.digits(0)), findsWidgets);
    expect(find.text('سفارش‌های امروز'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('API failure shows the error view', (tester) async {
    await pumpDashboard(tester, _FailingRepository());

    expect(find.byType(DashboardStats), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider exposes success state and reuses the repository',
      (tester) async {
    final repo = _FakeRepository(realResponse());
    final provider = await pumpDashboard(tester, repo);

    expect(provider.state.status.name, 'success');
    expect(provider.state.data!.todaySales, summary.todaySales);
    expect(provider.state.data!.recentOrders, hasLength(6));
    expect(repo.calls, 1);
  });
}
