// lib/repositories/mock/mock_expense_repository.dart
import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/expense.dart';
import '../expense_repository.dart';
import 'mock_database.dart';

/// اعتبارسنجی‌ها همان قوانینی است که بعداً Backend اعمال می‌کند.
class MockExpenseRepository implements ExpenseRepository {
  MockExpenseRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  int _nextId() {
    var max = 0;
    for (final e in _db.expenses) {
      if (e.id > max) max = e.id;
    }
    return max + 1;
  }

  AppFailure? _validate(ExpenseDraft d) {
    if (d.title.isEmpty) {
      return AppFailure.validation('عنوان هزینه را وارد کنید.');
    }
    if (d.title.length > 80) {
      return AppFailure.validation('عنوان هزینه حداکثر ۸۰ حرف باشد.');
    }
    if (d.amount <= 0) {
      return AppFailure.validation('مبلغ هزینه باید بیشتر از صفر باشد.');
    }
    return null;
  }

  @override
  Future<Result<List<Expense>>> getExpenses() async {
    try {
      await _latency();
      final list = [..._db.expenses]..sort((a, b) => b.date.compareTo(a.date));
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Expense>> create(ExpenseDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final invalid = _validate(d);
      if (invalid != null) return Failure(invalid);
      final expense = Expense(
        id: _nextId(),
        title: d.title,
        amount: d.amount,
        category: d.category,
        date: DateTime.now(),
        note: d.note,
      );
      _db.expenses.add(expense);
      return Success(expense);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Expense>> update(int id, ExpenseDraft draft) async {
    try {
      await _latency();
      final index = _db.expenses.indexWhere((e) => e.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final d = draft.normalized();
      final invalid = _validate(d);
      if (invalid != null) return Failure(invalid);
      final current = _db.expenses[index];
      final updated = Expense(
        id: current.id,
        title: d.title,
        amount: d.amount,
        category: d.category,
        date: current.date,
        note: d.note,
      );
      _db.expenses[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _latency();
      final index = _db.expenses.indexWhere((e) => e.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      _db.expenses.removeAt(index);
      return const Success<void>(null);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
