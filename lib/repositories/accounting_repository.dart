// lib/repositories/accounting_repository.dart
import '../core/errors/result.dart';
import '../models/accounting_entry.dart';

abstract interface class AccountingRepository {
  /// همه‌ی تراکنش‌های درآمد (سفارش‌های پرداخت‌شده) و هزینه، جدیدترین اول.
  Future<Result<List<AccountingEntry>>> getEntries();
}
