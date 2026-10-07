// lib/repositories/accounting_repository.dart
import '../core/errors/result.dart';
import '../models/accounting_entry.dart';
import '../models/enums.dart';

abstract interface class AccountingRepository {
  /// همه‌ی تراکنش‌های درآمد (سفارش‌های پرداخت‌شده) و هزینه، جدیدترین اول.
  Future<Result<List<AccountingEntry>>> getEntries();

  /// بازرسی یکپارچگی دفتر با سفارش‌ها و موجودی انبار. [LedgerVerification.ok]
  /// یعنی همه‌چیز می‌خواند. این یک تشخیص است نه اقدام: خودش چیزی را
  /// درست نمی‌کند، فقط می‌گوید کجا ناهماهنگ است.
  Future<Result<LedgerVerification>> verifyLedger();
}
