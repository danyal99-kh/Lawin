import 'api_enum.dart';
import 'enums.dart';

/// وضعیت یک نسیه؛ همان `Credit.Status` بک‌اند.
///
/// نسیه‌ی «باز» یعنی طلبِ وصول‌نشده، «تسویه‌شده» یعنی مانده‌اش صفر شده و
/// «برگشت‌خورده» یعنی سفارش refund شده و طلب خنثی شده است.
enum CreditStatus implements ApiEnum {
  open('open', 'باز'),
  settled('settled', 'تسویه‌شده'),
  refunded('refunded', 'برگشت‌خورده');

  const CreditStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  bool get isOpen => this == open;
}

/// بدهکار: کسی که نسیه به نام او ثبت می‌شود. در پرداخت نسیه خودکار ساخته
/// می‌شود؛ `debt` از خودِ ردیف‌های Credit می‌آید نه محاسبه‌ی جداگانه.
class Debtor {
  const Debtor({
    required this.id,
    required this.name,
    required this.debt,
    required this.openCredits,
    required this.extended,
    this.phone,
    this.note,
    this.lastActivity,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? phone;
  final String? note;

  /// مانده‌ی باز: چقدر باید بگیریم.
  final int debt;

  /// تعداد نسیه‌های باز.
  final int openCredits;

  /// کل نسیه‌ای که تا حالا ثبت کرده‌ایم.
  final int extended;
  final DateTime? lastActivity;
  final DateTime createdAt;

  bool get isSettled => debt == 0;

  factory Debtor.fromJson(Map<String, dynamic> json) => Debtor(
        id: json['id'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        note: json['note'] as String?,
        debt: (json['debt'] as num?)?.toInt() ?? 0,
        openCredits: (json['open_credits'] as num?)?.toInt() ?? 0,
        extended: (json['extended'] as num?)?.toInt() ?? 0,
        lastActivity: _parseDate(json['last_activity']),
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      );
}

/// یک طلب (نسیه) از یک بدهکار بابت یک سفارش. مبلغ اولیه ثابت می‌ماند؛ فقط
/// [remainingAmount] با تسویه کم می‌شود.
class Credit {
  const Credit({
    required this.id,
    required this.debtorId,
    required this.debtorName,
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int debtorId;
  final String debtorName;
  final String orderId;
  final int orderNumber;
  final int amount;

  /// مانده‌ی وصول‌نشده. کلاینت هرگز آن را نمی‌نویسد؛ فقط از بک‌اند می‌خواند.
  final int remainingAmount;
  final CreditStatus status;
  final DateTime createdAt;

  bool get isOpen => status.isOpen;
  bool get isFullyPaid => remainingAmount == 0;

  factory Credit.fromJson(Map<String, dynamic> json) => Credit(
        id: json['id'] as int,
        debtorId: json['debtor_id'] as int,
        debtorName: json['debtor_name'] as String? ?? '',
        orderId: json['order_id'] as String? ?? '',
        orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num).toInt(),
        remainingAmount: (json['remaining_amount'] as num?)?.toInt() ?? 0,
        status: parseApiEnum(CreditStatus.values, json['status'],
            fallback: CreditStatus.open),
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      );
}

/// یک قسط وصول‌شده: پول واقعاً وارد صندوق/بانک شده است.
class CreditPayment {
  const CreditPayment({
    required this.id,
    required this.creditId,
    required this.debtorId,
    required this.debtorName,
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.account,
    required this.createdAt,
    this.note,
  });

  final int id;
  final int creditId;
  final int debtorId;
  final String debtorName;
  final String orderId;
  final int orderNumber;
  final int amount;
  final CashAccount account;
  final String? note;
  final DateTime createdAt;

  factory CreditPayment.fromJson(Map<String, dynamic> json) => CreditPayment(
        id: json['id'] as int,
        creditId: json['credit_id'] as int,
        debtorId: (json['debtor_id'] as num).toInt(),
        debtorName: json['debtor_name'] as String? ?? '',
        orderId: json['order_id'] as String? ?? '',
        orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num).toInt(),
        account: parseApiEnum(CashAccount.values, json['account'],
            fallback: CashAccount.cash),
        note: json['note'] as String?,
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      );
}

/// خروجی `POST /credits/payments/`: قسط‌های ثبت‌شده + وضعیت تازه‌ی نسیه‌ها.
class SettleResult {
  const SettleResult({
    required this.total,
    required this.payments,
    required this.credits,
    this.debtorId,
    this.debtorName,
  });

  /// مبلغی که واقعاً وصول شد (ممکن است کمتر از درخواست باشد، هرگز بیشتر).
  final int total;
  final List<CreditPayment> payments;
  final List<Credit> credits;
  final int? debtorId;
  final String? debtorName;

  factory SettleResult.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
        (raw as List<dynamic>? ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    return SettleResult(
      total: (json['total'] as num?)?.toInt() ?? 0,
      payments: list(json['payments'], CreditPayment.fromJson),
      credits: list(json['credits'], Credit.fromJson),
      debtorId: (json['debtor_id'] as num?)?.toInt(),
      debtorName: json['debtor_name'] as String?,
    );
  }
}

/// جزئیات یک بدهکار: خودِ بدهکار + نسیه‌هایش.
class DebtorDetail {
  const DebtorDetail({required this.debtor, required this.credits});

  final Debtor debtor;
  final List<Credit> credits;

  factory DebtorDetail.fromJson(Map<String, dynamic> json) => DebtorDetail(
        debtor: Debtor.fromJson(json['debtor'] as Map<String, dynamic>),
        credits: ((json['credits'] as List<dynamic>? ?? const []))
            .map((e) => Credit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

DateTime? _parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toLocal();
}
