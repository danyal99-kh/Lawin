import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/enums.dart';
import '../../../models/order.dart';
import '../../../models/table_overview.dart';
import '../../../widgets/live_duration.dart';
import '../../../widgets/status_chip.dart';
import '../../../widgets/status_tones.dart';
import 'info_row.dart';

/// جزئیات یک میز (داخل Dialog یا Bottom Sheet).
/// [onToggleReserved] فقط برای میز خالی/رزرو نمایش داده می‌شود.
class TableDetail extends StatelessWidget {
  const TableDetail({
    super.key,
    required this.overview,
    required this.onToggleReserved,
  });

  final TableOverview overview;
  final VoidCallback onToggleReserved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final table = overview.table;
    final isActive = overview.status == TableStatus.active;
    final isReserved = overview.status == TableStatus.reserved;
    final session = overview.activeSession ?? overview.lastSession;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('میز ${PersianFormat.digits(table.number)}',
                    style: theme.titleLarge),
              ),
              StatusChip(label: table.status.label, tone: table.status.tone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (session != null) ...[
            Text(isActive ? 'نشست فعلی' : 'آخرین نشست', style: theme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            InfoRow(
                icon: Icons.login,
                label: 'زمان ورود',
                value: shortWhen(session.enteredAt)),
            InfoRow(
              icon: Icons.logout,
              label: 'زمان خروج',
              value: session.exitedAt == null
                  ? 'هنوز خارج نشده'
                  : shortWhen(session.exitedAt!),
            ),
            if (isActive)
              InfoRow.widget(
                icon: Icons.timer_outlined,
                label: 'مدت حضور',
                child: LiveDuration(
                  since: session.enteredAt,
                  style: theme.titleSmall?.copyWith(color: AppColors.primary),
                ),
              )
            else
              InfoRow(
                icon: Icons.timer_outlined,
                label: 'مدت حضور',
                value: PersianFormat.duration(session.durationAt(DateTime.now())),
              ),
          ] else
            Text('هنوز نشستی برای این میز ثبت نشده', style: theme.bodySmall),
          if (isActive) ...[
            const Divider(height: AppSpacing.xxl),
            if (overview.openOrders.isEmpty)
              Text('سفارش بازی برای این میز نیست', style: theme.bodySmall)
            else ...[
              for (final o in overview.openOrders) _OrderBlock(order: o),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('مبلغ فعلی', style: theme.titleSmall),
                  const Spacer(),
                  Text(PersianFormat.money(overview.currentAmount),
                      style: theme.titleMedium
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ],
          if (!isActive) ...[
            const SizedBox(height: AppSpacing.xl),
            isReserved
                ? OutlinedButton.icon(
                    onPressed: onToggleReserved,
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    label: const Text('لغو رزرو'),
                  )
                : FilledButton.icon(
                    onPressed: onToggleReserved,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('رزرو این میز'),
                  ),
          ],
        ],
      ),
    );
  }
}

class _OrderBlock extends StatelessWidget {
  const _OrderBlock({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('سفارش ${PersianFormat.digits(order.number)}',
                  style: theme.titleSmall),
              StatusChip(label: order.status.label, tone: order.status.tone),
              if (order.isFromCustomer)
                const StatusChip(
                    label: 'مشتری',
                    tone: StatusTone.info,
                    icon: Icons.smartphone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} × ${PersianFormat.digits(item.quantity)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(PersianFormat.money(item.lineTotal),
                      style: theme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}