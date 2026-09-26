// lib/repositories/inventory_repository.dart
import '../core/errors/result.dart';
import '../models/inventory_draft.dart';
import '../models/inventory_item.dart';

abstract interface class InventoryRepository {
  /// همه‌ی کالاهای انبار.
  Future<Result<List<InventoryItem>>> getItems();

  Future<Result<InventoryItem>> create(InventoryItemDraft draft);

  /// واحد پایه و موجودی فعلی از طریق این متد تغییر نمی‌کند.
  Future<Result<InventoryItem>> update(int id, InventoryItemDraft draft);

  /// کالایی که موجودی دارد حذف نمی‌شود (conflict).
  Future<Result<void>> delete(int id);
}
