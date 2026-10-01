import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/accounting_entry.dart';
import '../accounting_repository.dart';

/// دفتر حسابداری از Django: درآمد (سفارش‌های پرداخت‌شده) و هزینه‌ها را خودِ
/// Backend ترکیب و مرتب می‌کند، پس اینجا فقط نگاشت JSON به مدل انجام می‌شود.
class ApiAccountingRepository implements AccountingRepository {
  ApiAccountingRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<AccountingEntry>>> getEntries() => _api.get(
        ApiEndpoints.transactions,
        (j) => (j as List)
            .map((e) => AccountingEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
