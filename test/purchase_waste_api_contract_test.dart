// قرارداد بین پاسخ واقعی Django و مدل‌های Flutter.
// JSONهای این تست عیناً از پاسخ واقعی
// GET /api/v1/inventory/purchases/ و /api/v1/inventory/wastes/ کپی شده‌اند.
import 'dart:convert';

import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/models/purchase.dart';
import 'package:cafe_book_admin/models/waste.dart';
import 'package:cafe_book_admin/models/waste_reason.dart';
import 'package:flutter_test/flutter_test.dart';

/// پاسخ واقعی POST/GET خرید (Django، inventory/serializers.purchase_dict).
const String purchasesJson = '''
[{"id":2,"item_id":1,"item_name":"شیر","unit":"ml","quantity":20.0,
  "unit_cost":100.0,"total_cost":2000.0,"account":"bank",
  "purchased_at":"2026-10-05T21:51:25.185998+00:00","note":"خرید تستی"}]
''';

/// پاسخ واقعی ضایعات (Django، inventory/serializers.waste_dict).
const String wastesJson = '''
[{"id":3,"item_id":1,"item_name":"شیر","unit":"ml","quantity":25.0,
  "unit_cost":100.0,"total_cost":2500.0,"reason":"spoiled",
  "wasted_at":"2026-10-05T21:51:25.188288+00:00","note":"شیر گازدار"}]
''';

void main() {
  group('Purchase.fromJson parses the real Django response', () {
    final list = (jsonDecode(purchasesJson) as List)
        .map((j) => Purchase.fromJson(j as Map<String, dynamic>))
        .toList();

    test('maps every field', () {
      expect(list, hasLength(1));
      final p = list.single;
      expect(p.id, 2);
      expect(p.itemId, 1);
      expect(p.itemName, 'شیر');
      expect(p.unit, BaseUnit.milliliter);
      expect(p.quantity, 20.0);
      expect(p.unitCost, 100.0);
      expect(p.totalCost, 2000.0);
      expect(p.note, 'خرید تستی');
      // حسابی که پول خرید از آن کم شده، نه روش پرداخت مشتری
      expect(p.account, CashAccount.bank);
      expect(
        p.purchasedAt.isAtSameMomentAs(
          DateTime.parse('2026-10-05T21:51:25.185998+00:00'),
        ),
        isTrue,
      );
    });

    test('a missing account degrades to cash instead of crashing', () {
      final p = Purchase.fromJson({
        'id': 1,
        'item_id': 1,
        'item_name': 'شیر',
        'unit': 'ml',
        'quantity': 1.0,
        'unit_cost': 1.0,
        'purchased_at': '2026-10-05T21:51:25+00:00',
      });
      expect(p.account, CashAccount.cash);
      expect(p.note, isNull);
    });

    test('round-trips through toJson', () {
      final again = Purchase.fromJson(list.first.toJson());
      expect(again.id, list.first.id);
      expect(again.itemName, list.first.itemName);
      expect(again.quantity, list.first.quantity);
    });
  });

  group('Waste.fromJson parses the real Django response', () {
    final list = (jsonDecode(wastesJson) as List)
        .map((j) => Waste.fromJson(j as Map<String, dynamic>))
        .toList();

    test('maps every field', () {
      final w = list.single;
      expect(w.id, 3);
      expect(w.itemId, 1);
      expect(w.itemName, 'شیر');
      expect(w.quantity, 25.0); // مثبت، حتی اگر در دفتر حرکت منفی ذخیره شود
      expect(w.unitCost, 100.0);
      expect(w.totalCost, 2500.0);
      expect(w.reason, WasteReason.spoiled);
      expect(w.note, 'شیر گازدار');
      expect(
        w.wastedAt.isAtSameMomentAs(
          DateTime.parse('2026-10-05T21:51:25.188288+00:00'),
        ),
        isTrue,
      );
    });

    test('round-trips through toJson', () {
      final again = Waste.fromJson(list.single.toJson());
      expect(again.id, list.single.id);
      expect(again.reason, list.single.reason);
    });
  });

  group(
      'draft payload matches what ApiPurchaseRepository/ApiWasteRepository POST',
      () {
    test('purchase draft', () {
      final draft = PurchaseDraft(
        itemId: 9,
        quantity: 5,
        unitCost: 12500,
        note: 'خرید هفتگی',
      ).normalized();
      expect(draft.itemId, 9);
      expect(draft.quantity, 5.0);
      expect(draft.unitCost, 12500.0);
    });

    test('waste draft sends a reason the backend accepts', () {
      // مقادیر apiValue دقیقاً با choices دیتابیس یکی هستند.
      const backendChoices = {
        'expired',
        'damaged',
        'spoiled',
        'preparation_error',
        'other',
      };
      for (final r in WasteReason.values) {
        expect(backendChoices, contains(r.apiValue));
      }
      final draft = WasteDraft(
        itemId: 9,
        quantity: 5,
        reason: WasteReason.spoiled,
      ).normalized();
      expect(draft.reason.apiValue, 'spoiled');
    });
  });
}
