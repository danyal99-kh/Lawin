// lib/pages/expenses/widgets/expense_list_tile.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/expense.dart';
import '../../../widgets/app_card.dart';

/// کارت هزینه برای موبایل (جایگزین ردیف جدول).
class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.woodSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.payments_outlined, color: AppColors.wood),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(expense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        tooltip: 'گزینه‌ها',
                        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${expense.category.label} • ${PersianFormat.date(expense.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(PersianFormat.money(expense.amount),
                    style: theme.titleSmall?.copyWith(color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
