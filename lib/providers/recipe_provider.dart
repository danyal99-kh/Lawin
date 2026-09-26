import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/inventory_item.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

/// وضعیت دستور مصرف همه‌ی محصولات. UI فقط این Provider را می‌خواند.
class RecipeProvider extends ChangeNotifier {
  RecipeProvider(this._repository);

  final RecipeRepository _repository;

  ViewState<List<Recipe>> _state = const ViewState.initial();
  ViewState<List<Recipe>> get state => _state;
  List<Recipe> get all => _state.data ?? const [];

  List<InventoryItem> _inventoryItems = const [];
  List<InventoryItem> get inventoryItems => _inventoryItems;

  bool _disposed = false;

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<Recipe>>.loading(previous: previous);
    _notify();
    final recipesFuture = _repository.getRecipes();
    final itemsFuture = _repository.getInventoryItems();
    final recipesResult = await recipesFuture;
    final itemsResult = await itemsFuture;
    _inventoryItems = itemsResult.dataOrNull ?? _inventoryItems;
    _state = recipesResult.when<ViewState<List<Recipe>>>(
      success: (list) => ViewState<List<Recipe>>.success(list),
      failure: (f) => ViewState<List<Recipe>>.error(f, previous: previous),
    );
    _notify();
  }

  /// ذخیره‌ی دستور مصرف یک محصول. null یعنی موفق.
  Future<AppFailure?> save(int productId, List<RecipeItem> items) async {
    final result = await _repository.save(productId, items);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    final saved = result.dataOrNull!;
    _state = ViewState<List<Recipe>>.success([
      for (final r in all) r.productId == productId ? saved : r,
    ]);
    _notify();
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
