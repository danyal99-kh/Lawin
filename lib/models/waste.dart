// lib/models/waste.dart
import 'api_enum.dart';
import 'enums.dart';
import 'waste_reason.dart';

/// یک رکورد ضایعات. با ثبت آن، موجودی کالای مربوطه در انبار کم می‌شود.
class Waste {
  const Waste({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitCost,
    required this.reason,
    required this.wastedAt,
    this.note,
  });

  final int id;
  final int itemId;

  /// نام کالا در لحظه‌ی ثبت (اگر بعداً کالا حذف شود، تاریخچه از دست نمی‌رود).
  final String itemName;
  final BaseUnit unit;
  final double quantity;

  /// قیمت خرید هر واحد پایه در لحظه‌ی ثبت (برای محاسبه‌ی ارزش ریالی ضایعات).
  final double unitCost;
  final WasteReason reason;
  final DateTime wastedAt;
  final String? note;

  double get totalCost => quantity * unitCost;

  factory Waste.fromJson(Map<String, dynamic> json) => Waste(
        id: json['id'] as int,
        itemId: json['item_id'] as int,
        itemName: json['item_name'] as String,
        unit: parseApiEnum(BaseUnit.values, json['unit'],
            fallback: BaseUnit.piece),
        quantity: (json['quantity'] as num).toDouble(),
        unitCost: (json['unit_cost'] as num).toDouble(),
        reason: parseApiEnum(WasteReason.values, json['reason'],
            fallback: WasteReason.other),
        wastedAt: DateTime.parse(json['wasted_at'] as String).toLocal(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'item_name': itemName,
        'unit': unit.apiValue,
        'quantity': quantity,
        'unit_cost': unitCost,
        'total_cost': totalCost,
        'reason': reason.apiValue,
        'wasted_at': wastedAt.toUtc().toIso8601String(),
        'note': note,
      };
}

/// داده‌ی فرم ثبت ضایعات.
class WasteDraft {
  const WasteDraft({
    required this.itemId,
    required this.quantity,
    required this.reason,
    this.note,
  });

  final int itemId;
  final double quantity;
  final WasteReason reason;
  final String? note;

  WasteDraft normalized() {
    final t = note?.trim();
    return WasteDraft(
      itemId: itemId,
      quantity: quantity < 0 ? 0 : quantity,
      reason: reason,
      note: (t == null || t.isEmpty) ? null : t,
    );
  }
}
