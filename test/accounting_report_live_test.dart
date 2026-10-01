// تست سرتاسری واقعی: ApiAccountingRepository و ApiReportRepository →
// ApiClient → Django → دیتابیس.
// نیازمند اجرای Django روی 127.0.0.1:8000 و توکن معتبر در LAWIN_TEST_TOKEN.
//
//   cd Lawin && DJANGO_DEBUG=1 DJANGO_SECRET_KEY=... python manage.py runserver 127.0.0.1:8000 --noreload
//   flutter test test/accounting_report_live_test.dart \
//       --dart-define=LAWIN_TEST_TOKEN=<token> \
//       --dart-define=API_BASE_URL=http://127.0.0.1:8000
//
// اگر توکن داده نشود، تست‌ها skip می‌شوند تا در CI شکست نخورند.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/accounting_entry.dart';
import 'package:cafe_book_admin/models/report.dart';
import 'package:cafe_book_admin/repositories/api/api_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_report_repository.dart';
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

  late ApiAccountingRepository accounting;
  late ApiReportRepository reports;
  final api = ApiClient(_StaticTokenStorage(_token));

  setUp(() {
    accounting = ApiAccountingRepository(api);
    reports = ApiReportRepository(api);
  });

  group('GET /accounting/transactions/', () {
    test('returns a parsable ledger', () async {
      final result = await accounting.getEntries();
      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isA<List<AccountingEntry>>());
    });

    test('every row has a real amount and a local date', () async {
      final entries = (await accounting.getEntries()).dataOrNull!;
      for (final e in entries) {
        expect(e.id, isNotEmpty);
        expect(e.title, isNotEmpty);
        expect(e.amount, greaterThanOrEqualTo(0));
        expect(e.date.isUtc, isFalse);
        expect(e.amount, greaterThanOrEqualTo(0));
      }
    });

    test('the newest row comes first', () async {
      final entries = (await accounting.getEntries()).dataOrNull!;
      for (var i = 1; i < entries.length; i++) {
        expect(entries[i].date.isAfter(entries[i - 1].date), isFalse);
      }
    });
  });

  group('GET /reports/', () {
    test('period=today succeeds', () async {
      final r = await reports.getReport(ReportPeriod.today);
      expect(r.failureOrNull, isNull);
      expect(r.dataOrNull!.totalSales, greaterThanOrEqualTo(0));
    });

    test('period=week succeeds', () async {
      final r = await reports.getReport(ReportPeriod.week);
      expect(r.failureOrNull, isNull);
      expect(r.dataOrNull!.dailyPoints, isNotEmpty);
    });

    test('period=month succeeds and uses the jalali month', () async {
      final r = await reports.getReport(ReportPeriod.month);
      expect(r.failureOrNull, isNull);
      final report = r.dataOrNull!;
      // ۷ تا ۱۲ روز شمسی + روزهای گذشته‌ی ماه
      expect(report.dailyPoints.length, inInclusiveRange(28, 31));
      expect(report.end.isAfter(report.start), isTrue);
    });

    test('a custom range is accepted', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final r = await reports.getCustomReport(start, now);
      expect(r.failureOrNull, isNull);
      expect(r.dataOrNull!.orderCount, greaterThanOrEqualTo(0));
    });

    test('start after end is rejected as validation', () async {
      final r = await reports.getCustomReport(
          DateTime(2026, 1, 10), DateTime(2026, 1, 1));
      expect(r.failureOrNull, isNotNull);
      expect(r.failureOrNull!.type, FailureType.validation);
    });

    test('a range wider than a year is rejected as validation', () async {
      final r = await reports.getCustomReport(
          DateTime(2020, 1, 1), DateTime(2026, 1, 1));
      expect(r.failureOrNull!.type, FailureType.validation);
    });

    test('an invalid token is rejected as unauthorized', () async {
      final bad = ApiClient(_StaticTokenStorage('not-a-real-token'));
      expect(
        (await ApiReportRepository(bad).getReport(ReportPeriod.month))
            .failureOrNull!
            .type,
        FailureType.unauthorized,
      );
      expect(
        (await ApiAccountingRepository(bad).getEntries()).failureOrNull!.type,
        FailureType.unauthorized,
      );
    });
  });
}
