// قرارداد بین پاسخ واقعی Django و مدل‌های Flutter.
// JSONهای این تست عیناً از پاسخ واقعی
// GET /api/v1/inventory/purchases/ و /api/v1/inventory/wastes/ کپی شده‌اند.
import 'dart:convert';

import 'package:cafe_book_admin/models/purchase.dart';
import 'package:cafe_book_admin/models/waste.dart';
import 'package:cafe_book_admin/models/waste_reason.dart';
import 'package:flutter_test/flutter_test.dart';

/// پاسخ واقعی POST/GET خرید (Django، inventory/serializers.purchase_dict).
const String purchasesJson = '''
[{"id":24,"item_id":9,"item_name":"شیر تستی","unit":"ml","quantity":20.0,
  "unit_cost":100.0,"total_cost":2000.0,
  "purchased_at":"2026-09-30T17:31:50.592012+00:00","note":null},
 {"id":22,"item_id":9,"item_name":"شیر تستی","unit":"ml","quantity":5.0,
  "unit_cost":12500.0,"total_cost":62500.0,
  "purchased_at":"2026-09-30T17:31:29.813788+00:00","note":"خرید هفتگی"}]
''';

/// پاسخ واقعی ضایعات (Django، inventory/serializers.waste_dict).
const String wastesJson = '''
[{"id":23,"item_id":9,"item_name":"شیر تستی","unit":"ml","quantity":25.0,
  "unit_cost":12500.0,"total_cost":312500.0,"reason":"spoiled",
  "wasted_at":"2026-09-30T17:31:39.362838+00:00","note":null}]
''';

void main() {
  group('Purchase.fromJson parses the real Django response', () {
    final list = (jsonDecode(purchasesJson) as List)
        .map((j) => Purchase.fromJson(j as Map<String, dynamic>))
        .toList();

    test('maps every field', () {
      expect(list, hasLength(2));
      final p = list.last; // خرید «خرید هفتگی»
      expect(p.id, 22);
      expect(p.itemId, 9);
      expect(p.itemName, 'شیر تستی');
      expect(p.quantity, 5.0);
      expect(p.unitCost, 12500.0);
      expect(p.totalCost, 62500.0);
      expect(p.note, 'خرید هفتگی');
      expect(
        p.purchasedAt.isAtSameMomentAs(
          DateTime.parse('2026-09-30T17:31:29.813788+00:00'),
        ),
        isTrue,
      );
    });

    test('null note is accepted', () {
      expect(list.first.note, isNull);
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
      expect(w.id, 23);
      expect(w.itemId, 9);
      expect(w.itemName, 'شیر تستی');
      expect(w.quantity, 25.0); // مثبت، حتی اگر در دفتر حرکت منفی ذخیره شود
      expect(w.unitCost, 12500.0);
      expect(w.totalCost, 312500.0);
      expect(w.reason, WasteReason.spoiled);
      expect(w.note, isNull);
      expect(
        w.wastedAt.isAtSameMomentAs(
          DateTime.parse('2026-09-30T17:31:39.362838+00:00'),
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

  group('draft payload matches what ApiPurchaseRepository/ApiWasteRepository POST', () {
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
