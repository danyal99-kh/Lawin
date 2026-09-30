import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/expense.dart';
import '../expense_repository.dart';

class ApiExpenseRepository implements ExpenseRepository {
  ApiExpenseRepository(this._api);
  final ApiClient _api;

  static Expense _expense(dynamic j) =>
      Expense.fromJson(j as Map<String, dynamic>);

  Map<String, dynamic> _body(ExpenseDraft d) => {
        'title': d.title,
        'amount': d.amount,
        'category': d.category.apiValue,
        'note': d.note ?? '',
      };

  @override
  Future<Result<List<Expense>>> getExpenses() => _api.get(
        ApiEndpoints.expenses,
        (j) => (j as List).map(_expense).toList(),
      );

  @override
  Future<Result<Expense>> create(ExpenseDraft draft) =>
      _api.post(ApiEndpoints.expenses, _expense, body: _body(draft));

  @override
  Future<Result<Expense>> update(int id, ExpenseDraft draft) =>
      _api.patch(ApiEndpoints.expense(id), _expense, body: _body(draft));

  @override
  Future<Result<void>> delete(int id) => _api.delete(ApiEndpoints.expense(id));
}
