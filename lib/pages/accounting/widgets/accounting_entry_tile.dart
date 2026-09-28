// lib/pages/accounting/widgets/accounting_entry_tile.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/accounting_entry.dart';

/// یک ردیف دفتر حسابداری: درآمد سبز با فلش رو به بالا، هزینه قرمز با فلش رو به پایین.
class AccountingEntryTile extends StatelessWidget {
  const AccountingEntryTile({super.key, required this.entry});

  final AccountingEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final color = entry.isIncome ? AppColors.success : AppColors.danger;
    final sign = entry.isIncome ? '+' : '−';
    final subtitle = entry.subtitle == null
        ? PersianFormat.dateTime(entry.date)
        : '${entry.subtitle} • ${PersianFormat.dateTime(entry.date)}';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              entry.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$sign${PersianFormat.money(entry.amount)}',
              style: theme.titleSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
