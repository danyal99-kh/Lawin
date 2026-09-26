import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/enums.dart';
import '../../../models/table_overview.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/live_duration.dart';
import '../../../widgets/status_chip.dart';
import '../../../widgets/status_tones.dart';
import 'info_row.dart';

/// کارت یک میز: شماره، وضعیت، زمان ورود/خروج، مدت حضور (زنده برای میز فعال)، سفارش فعال و مبلغ فعلی.
class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.overview, required this.onTap});

  final TableOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final table = overview.table;
    final tone = table.status.tone;
    final theme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(PersianFormat.digits(table.number),
                    style:
                        theme.titleLarge?.copyWith(color: tone.foreground)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('میز ${PersianFormat.digits(table.number)}',
                        style: theme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    StatusChip(label: table.status.label, tone: tone),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          _Body(overview: overview),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.overview});

  final TableOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    switch (overview.status) {
      case TableStatus.active:
        final session = overview.activeSession;
        final orderCount = overview.openOrders.length;
        return Column(
          children: [
            if (session != null) ...[
              InfoRow(
                  icon: Icons.login,
                  label: 'ورود',
                  value: shortWhen(session.enteredAt)),
              InfoRow.widget(
                icon: Icons.timer_outlined,
                label: 'مدت حضور',
                child: LiveDuration(
                  since: session.enteredAt,
                  style: theme.titleSmall?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
            InfoRow(
              icon: Icons.receipt_long_outlined,
              label: 'سفارش فعال',
              value: orderCount == 0
                  ? '—'
                  : '${PersianFormat.digits(orderCount)} سفارش',
            ),
            InfoRow(
              icon: Icons.payments_outlined,
              label: 'مبلغ فعلی',
              value: PersianFormat.money(overview.currentAmount),
            ),
          ],
        );

      case TableStatus.reserved:
        return Text('رزرو شده؛ منتظر ورود مشتری', style: theme.bodySmall);

      case TableStatus.empty:
        final last = overview.lastSession;
        if (last == null || last.exitedAt == null) {
          return Text('هنوز نشستی برای این میز ثبت نشده', style: theme.bodySmall);
        }
        return Column(
          children: [
            InfoRow(
                icon: Icons.logout,
                label: 'آخرین خروج',
                value: shortWhen(last.exitedAt!)),
            InfoRow(
              icon: Icons.timer_outlined,
              label: 'مدت حضور',
              value: PersianFormat.duration(last.durationAt(DateTime.now())),
            ),
          ],
        );
    }
  }
}