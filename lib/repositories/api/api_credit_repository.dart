import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/credit.dart';
import '../../models/enums.dart';
import '../credit_repository.dart';

class ApiCreditRepository implements CreditRepository {
  ApiCreditRepository(this._api);
  final ApiClient _api;

  static Credit _credit(dynamic j) =>
      Credit.fromJson(j as Map<String, dynamic>);
  static Debtor _debtor(dynamic j) => Debtor.fromJson(j as Map<String, dynamic>);
  static CreditPayment _payment(dynamic j) =>
      CreditPayment.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<Credit>>> getCredits(
          {int? debtorId, CreditStatus? status}) =>
      _api.get(
        ApiEndpoints.credits,
        (j) => (j as List).map(_credit).toList(),
        query: {
          if (debtorId != null) 'debtor': '$debtorId',
          if (status != null) 'status': status.apiValue,
        },
      );

  @override
  Future<Result<List<Debtor>>> getDebtors({String? query}) => _api.get(
        ApiEndpoints.creditDebtors,
        (j) => (j as List).map(_debtor).toList(),
        query: {if (query != null && query.isNotEmpty) 'q': query},
      );

  @override
  Future<Result<DebtorDetail>> getDebtor(int id) => _api.get(
        ApiEndpoints.creditDebtor(id),
        (j) => DebtorDetail.fromJson(j as Map<String, dynamic>),
      );

  @override
  Future<Result<List<CreditPayment>>> getPayments({int? debtorId}) => _api.get(
        ApiEndpoints.creditPayments,
        (j) => (j as List).map(_payment).toList(),
        query: {if (debtorId != null) 'debtor': '$debtorId'},
      );

  @override
  Future<Result<SettleResult>> settle({
    int? debtorId,
    int? creditId,
    required int amount,
    required CashAccount account,
    String? note,
    String? idempotencyKey,
  }) =>
      _api.post(
        ApiEndpoints.creditPayments,
        (j) => SettleResult.fromJson(j as Map<String, dynamic>),
        body: {
          if (debtorId != null) 'debtor_id': debtorId,
          if (creditId != null) 'credit_id': creditId,
          'amount': amount,
          'account': account.apiValue,
          if (note != null && note.isNotEmpty) 'note': note,
          if (idempotencyKey != null && idempotencyKey.isNotEmpty)
            'idempotency_key': idempotencyKey,
        },
      );
}
