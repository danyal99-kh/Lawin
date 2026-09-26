import 'api_enum.dart';
import 'enums.dart';

/// یک قلم دستور مصرف: مقدار مصرفی یک کالای انبار (بر پایه‌ی واحد پایه‌ی همان کالا)
/// برای تولید «یک واحد» از محصول.
class RecipeItem {
  const RecipeItem({
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.unit,
    required this.quantity,
  });

  final int inventoryItemId;
  final String inventoryItemName;
  final BaseUnit unit;

  /// مقدار مصرفی بر پایه‌ی [unit].
  final double quantity;

  RecipeItem copyWith({double? quantity}) => RecipeItem(
        inventoryItemId: inventoryItemId,
        inventoryItemName: inventoryItemName,
        unit: unit,
        quantity: quantity ?? this.quantity,
      );

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
        inventoryItemId: json['inventory_item_id'] as int,
        inventoryItemName: json['inventory_item_name'] as String,
        unit: parseApiEnum(BaseUnit.values, json['unit'],
            fallback: BaseUnit.piece),
        quantity: (json['quantity'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'inventory_item_id': inventoryItemId,
        'inventory_item_name': inventoryItemName,
        'unit': unit.apiValue,
        'quantity': quantity,
      };
}

/// دستور مصرف یک محصول. وقتی سفارش پرداخت می‌شود (مرحله ۸)، موجودی انبار
/// بر همین اساس کسر خواهد شد.
class Recipe {
  const Recipe({
    required this.productId,
    required this.productName,
    this.items = const [],
  });

  final int productId;
  final String productName;
  final List<RecipeItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isDefined => items.isNotEmpty;

  /// بهای تمام‌شده‌ی یک واحد، بر اساس قیمت خرید فعلیِ کالاهای انبار.
  int costFor(Map<int, double> unitCostByItem) => items
      .fold<double>(
          0,
          (sum, i) =>
              sum + i.quantity * (unitCostByItem[i.inventoryItemId] ?? 0))
      .round();

  Recipe copyWith({List<RecipeItem>? items}) => Recipe(
      productId: productId,
      productName: productName,
      items: items ?? this.items);

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => RecipeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'items': items.map((i) => i.toJson()).toList(),
      };
}
