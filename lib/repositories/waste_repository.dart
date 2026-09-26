// lib/repositories/waste_repository.dart
import '../core/errors/result.dart';
import '../models/waste.dart';

abstract interface class WasteRepository {
  /// تاریخچه‌ی ضایعات، جدیدترین اول.
  Future<Result<List<Waste>>> getWastes();

  /// ثبت ضایعات؛ موجودی کالای مربوطه کم می‌شود. اگر مقدار بیشتر از موجودی
  /// فعلی باشد خطای اعتبارسنجی برمی‌گردد.
  Future<Result<Waste>> create(WasteDraft draft);
}
