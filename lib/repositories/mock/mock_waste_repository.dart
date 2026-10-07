// lib/repositories/mock/mock_waste_repository.dart
import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/inventory_item.dart';
import '../../models/waste.dart';
import '../waste_repository.dart';
import 'mock_database.dart';

/// موجودی کالا در همین Repository کم می‌شود؛ بعد از اتصال به Django،
/// Backend این کار را در یک تراکنش انجام می‌دهد.
/// تاریخچه‌ی ضایعات مستقل از MockDatabase نگه داشته می‌شود، اما تغییرات
/// موجودی روی همان MockDatabase مشترک اعمال می‌شود.
class MockWasteRepository implements WasteRepository {
  MockWasteRepository(this._db);

  final MockDatabase _db;
  final List<Waste> _wastes = [];
  int _seq = 0;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  AppFailure? _validate(WasteDraft d, InventoryItem? item) {
    if (item == null) {
      return AppFailure.validation('کالای انتخاب‌شده وجود ندارد.');
    }
    if (d.quantity <= 0) {
      return AppFailure.validation('مقدار ضایعات باید بیشتر از صفر باشد.');
    }
    if (d.quantity > item.currentStock) {
      return AppFailure.insufficientStock(item.name);
    }
    return null;
  }

  @override
  Future<Result<List<Waste>>> getWastes() async {
    try {
      await _latency();
      final list = List<Waste>.of(_wastes)
        ..sort((a, b) => b.wastedAt.compareTo(a.wastedAt));
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Waste>> create(WasteDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final index = _db.inventoryItems.indexWhere((i) => i.id == d.itemId);
      final item = index == -1 ? null : _db.inventoryItems[index];
      final invalid = _validate(d, item);
      if (invalid != null) return Failure(invalid);

      final waste = Waste(
        id: ++_seq,
        itemId: item!.id,
        itemName: item.name,
        unit: item.unit,
        quantity: d.quantity,
        unitCost: item.unitCost,
        reason: d.reason,
        wastedAt: DateTime.now(),
        note: d.note,
      );
      _wastes.add(waste);

      // موجودی کم می‌شود؛ قیمت خرید تغییر نمی‌کند.
      _db.inventoryItems[index] = InventoryItem(
        id: item.id,
        name: item.name,
        unit: item.unit,
        currentStock: item.currentStock - d.quantity,
        minStock: item.minStock,
        unitCost: item.unitCost,
        description: item.description,
      );

      return Success(waste);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  /// موجودی کالا را به‌روز می‌کند. [delta] مثبت یعنی به انبار برمی‌گردد.
  void _applyStock(int index, double delta) {
    final item = _db.inventoryItems[index];
    _db.inventoryItems[index] = InventoryItem(
      id: item.id,
      name: item.name,
      unit: item.unit,
      currentStock: item.currentStock + delta,
      minStock: item.minStock,
      unitCost: item.unitCost,
      description: item.description,
    );
  }

  @override
  Future<Result<Waste>> update(int id, WasteDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final index = _wastes.indexWhere((w) => w.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      if (d.quantity <= 0) {
        return Failure(
            AppFailure.validation('مقدار ضایعات باید بیشتر از صفر باشد.'));
      }
      final old = _wastes[index];
      final itemIndex =
          _db.inventoryItems.indexWhere((i) => i.id == old.itemId);
      if (itemIndex == -1) {
        return Failure(AppFailure.validation('کالای انتخاب‌شده وجود ندارد.'));
      }
      final item = _db.inventoryItems[itemIndex];
      // کم کردن مقدار ضایعات یعنی آن مقدار به انبار برمی‌گردد؛ پس موجودی
      // کافی باید داشته باشیم — دقیقاً مثل بک‌اند.
      final returning = old.quantity - d.quantity;
      if (item.currentStock + returning < 0) {
        return Failure(AppFailure.insufficientStock(item.name));
      }
      final updated = Waste(
        id: old.id,
        itemId: old.itemId,
        itemName: old.itemName,
        unit: old.unit,
        quantity: d.quantity,
        unitCost: item.unitCost,
        reason: d.reason,
        wastedAt: old.wastedAt,
        note: d.note,
      );
      _wastes[index] = updated;
      _applyStock(itemIndex, returning);
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _latency();
      final index = _wastes.indexWhere((w) => w.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final removed = _wastes.removeAt(index);
      final itemIndex =
          _db.inventoryItems.indexWhere((i) => i.id == removed.itemId);
      if (itemIndex != -1) {
        final item = _db.inventoryItems[itemIndex];
        _db.inventoryItems[itemIndex] = InventoryItem(
          id: item.id,
          name: item.name,
          unit: item.unit,
          currentStock: item.currentStock + removed.quantity,
          minStock: item.minStock,
          unitCost: item.unitCost,
          description: item.description,
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
