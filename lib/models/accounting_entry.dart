// lib/models/accounting_entry.dart

/// نوع ردیف دفتر: درآمد (پرداخت سفارش) یا هزینه.
enum AccountingEntryType { income, expense }

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
}
