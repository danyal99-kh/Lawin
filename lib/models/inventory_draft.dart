// lib/models/inventory_draft.dart
import 'enums.dart';

/// داده‌ی فرم ایجاد/ویرایش کالای انبار. موجودی فعلی فقط هنگام ایجاد
/// (به‌صورت موجودی اولیه) قابل تعیین است؛ بعد از آن فقط با خرید یا ضایعات تغییر می‌کند.
class InventoryItemDraft {
  const InventoryItemDraft({
    required this.name,
    required this.unit,
    this.minStock = 0,
    this.unitCost = 0,
    this.description,
    this.initialStock = 0,
  });

  final String name;
  final BaseUnit unit;
  final double minStock;
  final double unitCost;
  final String? description;
  final double initialStock;

  /// حذف فاصله‌های اضافه و اطمینان از عدم منفی بودن مقادیر عددی.
  InventoryItemDraft normalized() {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return InventoryItemDraft(
      name: name.trim(),
      unit: unit,
      minStock: minStock < 0 ? 0 : minStock,
      unitCost: unitCost < 0 ? 0 : unitCost,
      description: clean(description),
      initialStock: initialStock < 0 ? 0 : initialStock,
    );
  }
}
