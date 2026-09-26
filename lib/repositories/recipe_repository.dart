import '../core/errors/result.dart';
import '../models/inventory_item.dart';
import '../models/recipe.dart';

abstract interface class RecipeRepository {
  /// دستور مصرف همه‌ی محصولات؛ محصول بدون دستور مصرف با لیست خالی برمی‌گردد.
  Future<Result<List<Recipe>>> getRecipes();

  /// برای پرکردن گزینه‌های انتخاب در فرم دستور مصرف.
  Future<Result<List<InventoryItem>>> getInventoryItems();

  /// جایگزینی کامل اقلام دستور مصرف یک محصول.
  Future<Result<Recipe>> save(int productId, List<RecipeItem> items);
}
