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
}
