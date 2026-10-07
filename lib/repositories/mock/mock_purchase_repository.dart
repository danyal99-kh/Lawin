// lib/repositories/mock/mock_purchase_repository.dart
import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/inventory_item.dart';
import '../../models/purchase.dart';
import '../purchase_repository.dart';
import 'mock_database.dart';

/// موجودی و قیمت خرید کالا در همین Repository به‌روزرسانی می‌شود؛
/// بعد از اتصال به Django، Backend این کار را در یک تراکنش انجام می‌دهد.
/// تاریخچه‌ی خریدها مستقل از MockDatabase نگه داشته می‌شود (فقط همین Repository
/// به آن نیاز دارد)، اما تغییرات موجودی روی همان MockDatabase مشترک اعمال می‌شود.
class MockPurchaseRepository implements PurchaseRepository {
  MockPurchaseRepository(this._db) {
    _seed();
  }

  final MockDatabase _db;
  final List<Purchase> _purchases = [];
  int _seq = 0;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  void _seed() {
    final now = DateTime.now();
    void add(int itemId, double qty, double cost, int daysAgo) {
      final matches = _db.inventoryItems.where((i) => i.id == itemId);
      if (matches.isEmpty) return;
      final item = matches.first;
      _purchases.add(Purchase(
        id: ++_seq,
        itemId: itemId,
        itemName: item.name,
        unit: item.unit,
        quantity: qty,
        unitCost: cost,
        purchasedAt: now.subtract(Duration(days: daysAgo)),
      ));
    }

    add(1, 3000, 850, 6); // دانه‌ی قهوه
    add(2, 15000, 55, 4); // شیر
    add(3, 4000, 40, 9); // شکر
    add(1, 2000, 900, 1); // دانه‌ی قهوه
  }

  AppFailure? _validate(PurchaseDraft d) {
    if (!_db.inventoryItems.any((i) => i.id == d.itemId)) {
      return AppFailure.validation('کالای انتخاب‌شده وجود ندارد.');
    }
    if (d.quantity <= 0) {
      return AppFailure.validation('مقدار خرید باید بیشتر از صفر باشد.');
    }
    if (d.unitCost < 0) {
      return AppFailure.validation('قیمت خرید واردشده معتبر نیست.');
    }
    return null;
  }

  @override
  Future<Result<List<Purchase>>> getPurchases() async {
    try {
      await _latency();
      final list = List<Purchase>.of(_purchases)
        ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Purchase>> create(PurchaseDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final invalid = _validate(d);
      if (invalid != null) return Failure(invalid);

      final index = _db.inventoryItems.indexWhere((i) => i.id == d.itemId);
      final item = _db.inventoryItems[index];
      final purchase = Purchase(
        id: ++_seq,
        itemId: item.id,
        itemName: item.name,
        unit: item.unit,
        quantity: d.quantity,
        unitCost: d.unitCost,
        purchasedAt: DateTime.now(),
        account: d.account,
        note: d.note,
      );
      _purchases.add(purchase);
      _applyStock(index, d.quantity, d.unitCost);
      return Success(purchase);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  /// موجودی را به‌روز می‌کند: مقدار خریداری‌شده اضافه می‌شود و قیمت خرید با
  /// آخرین خرید جایگزین می‌شود (میانگین نمی‌گیریم).
  void _applyStock(int index, double quantity, double unitCost) {
    final item = _db.inventoryItems[index];
    _db.inventoryItems[index] = InventoryItem(
      id: item.id,
      name: item.name,
      unit: item.unit,
      currentStock: item.currentStock + quantity,
      minStock: item.minStock,
      unitCost: unitCost,
      description: item.description,
    );
  }

  @override
  Future<Result<Purchase>> update(int id, PurchaseDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final index = _purchases.indexWhere((p) => p.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      if (d.quantity <= 0) {
        return Failure(
            AppFailure.validation('مقدار خرید باید بیشتر از صفر باشد.'));
      }
      if (d.unitCost < 0) {
        return Failure(AppFailure.validation('قیمت خرید واردشده معتبر نیست.'));
      }
      final old = _purchases[index];
      final delta = d.quantity - old.quantity;
      final itemIndex =
          _db.inventoryItems.indexWhere((i) => i.id == old.itemId);
      final item = _db.inventoryItems[itemIndex];
      // مثل بک‌اند: کم کردن مقدار خرید نباید موجودی را منفی کند.
      if (item.currentStock + delta < 0) {
        return Failure(AppFailure.insufficientStock(item.name));
      }
      final updated = Purchase(
        id: old.id,
        itemId: old.itemId,
        itemName: old.itemName,
        unit: old.unit,
        quantity: d.quantity,
        unitCost: d.unitCost,
        purchasedAt: old.purchasedAt,
        account: d.account,
        note: d.note,
      );
      _purchases[index] = updated;
      _applyStock(itemIndex, delta, d.unitCost);
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _latency();
      final index = _purchases.indexWhere((p) => p.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final removed = _purchases.removeAt(index);
      final itemIndex =
          _db.inventoryItems.indexWhere((i) => i.id == removed.itemId);
      if (itemIndex != -1) {
        final item = _db.inventoryItems[itemIndex];
        if (item.currentStock < removed.quantity) {
          // موجودی را دست‌نخورده نگه می‌داریم و رکورد را برمی‌گردانیم.
          _purchases.insert(index, removed);
          return Failure(AppFailure.insufficientStock(item.name));
        }
        _db.inventoryItems[itemIndex] = InventoryItem(
          id: item.id,
          name: item.name,
          unit: item.unit,
          currentStock: item.currentStock - removed.quantity,
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
