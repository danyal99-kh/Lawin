// تست Repositoryهای حسابداری و گزارش: مسیر درخواست، query دوره‌ها و
// تبدیل خطای Django به AppFailure.
// از MockClient استفاده می‌شود تا شبکه‌ای در کار نباشد ولی دقیقاً همان
// چیزی تست شود که Flutter روی آن real HTTP می‌فرستد.
import 'dart:convert';

import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/report.dart';
import 'package:cafe_book_admin/repositories/api/api_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

/// پاسخ گزارش معتبر با صفرها (بازه‌ی بدون داده).
final String _okReport = jsonEncode({
  'start': '2026-10-01T00:00:00+03:30',
  'end': '2026-10-02T00:00:00+03:30',
  'total_sales': 0,
  'total_expenses': 0,
  'order_count': 0,
  'items_sold_count': 0,
  'top_products': <dynamic>[],
  'expenses_by_category': <dynamic>[],
  'daily_points': [
    {'date': '2026-10-01', 'sales': 0, 'expenses': 0}
  ],
});

/// دفتر حسابداری با یک ردیف درآمد و یک ردیف هزینه.
final String _okLedger = jsonEncode([
  {
    'id': 'income-12',
    'type': 'income',
    'title': 'سفارش 1014',
    'subtitle': 'میز 2 • نقدی',
    'amount': 220000,
    'date': '2026-10-01T08:40:00+03:30',
  },
  {
    'id': 'expense-5',
    'type': 'expense',
    'title': 'خرید شیر',
    'subtitle': 'خرید مواد اولیه',
    'amount': 50000,
    'date': '2026-10-01T09:15:00+03:30',
  },
]);

/// پاسخ واقعی بازرسی دفتر با ایراد (Django، core/ledger.py health).
/// کدها عیناً همان رشته‌هایی هستند که بک‌اند می‌فرستد.
final String _okVerification = jsonEncode({
  'ok': false,
  'problems': [
    {
      'code': 'order_sale_mismatch',
      'order_id': '1014',
      'detail': 'ورودی فروش 0 ≠ مبلغ سفارش 220000',
    },
    {
      'code': 'inventory_mismatch',
      'detail': 'موجودی دفتر 50000 ≠ ارزش کالا 0',
    },
  ],
  'warnings': [
    {
      'code': 'negative_balance',
      'detail': 'مانده‌ی cash منفی است',
    },
  ],
});

