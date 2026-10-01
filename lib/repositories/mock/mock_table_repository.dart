import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/cafe_table.dart';
import '../../models/enums.dart';
import '../../models/table_overview.dart';
import '../../models/table_session.dart';
import '../table_repository.dart';
import 'mock_database.dart';

class MockTableRepository implements TableRepository {
  MockTableRepository(this._db);

  final MockDatabase _db;

  @override
  Future<Result<List<TableOverview>>> getTables() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return Success(buildOverviews());
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<TableOverview>> setReserved(int tableId,
      {required bool reserved}) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final index = _db.tables.indexWhere((t) => t.id == tableId);
      if (index == -1) return Failure(AppFailure.notFound());
      final table = _db.tables[index];
      if (table.status == TableStatus.active) {
        return Failure(AppFailure.conflict('میز فعال است و قابل رزرو نیست.'));
      }
      final updated = table.copyWith(
        status: reserved ? TableStatus.reserved : TableStatus.empty,
      );
      _db.tables[index] = updated;
      return Success(overviewFor(updated));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  /// عمومی برای تست‌پذیری.
  List<TableOverview> buildOverviews() =>
      [for (final t in _db.tables) overviewFor(t)];

  TableOverview overviewFor(CafeTable table) {
    TableSession? active;
    TableSession? last;
    for (final s in _db.sessions) {
      if (s.tableId != table.id) continue;
      if (s.isOpen) {
        active = s;
      } else if (last == null || s.exitedAt!.isAfter(last.exitedAt!)) {
        last = s;
      }
    }
    final open = _db.orders
        .where((o) => o.tableId == table.id && o.status.isOpen)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return TableOverview(
      table: table,
      activeSession: active,
      lastSession: last,
      openOrders: open,
      waiterCall: _db.activeWaiterCallFor(table.id),
    );
  }
}
