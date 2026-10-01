// قرارداد بین پاسخ واقعی Django و مدل‌های Flutter.
// JSONهای این تست عیناً از پاسخ واقعی GET /api/v1/settings/ و
// /api/v1/settings/welcome/ کپی شده‌اند.
import 'dart:convert';

import 'package:cafe_book_admin/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// پاسخ واقعی GET /api/v1/settings/ (Django، core.api.cafe_settings_dict).
const String settingsJson = '''
{"name":"کافه‌کتاب","address":"","phone":"","receipt_note":"",
 "auto_print":true,"low_stock_alert":true,
 "updated_at":"2026-10-01T10:53:21.417320+00:00"}
''';

/// همان پاسخ بعد از یک PATCH واقعی.
const String settingsPatchedJson = '''
{"name":"کافه دانش","address":"خیابان ولیعصر، پلاک ۱۲","phone":"02155443322",
 "receipt_note":"با تشکر از خرید شما","auto_print":false,"low_stock_alert":true,
 "updated_at":"2026-10-01T11:02:04.901233+00:00"}
''';

/// پاسخ واقعی GET /api/v1/settings/welcome/ (قرارداد موجود و حفظ‌شده).
const String welcomeJson = '''
{"title":"به کافه‌کتاب خوش آمدید ☕📚",
 "message":"لحظه‌ای برای خودتان، یک فنجان برای حالتان.",
 "enabled":true,"updated_at":"2026-10-01T10:53:21.390115+00:00"}
''';

Map<String, dynamic> decode(String s) => jsonDecode(s) as Map<String, dynamic>;

void main() {
  group('AppSettings.fromJson parses the real Django response', () {
    test('maps every field', () {
      final s = AppSettings.fromJson(decode(settingsJson));
      expect(s.cafeName, 'کافه‌کتاب');
      expect(s.address, isNull); // رشته خالی در سرور → null
      expect(s.phone, isNull);
      expect(s.receiptFooterNote, isNull);
      expect(s.autoPrintBarOrders, isTrue);
      expect(s.lowStockAlertEnabled, isTrue);
    });

    test('maps a patched response', () {
      final s = AppSettings.fromJson(decode(settingsPatchedJson));
      expect(s.cafeName, 'کافه دانش');
      expect(s.address, 'خیابان ولیعصر، پلاک ۱۲');
      expect(s.phone, '02155443322');
      expect(s.receiptFooterNote, 'با تشکر از خرید شما');
      expect(s.autoPrintBarOrders, isFalse);
      expect(s.lowStockAlertEnabled, isTrue);
    });

    test('uses the Django field names in toJson', () {
      final body = AppSettings.fromJson(decode(settingsPatchedJson)).toJson();
      expect(body.keys,
          containsAll(<String>['name', 'address', 'phone', 'receipt_note',
            'auto_print', 'low_stock_alert']));
      expect(body['name'], 'کافه دانش');
      expect(body.containsKey('cafe_name'), isFalse);
      expect(body.containsKey('updated_at'), isFalse);
    });

    test('round-trips through toJson', () {
      final first = AppSettings.fromJson(decode(settingsPatchedJson));
      final again = AppSettings.fromJson(first.toJson());
      expect(again.cafeName, first.cafeName);
      expect(again.address, first.address);
      expect(again.phone, first.phone);
      expect(again.receiptFooterNote, first.receiptFooterNote);
      expect(again.autoPrintBarOrders, first.autoPrintBarOrders);
      expect(again.lowStockAlertEnabled, first.lowStockAlertEnabled);
    });

    test('missing booleans fall back to enabled', () {
      final s = AppSettings.fromJson({'name': 'کافه‌کتاب'});
      expect(s.autoPrintBarOrders, isTrue);
      expect(s.lowStockAlertEnabled, isTrue);
    });
  });

  group('AppSettingsDraft.normalized', () {
    test('trims and turns blanks into null', () {
      final d = const AppSettingsDraft(
        cafeName: '  کافه‌کتاب  ',
        address: '   ',
        phone: ' 0211234 ',
        receiptFooterNote: ' با تشکر ',
      ).normalized();
      expect(d.cafeName, 'کافه‌کتاب');
      expect(d.address, isNull);
      expect(d.phone, '0211234');
      expect(d.receiptFooterNote, 'با تشکر');
    });
  });

  group('WelcomeSettings keeps the existing welcome contract', () {
    test('maps every field', () {
      final w = WelcomeSettings.fromJson(decode(welcomeJson));
      expect(w.title, 'به کافه‌کتاب خوش آمدید ☕📚');
      expect(w.message, 'لحظه‌ای برای خودتان، یک فنجان برای حالتان.');
      expect(w.enabled, isTrue);
      expect(w.updatedAt, isNotNull);
    });

    test('welcome is not part of AppSettings', () {
      final s = AppSettings.fromJson(decode(settingsJson));
      expect(s.toJson().containsKey('welcome_message'), isFalse);
      expect(decode(settingsJson).containsKey('welcome_message'), isFalse);
    });

    test('toJson sends exactly the writable fields', () {
      final body = WelcomeSettings.fromJson(decode(welcomeJson)).toJson();
      expect(body.keys, containsAll(<String>['title', 'message', 'enabled']));
      expect(body.containsKey('updated_at'), isTrue);
    });

    test('updatedAt is null when the server omits it', () {
      final w = WelcomeSettings.fromJson({'title': 'a', 'message': 'b'});
      expect(w.updatedAt, isNull);
      expect(w.enabled, isTrue);
    });

    test('draft normalization trims both fields', () {
      final d = const WelcomeSettingsDraft(
        title: '  عنوان  ',
        message: '  متن  ',
      ).normalized();
      expect(d.title, 'عنوان');
      expect(d.message, 'متن');
      expect(d.enabled, isTrue);
    });
  });
}
