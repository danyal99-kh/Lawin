import '../core/errors/result.dart';
import '../models/table_overview.dart';

abstract interface class TableRepository {
  /// همه‌ی میزها همراه با نشست فعال، آخرین نشست و سفارش‌های باز.
  Future<Result<List<TableOverview>>> getTables();

  /// رزرو یا لغو رزرو یک میز. میز فعال قابل رزرو نیست.
  Future<Result<TableOverview>> setReserved(int tableId,
      {required bool reserved});
}