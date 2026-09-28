// lib/pages/accounting/widgets/accounting_summary.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../responsive/adaptive_grid.dart';
import '../../../widgets/app_card.dart';

/// سه کارت خلاصه: درآمد، هزینه و سود بازه‌ی انتخاب‌شده.
class AccountingSummary extends StatelessWidget {
  const AccountingSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.profit,
  });

  final int income;
  final int expense;
  final int profit;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 200,
      maxColumns: 3,
      children: [
        _Card(
          title: 'درآمد',
          value: PersianFormat.money(income),
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        _Card(
          title: 'هزینه',
          value: PersianFormat.money(expense),
          icon: Icons.trending_down,
          color: AppColors.danger,
        ),
        _Card(
          title: 'سود',
          value: PersianFormat.money(profit),
          icon: Icons.account_balance_wallet_outlined,
          color: profit < 0 ? AppColors.danger : AppColors.primary,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value,
                      style: theme.titleMedium?.copyWith(color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