void main() {
  /// یک مشتری ساختگی که آخرین درخواست را نگه می‌دارد و پاسخ تعیین‌شده
  /// را برمی‌گرداند.
  late Uri lastRequest;
  late Map<String, String> lastHeaders;
  MockClient clientReturning(int status, String body) =>
      MockClient((req) async {
        lastRequest = req.url;
        lastHeaders = req.headers;
        return http.Response(body, status,
            headers: {'content-type': 'application/json'});
      });

  group('ApiAccountingRepository', () {
    test('GETs the transactions endpoint and sends the token', () async {
      final repo = ApiAccountingRepository(
        ApiClient(_FakeTokenStorage(), client: clientReturning(200, _okLedger)),
      );

      final result = await repo.getEntries();
      expect(result.failureOrNull, isNull);

      final entries = result.dataOrNull!;
      expect(entries, hasLength(2));
      expect(entries.firstWhere((e) => e.isIncome).amount, 220000);
      expect(entries.firstWhere((e) => !e.isIncome).amount, 50000);

      expect(lastRequest.path, '/api/v1/accounting/transactions/');
      expect(lastRequest.query, isEmpty);
      expect(lastHeaders['Authorization'], 'Token test-token');
    });

    test('an empty ledger is a valid empty list', () async {
      final repo = ApiAccountingRepository(
          ApiClient(_FakeTokenStorage(), client: clientReturning(200, '[]')));
      final result = await repo.getEntries();
      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isEmpty);
    });

    test('401 becomes AppFailure.unauthorized and fires onUnauthorized',
        () async {
      final api = ApiClient(_FakeTokenStorage(),
          client: clientReturning(
              401,
              jsonEncode({
                'error': {'code': 'unauthorized', 'message': 'نشست منقضی'}
              })));
      var fired = 0;
      api.onUnauthorized = () => fired++;

      final result = await ApiAccountingRepository(api).getEntries();
      expect(result.failureOrNull!.type, FailureType.unauthorized);
      expect(fired, 1);
    });

    test('verifyLedger GETs the verify endpoint and maps problems', () async {
      final repo = ApiAccountingRepository(
        ApiClient(_FakeTokenStorage(),
            client: clientReturning(200, _okVerification)),
      );

      final result = await repo.verifyLedger();
      expect(result.failureOrNull, isNull);
      final v = result.dataOrNull!;
      expect(v.ok, isFalse);
      expect(v.problems, hasLength(2));
      expect(v.problems.first.code, 'order_sale_mismatch');
      expect(v.problems.first.detail, contains('220000'));
      expect(v.problems.map((i) => i.code),
          containsAll(['order_sale_mismatch', 'inventory_mismatch']));
      expect(v.warnings.single.code, 'negative_balance');
      expect(v.hasWarnings, isTrue);

      expect(lastRequest.path, '/api/v1/accounting/verify/');
      expect(lastRequest.query, isEmpty);
      expect(lastHeaders['Authorization'], 'Token test-token');
    });

    test('a clean ledger is ok with empty problems and warnings', () async {
      final repo = ApiAccountingRepository(
        ApiClient(_FakeTokenStorage(),
            client: clientReturning(
                200, jsonEncode({'ok': true, 'problems': [], 'warnings': []}))),
      );
      final v = (await repo.verifyLedger()).dataOrNull!;
      expect(v.ok, isTrue);
      expect(v.problems, isEmpty);
      expect(v.warnings, isEmpty);
    });

    test('a body that is not the verify shape is a failure, not a crash',
        () async {
      // «ok» باید bool باشد؛ یک رشته یعنی سرور چیزی غیرمنتظره برگردانده.
      final repo = ApiAccountingRepository(
        ApiClient(_FakeTokenStorage(),
            client: clientReturning(200, jsonEncode({'ok': 'yes'}))),
      );
      final result = await repo.verifyLedger();
      expect(result.failureOrNull, isNotNull);
      expect(result.dataOrNull, isNull);
    });
  });

  group('ApiReportRepository periods', () {
    Future<Uri> requestFor(ReportPeriod p) async {
      final repo = ApiReportRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(200, _okReport)));
      final result = await repo.getReport(p);
      expect(result.failureOrNull, isNull, reason: p.apiValue);
      expect(result.dataOrNull, isA<SalesReport>());
      return lastRequest;
    }

    test('today sends period=today', () async {
      final url = await requestFor(ReportPeriod.today);
      expect(url.path, '/api/v1/reports/');
      expect(url.queryParameters['period'], 'today');
      expect(url.queryParameters.containsKey('start'), isFalse);
      expect(url.queryParameters.containsKey('end'), isFalse);
    });

    test('week sends period=week', () async {
      expect((await requestFor(ReportPeriod.week)).queryParameters['period'],
          'week');
    });

    test('month sends period=month', () async {
      expect((await requestFor(ReportPeriod.month)).queryParameters['period'],
          'month');
    });

    test('custom sends period, start and end as YYYY-MM-DD', () async {
      final repo = ApiReportRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(200, _okReport)));
      final result = await repo.getCustomReport(
          DateTime(2026, 9, 1), DateTime(2026, 9, 30));
      expect(result.failureOrNull, isNull);
      expect(lastRequest.queryParameters['period'], 'custom');
      expect(lastRequest.queryParameters['start'], '2026-09-01');
      expect(lastRequest.queryParameters['end'], '2026-09-30');
    });

    test('a single-day custom range keeps both ends', () async {
      final repo = ApiReportRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(200, _okReport)));
      await repo.getCustomReport(DateTime(2026, 9, 1), DateTime(2026, 9, 1));
      expect(lastRequest.queryParameters['start'], '2026-09-01');
      expect(lastRequest.queryParameters['end'], '2026-09-01');
    });
  });

  group('ApiReportRepository parses the response', () {
    test('maps summary, products, expenses and trend', () async {
      final body = jsonEncode({
        'start': '2026-09-23T00:00:00+03:30',
        'end': '2026-10-02T00:00:00+03:30',
        'total_sales': 3980000,
        'total_expenses': 2070000,
        'order_count': 4,
        'items_sold_count': 11,
        'top_products': [
          {
            'product_id': 3,
            'product_name': 'کیک',
            'quantity': 4,
            'revenue': 440000
          }
        ],
        'expenses_by_category': [
          {'category': 'supplies', 'amount': 1070000}
        ],
        'daily_points': [
          {
            'date': '2026-10-01',
            'sales': 95000,
            'expenses': 1000000,
            'cogs': 0,
            'waste': 0,
            'profit': -905000
          }
        ],
      });
      final repo = ApiReportRepository(
          ApiClient(_FakeTokenStorage(), client: clientReturning(200, body)));

      final report = (await repo.getReport(ReportPeriod.month)).dataOrNull!;
      expect(report.totalSales, 3980000);
      // سود از خود سرور خوانده می‌شود؛ صفر یعنی فیلد در پاسخ نبوده.
      expect(report.netProfit, 0);
      expect(report.topProducts.single.productName, 'کیک');
      expect(report.expensesByCategory.single.amount, 1070000);
      expect(report.dailyPoints.single.profit, -905000);
    });
  });

  group('ApiReportRepository errors', () {
    Future<Result<SalesReport>> callWith(int status, String body) {
      final repo = ApiReportRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(status, body)));
      return repo.getReport(ReportPeriod.month);
    }

    test('invalid period is AppFailure.validation with the server message',
        () async {
      final result = await callWith(
          400,
          jsonEncode({
            'error': {
              'code': 'validation',
              'message': 'نوع بازه‌ی گزارش نامعتبر است.'
            }
          }));
      expect(result.failureOrNull!.type, FailureType.validation);
      expect(
          result.failureOrNull!.userMessage, 'نوع بازه‌ی گزارش نامعتبر است.');
    });

    test('missing start/end is AppFailure.validation', () async {
      final result = await callWith(
          400,
          jsonEncode({
            'error': {
              'code': 'validation',
              'message': 'بازه‌ی زمانی نامعتبر است.'
            }
          }));
      expect(result.failureOrNull!.type, FailureType.validation);
    });

    test('start after end is AppFailure.validation', () async {
      final result = await callWith(
          400,
          jsonEncode({
            'error': {
              'code': 'validation',
              'message': 'تاریخ شروع نباید بعد از تاریخ پایان باشد.'
            }
          }));
      expect(result.failureOrNull!.type, FailureType.validation);
    });

    test('500 is AppFailure.server', () async {
      final result = await callWith(500, jsonEncode({'detail': 'boom'}));
      expect(result.failureOrNull!.type, FailureType.server);
    });

    test('malformed JSON never throws out of the repository', () async {
      final result = await callWith(200, 'not json at all');
      expect(result.failureOrNull, isNotNull);
    });
  });
}
