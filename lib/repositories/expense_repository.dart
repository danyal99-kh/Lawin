import '../core/errors/result.dart';
import '../models/expense.dart';

abstract interface class ExpenseRepository {
  /// همه‌ی هزینه‌ها، جدیدترین اول.
  Future<Result<List<Expense>>> getExpenses();

  /// ایجاد (id == null) یا ویرایش.
  Future<Result<Expense>> create(ExpenseDraft draft);
  Future<Result<Expense>> update(int id, ExpenseDraft draft);

  Future<Result<void>> delete(int id);
}
