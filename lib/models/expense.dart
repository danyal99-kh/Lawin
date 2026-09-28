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
    this.note,
  });

  final int id;
  final String title;
  final int amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as int,
        title: json['title'] as String,
        amount: json['amount'] as int,
        category: parseApiEnum(ExpenseCategory.values, json['category'],
            fallback: ExpenseCategory.other),
        date: DateTime.parse(json['date'] as String).toLocal(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.apiValue,
        'date': date.toUtc().toIso8601String(),
        'note': note,
      };
}

/// داده‌ی فرم ثبت/ویرایش هزینه.
class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amount,
    required this.category,
    this.note,
  });

  final String title;
  final int amount;
  final ExpenseCategory category;
  final String? note;

  ExpenseDraft normalized() {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return ExpenseDraft(
      title: title.trim(),
      amount: amount < 0 ? 0 : amount,
      category: category,
      note: clean(note),
    );
  }
}
