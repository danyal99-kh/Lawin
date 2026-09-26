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
  paid('paid', 'پرداخت‌شده');

  const PaymentStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

enum PaymentMethod implements ApiEnum {
  cash('cash', 'نقدی'),
  cardReader('card_reader', 'کارتخوان'),
  cardTransfer('card_transfer', 'کارت‌به‌کارت');

  const PaymentMethod(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
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
  rawMaterials('raw_materials', 'خرید مواد اولیه'),
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
