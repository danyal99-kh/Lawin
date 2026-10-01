// lib/models/accounting_entry.dart
import 'api_enum.dart';

/// نوع ردیف دفتر: درآمد (پرداخت سفارش) یا هزینه.
enum AccountingEntryType implements ApiEnum {
  income('income', 'درآمد'),
  expense('expense', 'هزینه');

  const AccountingEntryType(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// یک ردیف دفتر حسابداری؛ از سفارش‌های پرداخت‌شده و هزینه‌ها ساخته می‌شود.
class AccountingEntry {
  const AccountingEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.subtitle,
  });

  final String id;
  final AccountingEntryType type;
  final String title;
  final String? subtitle;

  /// همیشه مثبت؛ نوع تراکنش با [type] مشخص می‌شود.
  final int amount;
  final DateTime date;

  bool get isIncome => type == AccountingEntryType.income;

  /// `subtitle` اختیاری است چون ردیف درآمد همیشه «میز • روش پرداخت» دارد ولی
  /// بک‌اند ممکن است آن را خالی بفرستد.
  factory AccountingEntry.fromJson(Map<String, dynamic> json) =>
      AccountingEntry(
        id: json['id'] as String,
        type: parseApiEnum(AccountingEntryType.values, json['type'],
            fallback: AccountingEntryType.expense),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        amount: json['amount'] as int,
        date: DateTime.parse(json['date'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.apiValue,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'date': date.toUtc().toIso8601String(),
      };
}
