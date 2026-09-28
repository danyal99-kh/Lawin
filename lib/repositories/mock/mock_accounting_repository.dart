// lib/repositories/mock/mock_accounting_repository.dart
import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../core/utils/persian_format.dart';
import '../../models/accounting_entry.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../accounting_repository.dart';
import 'mock_database.dart';

/// دفتر حسابداری از ترکیب سفارش‌های پرداخت‌شده (درآمد) و هزینه‌ها ساخته می‌شود.
/// بعد از اتصال به Django، این ترکیب در Backend انجام می‌شود و این کلاس حذف می‌شود.
class MockAccountingRepository implements AccountingRepository {
  MockAccountingRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  String _incomeSubtitle(Order o) {
    final parts = <String>[];
    if (o.tableNumber != null)
      parts.add('میز ${PersianFormat.digits(o.tableNumber)}');
    if (o.paymentMethod != null) parts.add(o.paymentMethod!.label);
    if (parts.isEmpty) parts.add(o.source.label);
    return parts.join(' • ');
  }

  @override
  Future<Result<List<AccountingEntry>>> getEntries() async {
    try {
      await _latency();
      final entries = <AccountingEntry>[
        for (final o in _db.orders)
          if (o.status == OrderStatus.paid)
            AccountingEntry(
              id: 'income-${o.id}',
              type: AccountingEntryType.income,
              title: 'سفارش ${PersianFormat.digits(o.number)}',
              subtitle: _incomeSubtitle(o),
              amount: o.total,
              date: o.paidAt ?? o.createdAt,
            ),
        for (final e in _db.expenses)
          AccountingEntry(
            id: 'expense-${e.id}',
            type: AccountingEntryType.expense,
            title: e.title,
            subtitle: e.category.label,
            amount: e.amount,
            date: e.date,
          ),
      ]..sort((a, b) => b.date.compareTo(a.date));
      return Success(entries);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
