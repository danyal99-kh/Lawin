import '../../core/errors/app_failure.dart';
import '../../models/enums.dart';
import '../../models/table_session.dart';
import 'mock_database.dart';

/// قوانین کسب‌وکار نشست میز (نسخه‌ی Mock).
///
/// وقتی Django آماده شد، همین دو قانون در Backend و داخل یک تراکنش اجرا می‌شوند
/// (ثبت اولین سفارش / ثبت پرداخت) و این کلاس حذف می‌شود.
/// OrderRepository (مرحله ۷) و PaymentRepository (مرحله ۸) از همین‌جا استفاده می‌کنند؛
/// هیچ Widget مستقیماً با آن کار ندارد.
class MockSessionEngine {
  MockSessionEngine(this._db);

  final MockDatabase _db;

  /// قانون ۱: با اولین سفارش یک میز، نشست ساخته می‌شود و زمان ورود همان لحظه ثبت می‌شود.
  /// اگر نشست باز وجود داشته باشد همان برمی‌گردد. میز رزروشده با ورود مشتری فعال می‌شود.
  TableSession openIfNeeded(int tableId, DateTime now) {
    for (final s in _db.sessions) {
      if (s.tableId == tableId && s.isOpen) return s;
    }
    final index = _db.tables.indexWhere((t) => t.id == tableId);
    if (index == -1) throw AppFailure.notFound();
    final table = _db.tables[index];
    final session = TableSession(
      id: _db.nextSessionId(),
      tableId: tableId,
      tableNumber: table.number,
      enteredAt: now,
    );
    _db.sessions.add(session);
    _db.tables[index] = table.copyWith(status: TableStatus.active);
    return session;
  }

  /// قانون ۲: با پرداخت صورتحساب، زمان خروج ثبت و میز آزاد می‌شود.
  /// اگر نشست بازی نباشد null برمی‌گردد.
  TableSession? close(int tableId, DateTime now) {
    final sIndex =
        _db.sessions.indexWhere((s) => s.tableId == tableId && s.isOpen);
    if (sIndex == -1) return null;
    final closed = _db.sessions[sIndex].copyWith(exitedAt: now);
    _db.sessions[sIndex] = closed;
    final tIndex = _db.tables.indexWhere((t) => t.id == tableId);
    if (tIndex != -1) {
      _db.tables[tIndex] =
          _db.tables[tIndex].copyWith(status: TableStatus.empty);
    }
    return closed;
  }
}