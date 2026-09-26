import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/enums.dart';
import '../../../models/order.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';
import '../../../widgets/status_tones.dart';
import '../../tables/widgets/info_row.dart' show shortWhen;

/// کارت یک سفارش: آیتم‌ها، وضعیت، و اقدام بعدی (پیشبرد وضعیت / لغو / چاپ سفارش بار).
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.busy,
    required this.onAdvance,
    required this.onCancel,
    required this.onPrint,
  });

  final Order order;
  final bool busy;
  final void Function(OrderStatus next) onAdvance;
  final VoidCallback onCancel;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final next = order.status.nextStep;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('سفارش ${PersianFormat.digits(order.number)}',
                        style: theme.titleMedium),
                    StatusChip(
                        label: order.status.label, tone: order.status.tone),
                    if (order.isFromCustomer)
                      const StatusChip(
                          label: 'مشتری',
                          tone: StatusTone.info,
                          icon: Icons.smartphone),
                  ],
                ),
              ),
              Text(
                order.tableNumber == null
                    ? '—'
                    : 'میز ${PersianFormat.digits(order.tableNumber)}',
                style: theme.titleSmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(shortWhen(order.createdAt), style: theme.bodySmall),
          const Divider(height: AppSpacing.lg),
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
                  Text(PersianFormat.money(item.lineTotal),
                      style: theme.bodySmall),
                ],
              ),
            ),
          if (order.customerNote != null &&
              order.customerNote!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('یادداشت: ${order.customerNote}', style: theme.bodySmall),
          ],
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Text('جمع', style: theme.titleSmall),
              const Spacer(),
              Text(PersianFormat.money(order.total),
                  style: theme.titleSmall?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onPrint,
                icon: Icon(order.barPrintedAt == null
                    ? Icons.print_outlined
                    : Icons.print),
                label: Text(
                    order.barPrintedAt == null ? 'چاپ سفارش بار' : 'چاپ مجدد'),
              ),
              if (order.status.isOpen)
                TextButton(
                  onPressed: busy ? null : onCancel,
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('لغو سفارش'),
                ),
              if (next != null)
                FilledButton(
                  onPressed: busy ? null : () => onAdvance(next),
                  child: Text(order.status.advanceLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
