// lib/repositories/expense_repository.dart
import '../core/errors/result.dart';
import '../models/expense.dart';

abstract interface class ExpenseRepository {
  /// تاریخچه‌ی هزینه‌ها، جدیدترین اول.
  Future<Result<List<Expense>>> getExpenses();

  Future<Result<Expense>> create(ExpenseDraft draft);
  Future<Result<Expense>> update(int id, ExpenseDraft draft);

  /// حذف هزینه؛ روی محاسبات گذشته‌ی حسابداری اثر می‌گذارد.
  Future<Result<void>> delete(int id);
}
