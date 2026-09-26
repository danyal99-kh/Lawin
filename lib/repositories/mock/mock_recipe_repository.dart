import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/inventory_item.dart';
import '../../models/recipe.dart';
import '../recipe_repository.dart';
import 'mock_database.dart';

/// اعتبارسنجی همان قوانینی است که بعداً Backend اعمال می‌کند.
class MockRecipeRepository implements RecipeRepository {
  MockRecipeRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  AppFailure? _validate(List<RecipeItem> items) {
    if (items.isEmpty) return null; // پاک‌کردن دستور مصرف مجاز است.
    final seen = <int>{};
    for (final item in items) {
      if (!_db.inventoryItems.any((i) => i.id == item.inventoryItemId)) {
        return AppFailure.validation('کالای انبار انتخاب‌شده وجود ندارد.');
      }
      if (item.quantity <= 0) {
        return AppFailure.validation('مقدار مصرفی باید بیشتر از صفر باشد.');
      }
      if (!seen.add(item.inventoryItemId)) {
        return AppFailure.validation(
            'هر کالای انبار فقط یک‌بار قابل افزودن است.');
      }
    }
    return null;
  }

  @override
  Future<Result<List<Recipe>>> getRecipes() async {
    try {
      await _latency();
      final list = [
        for (final p in _db.products)
          Recipe(
            productId: p.id,
            productName: p.name,
            items: List.of(_db.recipeFor(p.id)),
          ),
      ];
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<List<InventoryItem>>> getInventoryItems() async {
    try {
      await _latency();
      return Success(List.of(_db.inventoryItems));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Recipe>> save(int productId, List<RecipeItem> items) async {
    try {
      await _latency();
      final matches = _db.products.where((p) => p.id == productId);
      if (matches.isEmpty) return Failure(AppFailure.notFound());
      final invalid = _validate(items);
      if (invalid != null) return Failure(invalid);
      _db.setRecipe(productId, List.of(items));
      return Success(Recipe(
        productId: productId,
        productName: matches.first.name,
        items: List.of(items),
      ));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
