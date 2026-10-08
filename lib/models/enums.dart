import '../core/utils/persian_format.dart';
import 'api_enum.dart';

/// منبع سفارش: ثبت‌شده توسط ادمین یا دریافت‌شده از بخش مشتری (Django).
enum OrderSource implements ApiEnum {
  admin('admin', 'ادمین'),
  customer('customer', 'مشتری');

  const OrderSource(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// روند اصلی سفارش کافه: جدید → در حال آماده‌سازی → آماده → تحویل‌شده → پرداخت‌شده (یا لغوشده).
enum OrderStatus implements ApiEnum {
  newOrder('new', 'جدید'),
  preparing('preparing', 'در حال آماده‌سازی'),
  ready('ready', 'آماده'),
  delivered('delivered', 'تحویل‌شده'),
  paid('paid', 'پرداخت‌شده'),
  cancelled('cancelled', 'لغوشده');

  const OrderStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  /// سفارشی که هنوز بسته نشده است.
  bool get isOpen => this != paid && this != cancelled;

  /// وضعیت بعدی در روند آشپزخانه (فقط تا «تحویل‌شده»؛ پرداخت مرحله‌ی جداست).
  OrderStatus? get nextStep => switch (this) {
        OrderStatus.newOrder => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.delivered,
        _ => null,
      };

  /// برچسب دکمه‌ی پیشبرد وضعیت.
  String get advanceLabel => switch (this) {
        OrderStatus.newOrder => 'شروع آماده‌سازی',
        OrderStatus.preparing => 'آماده شد',
        OrderStatus.ready => 'تحویل داده شد',
        _ => '',
      };
}

enum PaymentStatus implements ApiEnum {
  unpaid('unpaid', 'پرداخت‌نشده'),
  paid('paid', 'پرداخت‌شده'),

  /// با نسیه تسویه شده: سفارش از دید میز بسته شده ولی پول هنوز وصول نشده
  /// است. مبلغش به‌صورت «طلب» روی حساب بدهکاران نشسته و فقط لحظه‌ی تسویه‌ی
  /// نسیه به صندوق/بانک می‌نشیند.
  credit('credit', 'نسیه'),

  /// پول برگشته و موجودی مصرف‌شده به انبار برگشته است. این سفارش دیگر در
  /// درآمد دوره حساب نمی‌شود.
  refunded('refunded', 'برگشت‌خورده');

  const PaymentStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

enum PaymentMethod implements ApiEnum {
  cash('cash', 'نقدی'),
  cardReader('card_reader', 'کارتخوان'),
  cardTransfer('card_transfer', 'کارت‌به‌کارت'),

  /// نسیه: پول هنوز گرفته نشده. در دفتر «طلب» (بدهکاران) ثبت می‌شود و فقط
  /// لحظه‌ی تسویه به صندوق/بانک می‌نشیند. ثبتش نیازمند نام بدهکار است.
  credit('credit', 'نسیه');

  const PaymentMethod(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// حساب نقدی که پولش در دفتر جابه‌جا می‌شود.
///
/// تفکیکش عمدی است: [PaymentMethod.cardReader] و [PaymentMethod.cardTransfer]
/// هر دو در دفتر به «بانک» می‌نشینند، ولی [CashAccount] فقط دو مقدار دارد.
/// این enum برای پول *خارجی* است (هزینه، خرید کالا) — نه روش پرداخت مشتری.
enum CashAccount implements ApiEnum {
  cash('cash', 'صندوق'),
  bank('bank', 'بانک');

  const CashAccount(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// یک قسط از پرداخت چندروشی. مبلغ‌ها به تومان و مجموعشان باید برابر
/// مبلغ کل سفارش باشد.
class PaymentShare {
  const PaymentShare({required this.method, required this.amount});

  final PaymentMethod method;
  final int amount;

  Map<String, dynamic> toJson() =>
      {'method': method.apiValue, 'amount': amount};

  factory PaymentShare.fromJson(Map<String, dynamic> json) => PaymentShare(
        method: parseApiEnum(PaymentMethod.values, json['method'],
            fallback: PaymentMethod.cash),
        amount: (json['amount'] as num).toInt(),
      );
}

/// وضعیت بازرسی دفتر حسابداری (`GET /api/v1/accounting/verify/`).
///
/// [ok] یعنی دفتر با واقعیت کسب‌وکار می‌خواند. [problems] خطاهایی است که باید
/// برطرف شوند؛ [warnings] مثل «مانده‌ی صندوق منفی است» وضعیت کسب‌وکار است و
/// خرابیِ دفتر نیست.
class LedgerVerification {
  const LedgerVerification({
    required this.ok,
    required this.problems,
    required this.warnings,
  });

  final bool ok;
  final List<LedgerIssue> problems;
  final List<LedgerIssue> warnings;

  bool get hasWarnings => warnings.isNotEmpty;

  factory LedgerVerification.fromJson(Map<String, dynamic> json) {
    List<LedgerIssue> list(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => LedgerIssue.fromJson(e as Map<String, dynamic>))
            .toList();
    return LedgerVerification(
      ok: json['ok'] as bool? ?? false,
      problems: list('problems'),
      warnings: list('warnings'),
    );
  }
}

class LedgerIssue {
  const LedgerIssue({required this.code, required this.detail});

  final String code;
  final String detail;

  factory LedgerIssue.fromJson(Map<String, dynamic> json) => LedgerIssue(
        code: json['code'] as String? ?? 'unknown',
        detail: json['detail'] as String? ?? '',
      );
}

enum TableStatus implements ApiEnum {
  empty('empty', 'خالی'),
  active('active', 'فعال'),
  reserved('reserved', 'رزرو شده');

  const TableStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// واحد پایه‌ی انبار. تمام محاسبات داخلی موجودی فقط بر پایه‌ی همین واحدها انجام می‌شود
/// (کیلوگرم/لیتر/بطری/بسته «واحد تبدیل» هستند و در مرحله‌ی انبار اضافه می‌شوند).
enum BaseUnit implements ApiEnum {
  gram('g', 'گرم'),
  milliliter('ml', 'میلی‌لیتر'),
  piece('piece', 'عدد');

  const BaseUnit(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  /// نمایش خوانا: ۳۲۰۰ گرم → «۳٫۲ کیلوگرم»، ۳۵۰۰ میلی‌لیتر → «۳٫۵ لیتر»
  String format(double quantity) {
    switch (this) {
      case BaseUnit.gram:
        return quantity.abs() >= 1000
            ? '${PersianFormat.number(quantity / 1000, decimals: 2)} کیلوگرم'
            : '${PersianFormat.number(quantity, decimals: 1)} گرم';
      case BaseUnit.milliliter:
        return quantity.abs() >= 1000
            ? '${PersianFormat.number(quantity / 1000, decimals: 2)} لیتر'
            : '${PersianFormat.number(quantity, decimals: 1)} میلی‌لیتر';
      case BaseUnit.piece:
        return '${PersianFormat.number(quantity, decimals: 0)} عدد';
    }
  }
}

enum StockStatus {
  ok('موجود'),
  low('کم'),
  out('تمام‌شده');

  const StockStatus(this.label);
  final String label;
}

enum ExpenseCategory implements ApiEnum {
  salary('salary', 'حقوق'),
  rent('rent', 'اجاره'),
  water('water', 'آب'),
  electricity('electricity', 'برق'),
  gas('gas', 'گاز'),
  internet('internet', 'اینترنت'),
  repairs('repairs', 'تعمیرات'),
  equipment('equipment', 'تجهیزات'),
  advertising('advertising', 'تبلیغات'),
  transport('transport', 'حمل‌ونقل'),
  supplies('supplies', 'مواد مصرفی'),
  other('other', 'سایر هزینه‌ها');

  const ExpenseCategory(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}
