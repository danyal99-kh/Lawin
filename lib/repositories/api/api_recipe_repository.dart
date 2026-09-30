import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/inventory_item.dart';
import '../../models/recipe.dart';
import '../recipe_repository.dart';

class ApiRecipeRepository implements RecipeRepository {
  ApiRecipeRepository(this._api);
  final ApiClient _api;

  static Recipe _recipe(dynamic j) =>
      Recipe.fromJson(j as Map<String, dynamic>);
  static InventoryItem _item(dynamic j) =>
      InventoryItem.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<Recipe>>> getRecipes() => _api.get(
        ApiEndpoints.recipes,
        (j) => (j as List).map(_recipe).toList(),
      );

  @override
  Future<Result<List<InventoryItem>>> getInventoryItems() => _api.get(
        ApiEndpoints.inventoryItems,
        (j) => (j as List).map(_item).toList(),
      );

  @override
  Future<Result<Recipe>> save(int productId, List<RecipeItem> items) =>
      _api.put(
        ApiEndpoints.productRecipe(productId),
        _recipe,
        body: {
          'items': [
            for (final i in items)
              {
                'inventory_item_id': i.inventoryItemId,
                'quantity': i.quantity,
              }
          ],
        },
      );
}
