// lib/repositories/mock/mock_inventory_repository.dart
import '../../core/network/utils/text_utils.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/inventory_draft.dart';
import '../../models/inventory_item.dart';
import '../inventory_repository.dart';
import 'mock_database.dart';

/// اعتبارسنجی‌ها همان قوانینی است که بعداً Backend اعمال می‌کند.
/// تغییر مقدار موجودی فقط از طریق خرید (مرحله ۵ قسمت دوم) و ضایعات (قسمت سوم)
/// انجام می‌شود؛ این Repository فقط تعریف/ویرایش/حذف خود کالا را مدیریت می‌کند.
class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository(this._db);

  final MockDatabase _db;

  static const double maxUnitCost = 100000000;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  int _nextId() {
    var max = 0;
    for (final i in _db.inventoryItems) {
      if (i.id > max) max = i.id;
    }
    return max + 1;
  }

  AppFailure? _validate(InventoryItemDraft d, {int? excludeId}) {
    if (d.name.isEmpty) return AppFailure.validation('نام کالا را وارد کنید.');
    if (d.name.length > 60) {
      return AppFailure.validation('نام کالا حداکثر ۶۰ حرف باشد.');
    }
    if (d.minStock < 0) {
      return AppFailure.validation('حداقل موجودی نمی‌تواند منفی باشد.');
    }
    if (d.unitCost < 0 || d.unitCost > maxUnitCost) {
      return AppFailure.validation('قیمت خرید واردشده معتبر نیست.');
    }
    final key = TextUtils.normalizeFa(d.name);
    final duplicate = _db.inventoryItems
        .any((i) => i.id != excludeId && TextUtils.normalizeFa(i.name) == key);
    if (duplicate) {
      return AppFailure.validation('کالایی با این نام قبلاً ثبت شده است.');
    }
    return null;
  }

  @override
  Future<Result<List<InventoryItem>>> getItems() async {
    try {
      await _latency();
      return Success(List.of(_db.inventoryItems));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<InventoryItem>> create(InventoryItemDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final invalid = _validate(d);
      if (invalid != null) return Failure(invalid);
      final item = InventoryItem(
        id: _nextId(),
        name: d.name,
        unit: d.unit,
        currentStock: d.initialStock,
        minStock: d.minStock,
        unitCost: d.unitCost,
        description: d.description,
      );
      _db.inventoryItems.add(item);
      return Success(item);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<InventoryItem>> update(int id, InventoryItemDraft draft) async {
    try {
      await _latency();
      final index = _db.inventoryItems.indexWhere((i) => i.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final d = draft.normalized();
      final invalid = _validate(d, excludeId: id);
      if (invalid != null) return Failure(invalid);
      final current = _db.inventoryItems[index];
      final updated = InventoryItem(
        id: current.id,
        name: d.name,
        // واحد پایه بعد از ایجاد تغییر نمی‌کند (موجودی فعلی بر همان واحد ثبت شده).
        unit: current.unit,
        currentStock: current.currentStock,
        minStock: d.minStock,
        unitCost: d.unitCost,
        description: d.description,
      );
      _db.inventoryItems[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _latency();
      final index = _db.inventoryItems.indexWhere((i) => i.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      if (_db.inventoryItems[index].currentStock > 0) {
        return Failure(AppFailure.conflict(
          'این کالا موجودی دارد و قابل حذف نیست. ابتدا موجودی را از طریق ثبت ضایعات صفر کنید.',
        ));
      }
      _db.inventoryItems.removeAt(index);
      return const Success<void>(null);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
