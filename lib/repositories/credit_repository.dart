import '../core/errors/result.dart';
import '../models/credit.dart';
import '../models/enums.dart';

/// خواندن و تسویه‌ی نسیه (Accounts Receivable).
///
/// هیچ عددی برای مانده یا وضعیت از Client پذیرفته نمی‌شود؛ همه‌چیز را خودِ
/// بک‌اند از ردیف Credit و دفتر مرکزی محاسبه می‌کند. سمت کلاینت فقط خواندن
/// و فرستادن «مبلغ تسویه» مجاز است.
abstract interface class CreditRepository {
  /// نسیه‌ها، قدیمی‌ترین اول.
  Future<Result<List<Credit>>> getCredits({int? debtorId, CreditStatus? status});

  /// بدهکارها با جمع مانده‌شان؛ [query] روی نام جست‌وجو می‌کند.
  Future<Result<List<Debtor>>> getDebtors({String? query});

  /// جزئیات یک بدهکار + همه‌ی نسیه‌هایش.
  Future<Result<DebtorDetail>> getDebtor(int id);

  /// وصول‌های ثبت‌شده، جدیدترین اول.
  Future<Result<List<CreditPayment>>> getPayments({int? debtorId});

  /// ثبت تسویه: oldest-first از قدیمی‌ترین نسیه‌ی باز کم می‌کند.
  /// [debtorId] یا [creditId] باید یکی پر شود؛ [amount] به تومان.
  /// [idempotencyKey] درخواست تکراری را بی‌اثر می‌کند.
  Future<Result<SettleResult>> settle({
    int? debtorId,
    int? creditId,
    required int amount,
    required CashAccount account,
    String? note,
    String? idempotencyKey,
  });
}
