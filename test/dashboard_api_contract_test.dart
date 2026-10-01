// قرارداد بین پاسخ واقعی Django و مدل Flutter.
// JSON این تست عیناً پاسخ واقعی GET /api/v1/dashboard/summary/ است
// (کپی‌شده در test/fixtures/dashboard_summary.json، بدون دست‌کاری).
import 'dart:convert';
import 'dart:io';

import 'package:cafe_book_admin/core/utils/persian_format.dart';
import 'package:cafe_book_admin/models/dashboard_summary.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/mock/mock_dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// پاسخ واقعی داشبورد (Django، core/dashboard.py).
Map<String, dynamic> loadRealResponse() =>
    jsonDecode(File('test/fixtures/dashboard_summary.json').readAsStringSync())
        as Map<String, dynamic>;

/// پاسخ «دیتابیس خالی» که Backend برمی‌گرداند (۰ و لیست‌های خالی، نه null و نه خطا).
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

void main() {
  group('DashboardSummary.fromJson parses the real Django response', () {
    final summary = DashboardSummary.fromJson(loadRealResponse());

    test('reads the five money/count numbers without recomputing them', () {
      expect(summary.todaySales, 95000);
      expect(summary.monthSales, 3980000);
      expect(summary.todayExpenses, 1000000);
      expect(summary.monthExpenses, 2070000);
      expect(summary.todayOrderCount, 1);
    });

    test('profit is derived from the server numbers', () {
      expect(summary.todayProfit, 95000 - 1000000); // منفی → کارت قرمز
      expect(summary.monthProfit, 3980000 - 2070000);
    });

    test('tables come with their real status', () {
      expect(summary.tables, hasLength(10));
      expect(summary.tables.first.number, 1);
      expect(summary.tables.first.status, TableStatus.empty);
      expect(
        summary.tables.where((t) => t.status == TableStatus.reserved).length,
        1,
      );
      expect(summary.emptyTables, 9);
      expect(summary.activeTables, 0);
      expect(summary.reservedTables, 1);
      expect(summary.tables.fold(0, (s, t) => s + t.id), 55); // ۱..۱۰
    });

    test('low stock items keep current/min and derive status', () {
      expect(summary.lowStockItems, hasLength(4));
      final milk = summary.lowStockItems.firstWhere((i) => i.name == 'شیر');
      expect(milk.unit, BaseUnit.milliliter);
      expect(milk.currentStock, 300.0);
      expect(milk.minStock, 10000.0);
      expect(milk.unitCost, 55.0);
      expect(milk.isLow, isTrue);
      expect(milk.stockStatus, StockStatus.low);

      final cocoa = summary.lowStockItems.firstWhere((i) => i.name == 'پودر کاکائو');
      expect(cocoa.currentStock, 0.0);
      expect(cocoa.stockStatus, StockStatus.out);
      expect(
        summary.lowStockItems.every((i) => i.currentStock <= i.minStock),
        isTrue,
        reason: 'Backend فقط کالاهای زیر آستانه را می‌فرستد',
      );
    });

    test('recent orders keep number, table, status and items', () {
      expect(summary.recentOrders, hasLength(6));
      final first = summary.recentOrders.first;
      expect(first.number, 1014);
      expect(first.tableNumber, 1);
      expect(first.status, OrderStatus.cancelled);
      expect(first.isFromCustomer, isTrue);
      expect(first.items, hasLength(1));
      expect(first.itemCount, 6);
      expect(first.total, 450000); // از روی آیتم‌ها محاسبه می‌شود
      expect(first.paidAt, isNull);
      expect(first.createdAt.isUtc, isFalse); // به وقت محلی تبدیل شده

      // جدیدترین اول
      final times = summary.recentOrders.map((o) => o.createdAt).toList();
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isFalse);
      }
    });

    test('recent expenses keep title, amount, category and date', () {
      expect(summary.recentExpenses, isNotEmpty);
      final e = summary.recentExpenses.first;
      expect(e.id, 5);
      expect(e.title, 'ییییی');
      expect(e.amount, 1000000);
      expect(e.note, isNull);
      final dates = summary.recentExpenses.map((x) => x.date).toList();
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isFalse);
      }
    });

    test('period is optional and never required for parsing', () {
      // Backend یک بلاک period اضافه می‌فرستد؛ مدل نادیده‌اش می‌گیرد و
      // پاسخ‌های قدیمی/موک بدون period هم باید parse شوند.
      expect(loadRealResponse().containsKey('period'), isTrue);
      expect(
        () => DashboardSummary.fromJson(emptyResponse()),
        returnsNormally,
      );
    });
  });

  group('empty data never crashes and never becomes null', () {
    final summary = DashboardSummary.fromJson(emptyResponse());

    test('numbers are zero and lists are empty', () {
      expect(summary.todaySales, 0);
      expect(summary.monthSales, 0);
      expect(summary.todayExpenses, 0);
      expect(summary.monthExpenses, 0);
      expect(summary.todayOrderCount, 0);
      expect(summary.todayProfit, 0);
      expect(summary.monthProfit, 0);
      expect(summary.tables, isEmpty);
      expect(summary.lowStockItems, isEmpty);
      expect(summary.recentOrders, isEmpty);
      expect(summary.recentExpenses, isEmpty);
      expect(summary.activeTables, 0);
      expect(summary.emptyTables, 0);
      expect(summary.reservedTables, 0);
    });

    test('missing list keys degrade to empty instead of throwing', () {
      final s = DashboardSummary.fromJson({
        'today_sales': 10,
        'month_sales': 10,
        'today_expenses': 0,
        'month_expenses': 0,
        'today_order_count': 0,
      });
      expect(s.recentOrders, isEmpty);
      expect(s.recentExpenses, isEmpty);
    });
  });

  group('MockRepository keeps the same contract (useMock = true)', () {
    test('produces the same 6/5/0 shape from MockDatabase', () {
      final db = MockDatabase.seeded(now: DateTime(2026, 10, 1, 12));
      final s = MockDashboardRepository(db).buildSummary(DateTime(2026, 10, 1, 12));
      expect(s.recentOrders.length, lessThanOrEqualTo(6));
      expect(s.recentExpenses.length, lessThanOrEqualTo(5));
      expect(s.todayOrderCount, greaterThanOrEqualTo(0));
      expect(s.tables, isNotEmpty);
      expect(s.lowStockItems.every((i) => i.isLow), isTrue);
      expect(s.todaySales, greaterThanOrEqualTo(0));
      expect(s.todayExpenses, greaterThanOrEqualTo(0));
      expect(s.monthSales >= s.todaySales || s.todaySales == 0, isTrue);
    });

    test('cancelled orders never reach the today count', () {
      final db = MockDatabase.seeded(now: DateTime(2026, 10, 1, 12));
      final now = DateTime(2026, 10, 1, 12);
      final s = MockDashboardRepository(db).buildSummary(now);
      final startOfDay = DateTime(now.year, now.month, now.day);
      final expected = db.orders
          .where((o) => o.status != OrderStatus.cancelled && !o.createdAt.isBefore(startOfDay))
          .length;
      expect(s.todayOrderCount, expected);
    });
  });

  group('money formatting used by the dashboard', () {
    test('server ints render as Persian Toman', () {
      expect(PersianFormat.money(95000), '۹۵٬۰۰۰ تومان');
      expect(PersianFormat.money(1000000), '۱٬۰۰۰٬۰۰۰ تومان');
      expect(PersianFormat.digits(1014), '۱۰۱۴');
    });
  });
}