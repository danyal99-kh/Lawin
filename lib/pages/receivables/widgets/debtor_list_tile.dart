import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/credit.dart';
import '../../../widgets/app_card.dart';
import 'debtors_table.dart';

/// کارت یک بدهکار برای موبایل.
class DebtorListTile extends StatelessWidget {
  const DebtorListTile({
    super.key,
    required this.debtor,
    required this.onTap,
  });

  final Debtor debtor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debtor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'نسیه‌ی باز: ${PersianFormat.digits(debtor.openCredits)}'
                  ' • آخرین فعالیت: '
                  '${debtor.lastActivity == null ? '—' : PersianFormat.dateTime(debtor.lastActivity!)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                if (debtor.phone != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(debtor.phone!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.sm),
                DebtStatusChip(debtor: debtor),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_left, color: theme.bodySmall?.color),
        ],
      ),
    );
  }
}
