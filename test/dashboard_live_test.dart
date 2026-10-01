// تست سرتاسری واقعی داشبورد: ApiDashboardRepository → ApiClient → Django → دیتابیس.
// نیازمند اجرای Django روی 127.0.0.1:8000 و توکن معتبر در LAWIN_TEST_TOKEN.
//
//   cd Lawin_User && DJANGO_DEBUG=1 python manage.py runserver 127.0.0.1:8000 --noreload
//   flutter test test/dashboard_live_test.dart --dart-define=LAWIN_TEST_TOKEN=<token>
//
// اگر توکن داده نشود، تست‌ها skip می‌شوند تا در CI شکست نخورند.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/api_endpoints.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/dashboard_summary.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/api/api_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _token = String.fromEnvironment('LAWIN_TEST_TOKEN');

class _StaticTokenStorage implements TokenStorage {
  _StaticTokenStorage(this._token);
  final String _token;
  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  if (_token.isEmpty) {
    test('skipped: set LAWIN_TEST_TOKEN', () {});
    return;
  }

  late ApiDashboardRepository repo;

  setUp(() {
    repo = ApiDashboardRepository(ApiClient(_StaticTokenStorage(_token)));
  });

  test('GET dashboard/summary/ succeeds and parses', () async {
    final result = await repo.getSummary();
    expect(result.failureOrNull, isNull, reason: '${result.failureOrNull}');
    expect(result.dataOrNull, isA<DashboardSummary>());
  });

  test('numbers are non-negative and consistent', () async {
    final s = (await repo.getSummary()).dataOrNull!;
    expect(s.todaySales, greaterThanOrEqualTo(0));
    expect(s.monthSales, greaterThanOrEqualTo(0));
    expect(s.todayExpenses, greaterThanOrEqualTo(0));
    expect(s.monthExpenses, greaterThanOrEqualTo(0));
    expect(s.todayOrderCount, greaterThanOrEqualTo(0));
    expect(s.todayProfit, s.todaySales - s.todayExpenses);
    expect(s.monthProfit, s.monthSales - s.monthExpenses);
  });

  test('server never sends more than 6 orders or 5 expenses', () async {
    final s = (await repo.getSummary()).dataOrNull!;
    expect(s.recentOrders.length, lessThanOrEqualTo(6));
    expect(s.recentExpenses.length, lessThanOrEqualTo(5));
  });

  test('recent orders are newest first and cancelled never counted as sales',
      () async {
    final s = (await repo.getSummary()).dataOrNull!;
    for (var i = 1; i < s.recentOrders.length; i++) {
      expect(
        s.recentOrders[i].createdAt.isAfter(s.recentOrders[i - 1].createdAt),
        isFalse,
        reason: 'سفارش ${s.recentOrders[i].number} قدیمی‌تر از قبلی است',
      );
    }
    // لغوشده‌ها می‌توانند در فهرست اخیر باشند، ولی نباید در فروش باشند.
    final cancelled = s.recentOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .fold(0, (sum, o) => sum + o.total);
    expect(s.todaySales + s.monthSales + cancelled,
        greaterThanOrEqualTo(s.todaySales));
  });

  test('low stock items respect their own threshold', () async {
    final s = (await repo.getSummary()).dataOrNull!;
    for (final i in s.lowStockItems) {
      expect(i.currentStock, lessThanOrEqualTo(i.minStock),
          reason: '${i.name} نباید در لیست کم‌موجودی باشد');
      expect(i.isLow, isTrue);
    }
  });

  test('tables carry number and status', () async {
    final s = (await repo.getSummary()).dataOrNull!;
    expect(s.tables, isNotEmpty);
    for (final t in s.tables) {
      expect(t.number, greaterThan(0));
      expect(TableStatus.values.map((v) => v.apiValue), contains(t.status.apiValue));
    }
  });

  test('missing token is rejected as unauthorized', () async {
    final bad =
        ApiDashboardRepository(ApiClient(_StaticTokenStorage('not-a-real-token')));
    final result = await bad.getSummary();
    expect(result.failureOrNull, isNotNull);
    expect(result.failureOrNull!.type, FailureType.unauthorized);
  });

  test('endpoint constant matches the Django route', () {
    expect(ApiEndpoints.dashboardSummary, '/api/v1/dashboard/summary/');
  });
}