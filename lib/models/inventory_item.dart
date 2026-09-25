import 'api_enum.dart';
import 'enums.dart';

/// کالای انبار. مقدار موجودی و حداقل موجودی همیشه بر پایه‌ی واحد پایه (گرم/میلی‌لیتر/عدد) است.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    this.unitCost = 0,
    this.description,
  });

  final int id;
  final String name;
  final BaseUnit unit;
  final double currentStock;
  final double minStock;

  /// قیمت خرید هر «واحد پایه» به تومان (مثلاً هر گرم).
  final double unitCost;
  final String? description;

  StockStatus get stockStatus {
    if (currentStock <= 0) return StockStatus.out;
    if (currentStock <= minStock) return StockStatus.low;
    return StockStatus.ok;
  }

  bool get isLow => stockStatus != StockStatus.ok;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as int,
        name: json['name'] as String,
        unit: parseApiEnum(BaseUnit.values, json['unit'],
            fallback: BaseUnit.piece),
        currentStock: (json['current_stock'] as num).toDouble(),
        minStock: (json['min_stock'] as num).toDouble(),
        unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit.apiValue,
        'current_stock': currentStock,
        'min_stock': minStock,
        'unit_cost': unitCost,
        'description': description,
      };
}
