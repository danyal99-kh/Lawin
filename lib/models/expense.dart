// lib/models/expense.dart
import 'api_enum.dart';
import 'enums.dart';

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.account = CashAccount.cash,
    this.note,
  });

  final int id;
  final String title;
  final int amount;
  final ExpenseCategory category;
  final DateTime date;

  /// پول هزینه از کدام حساب کم شده.
  final CashAccount account;
  final String? note;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as int,
        title: json['title'] as String,
        amount: json['amount'] as int,
        category: parseApiEnum(ExpenseCategory.values, json['category'],
            fallback: ExpenseCategory.other),
        date: DateTime.parse(json['date'] as String).toLocal(),
        account: parseApiEnum(CashAccount.values, json['account'],
            fallback: CashAccount.cash),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.apiValue,
        'date': date.toUtc().toIso8601String(),
        'account': account.apiValue,
        'note': note,
      };
}

/// داده‌ی فرم ثبت/ویرایش هزینه.
/// زمان ثبت (date) همیشه لحظه‌ی ذخیره است، مشابه الگوی خرید و ضایعات —
/// کاربر تاریخ را دستی وارد نمی‌کند.
class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amount,
    required this.category,
    this.account = CashAccount.cash,
    this.note,
  });

  final String title;
  final int amount;
  final ExpenseCategory category;
  final CashAccount account;
  final String? note;

  ExpenseDraft normalized() {
    final t = note?.trim();
    return ExpenseDraft(
      title: title.trim(),
      amount: amount < 0 ? 0 : amount,
      category: category,
      account: account,
      note: (t == null || t.isEmpty) ? null : t,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'category': category.apiValue,
        'account': account.apiValue,
        'note': note,
      };
}
