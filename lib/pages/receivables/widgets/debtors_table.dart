import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/credit.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';

/// جدول بدهکاران برای تبلت/دسکتاپ.
class DebtorsTable extends StatelessWidget {
  const DebtorsTable({
    super.key,
    required this.debtors,
    required this.onSelect,
  });

  final List<Debtor> debtors;
  final void Function(Debtor) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final head = theme.labelMedium?.copyWith(color: AppColors.textSecondary);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surfaceMuted,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('بدهکار', style: head)),
                Expanded(flex: 2, child: Text('نسیه‌های باز', style: head)),
                Expanded(flex: 3, child: Text('مانده طلب', style: head)),
                Expanded(flex: 3, child: Text('آخرین فعالیت', style: head)),
                Expanded(flex: 3, child: Text('کل نسیه ثبت‌شده', style: head)),
              ],
            ),
          ),
          for (final d in debtors) ...[
            const Divider(),
            InkWell(
              onTap: () => onSelect(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall),
                          if (d.phone != null)
                            Text(d.phone!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(PersianFormat.digits(d.openCredits),
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(PersianFormat.money(d.debt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall?.copyWith(
                              color: d.debt > 0
                                  ? AppColors.danger
                                  : AppColors.success)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                          d.lastActivity == null
                              ? '—'
                              : PersianFormat.dateTime(d.lastActivity!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(PersianFormat.money(d.extended),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall),
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

/// وضعیت یک بدهکار برای نمایش در کارت موبایل.
class DebtStatusChip extends StatelessWidget {
  const DebtStatusChip({super.key, required this.debtor});

  final Debtor debtor;

  @override
  Widget build(BuildContext context) => debtor.debt > 0
      ? StatusChip(
          label: 'طلب ${PersianFormat.money(debtor.debt)}',
          tone: StatusTone.danger,
          icon: Icons.account_balance_wallet_outlined,
        )
      : const StatusChip(
          label: 'تسویه‌شده',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        );
}
