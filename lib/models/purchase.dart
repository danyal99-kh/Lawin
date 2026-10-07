// lib/models/purchase.dart
import 'api_enum.dart';
import 'enums.dart';

/// یک رکورد خرید کالای انبار. با ثبت هر خرید، موجودی کالای مربوطه افزایش
/// و قیمت خرید آن به‌روزرسانی می‌شود (میانگین نمی‌گیریم؛ آخرین قیمت خرید مبناست).
class Purchase {
  const Purchase({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitCost,
    required this.purchasedAt,
    this.account = CashAccount.cash,
    this.note,
  });

  final int id;
  final int itemId;

  /// نام کالا در لحظه‌ی خرید (اگر بعداً کالا حذف شود، تاریخچه از دست نمی‌رود).
  final String itemName;
  final BaseUnit unit;
  final double quantity;

  /// قیمت خرید هر واحد پایه در همین خرید (به تومان).
  final double unitCost;
  final DateTime purchasedAt;

  /// پول خرید از کدام حساب کم شده. فرقش با [PaymentMethod] روش پرداختِ
  /// مشتری است: اینجا پولِ *کافه* است.
  final CashAccount account;
  final String? note;

  double get totalCost => quantity * unitCost;

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        id: json['id'] as int,
        itemId: json['item_id'] as int,
        itemName: json['item_name'] as String,
        unit: parseApiEnum(BaseUnit.values, json['unit'],
            fallback: BaseUnit.piece),
        quantity: (json['quantity'] as num).toDouble(),
        unitCost: (json['unit_cost'] as num).toDouble(),
        purchasedAt: DateTime.parse(json['purchased_at'] as String).toLocal(),
        account: parseApiEnum(CashAccount.values, json['account'],
            fallback: CashAccount.cash),
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
        'account': account.apiValue,
        'purchased_at': purchasedAt.toUtc().toIso8601String(),
        'note': note,
      };
}

/// داده‌ی فرم ثبت/ویرایش خرید.
class PurchaseDraft {
  const PurchaseDraft({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    this.account = CashAccount.cash,
    this.note,
  });

  final int itemId;
  final double quantity;
  final double unitCost;
  final CashAccount account;
  final String? note;

  PurchaseDraft normalized() {
    final t = note?.trim();
    return PurchaseDraft(
      itemId: itemId,
      quantity: quantity < 0 ? 0 : quantity,
      unitCost: unitCost < 0 ? 0 : unitCost,
      account: account,
      note: (t == null || t.isEmpty) ? null : t,
    );
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'unit_cost': unitCost,
        'account': account.apiValue,
        'note': note,
      };
}
