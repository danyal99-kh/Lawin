// قرارداد بین پاسخ واقعی Django و مدل CafeStatus.
// JSONهای این تست عیناً از GET / POST واقعی `/api/v1/cafe/status/`
// (core.api.cafe_status_dict بک‌اند جنگو) کپی شده‌اند.
import 'dart:convert';

import 'package:cafe_book_admin/core/network/api_endpoints.dart';
import 'package:cafe_book_admin/models/cafe_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// پاسخ GET وقتی هنوز کافه نه باز شده نه بسته (بدون ساختن سطر در دیتابیس).
const String defaultJson =
    '{"is_open": false, "opened_at": null, "closed_at": null}';

/// پاسخ POST `open` واقعی؛ زمان با ISO-8601 و offset یعنی UTC (قرارداد بقیه
/// مدل‌ها) می‌آید و Flutter باید با toLocal نمایش دهد.
const String openJson =
    '{"is_open": true, "opened_at": "2026-10-06T10:51:27.306908+00:00", '
    '"closed_at": null}';

/// پاسخ POST `close` واقعی؛ opened_at نگه داشته می‌شود تا «شروع فعالیت»
/// همان روز دیده شود و closed_at ثبت آخرین فعالیت است.
const String closedJson =
    '{"is_open": false, "opened_at": "2026-10-06T10:51:27.306908+00:00", '
    '"closed_at": "2026-10-06T10:51:27.308970+00:00"}';

Map<String, dynamic> decode(String s) => jsonDecode(s) as Map<String, dynamic>;

void main() {
  group('CafeStatus.fromJson parses the real Django response', () {
    test('endpoint path matches core/api_urls.py', () {
      expect(ApiEndpoints.cafeStatus, '/api/v1/cafe/status/');
    });

    test('a never-opened cafe is closed with no timestamps', () {
      final s = CafeStatus.fromJson(decode(defaultJson));
      expect(s.isOpen, isFalse);
      expect(s.openedAt, isNull);
      expect(s.closedAt, isNull);
    });

    test('open keeps openedAt and clears closedAt', () {
      final s = CafeStatus.fromJson(decode(openJson));
      expect(s.isOpen, isTrue);
      expect(s.closedAt, isNull);
      // ارزش زمانی دقیق: همان لحظه‌ای که سرور ثبت کرده، بعد از toLocal.
      expect(s.openedAt!.toUtc(), DateTime.parse('2026-10-06T10:51:27.306908+00:00'));
    });

    test('close keeps openedAt and sets closedAt', () {
      final s = CafeStatus.fromJson(decode(closedJson));
      expect(s.isOpen, isFalse);
      expect(s.openedAt, isNotNull); // «شروع فعالیت» همان روز حفظ می‌شود
      expect(
        s.closedAt!.toUtc(),
        DateTime.parse('2026-10-06T10:51:27.308970+00:00'),
      );
    });

    test('ISO times are converted to the device local zone', () {
      final s = CafeStatus.fromJson(decode(openJson));
      expect(s.openedAt!.isUtc, isFalse, reason: 'toLocal must be applied');
    });

    test('missing keys fall back to the closed defaults', () {
      // اگر سرور فیلدی حذف کند، خاموش نشویم؛ همان پیش‌فرضِ بسته برگردد.
      final s = CafeStatus.fromJson({'is_open': true});
      expect(s.isOpen, isTrue);
      expect(s.openedAt, isNull);
      expect(s.closedAt, isNull);
      expect(CafeStatus.fromJson(<String, dynamic>{}).isOpen, isFalse);
    });

    test('empty timestamp strings are treated as null', () {
      final s = CafeStatus.fromJson({
        'is_open': false,
        'opened_at': '',
        'closed_at': '',
      });
      expect(s.openedAt, isNull);
      expect(s.closedAt, isNull);
    });
  });
}