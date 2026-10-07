// lib/repositories/waste_repository.dart
import '../core/errors/result.dart';
import '../models/waste.dart';

abstract interface class WasteRepository {
  /// تاریخچه‌ی ضایعات، جدیدترین اول.
  Future<Result<List<Waste>>> getWastes();

  /// ثبت ضایعات؛ موجودی کالای مربوطه کم می‌شود. اگر مقدار بیشتر از موجودی
  /// فعلی باشد خطای اعتبارسنجی برمی‌گردد.
  Future<Result<Waste>> create(WasteDraft draft);

  /// اصلاح ضایعات. اگر مقدار را کم کنیم، مقدار کم‌شده **به انبار برمی‌گردد**
  /// و زیان ضایعات در دفتر جایگزین می‌شود، نه اینکه انباشته شود.
  Future<Result<Waste>> update(int id, WasteDraft draft);

  /// حذف رکورد ضایعات؛ کالا به انبار برمی‌گردد و زیان آن از دفتر پاک می‌شود.
  Future<Result<void>> delete(int id);
}
