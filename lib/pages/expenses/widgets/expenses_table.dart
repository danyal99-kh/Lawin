import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/expense.dart';
import '../../../widgets/app_card.dart';

/// جدول هزینه‌ها برای تبلت/دسکتاپ.
class ExpensesTable extends StatelessWidget {
  const ExpensesTable({
    super.key,
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Expense> expenses;
  final void Function(Expense) onEdit;
  final void Function(Expense) onDelete;

  static const double _actions = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final head = theme.labelMedium?.copyWith(color: AppColors.textSecondary);

    Widget header() => Container(
          color: AppColors.surfaceMuted,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('عنوان', style: head)),
              Expanded(flex: 2, child: Text('دسته‌بندی', style: head)),
              Expanded(flex: 2, child: Text('مبلغ', style: head)),
              Expanded(flex: 2, child: Text('تاریخ', style: head)),
              const SizedBox(width: _actions),
            ],
          ),
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          for (final e in expenses) ...[
            const Divider(),
            InkWell(
              onTap: () => onEdit(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall),
                          if (e.note != null)
                            Text(e.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(e.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(PersianFormat.money(e.amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall
                              ?.copyWith(color: AppColors.wood)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(PersianFormat.dateTime(e.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall),
                    ),
                    SizedBox(
                      width: _actions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'ویرایش',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(e),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => onDelete(e),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
