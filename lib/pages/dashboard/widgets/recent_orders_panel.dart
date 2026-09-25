import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:cafe_book_admin/widgets/panel_card.dart';
import 'package:cafe_book_admin/widgets/state_views.dart';
import 'package:cafe_book_admin/widgets/status_chip.dart';
import 'package:cafe_book_admin/widgets/status_tones.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_ranges.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/order.dart';

import '../../shell/app_destination.dart';

class RecentOrdersPanel extends StatelessWidget {
  const RecentOrdersPanel({super.key, required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    void openOrders() =>
        context.read<NavigationProvider>().select(AppDestination.orders);

    return PanelCard(
      title: 'سفارش‌های اخیر',
      icon: Icons.receipt_long_outlined,
      action: TextButton(
        onPressed: openOrders,
        child: const Text('همه سفارش‌ها'),
      ),
      child: orders.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyView(
                title: 'هنوز سفارشی ثبت نشده',
                icon: Icons.receipt_long_outlined,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  if (i > 0) const Divider(),
                  _OrderRow(order: orders[i], onTap: openOrders),
                ],
              ],
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  String _when() => DateRanges.sameDay(order.createdAt, DateTime.now())
      ? PersianFormat.time(order.createdAt)
      : PersianFormat.dateTime(order.createdAt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            _TableBadge(number: order.tableNumber),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('سفارش ${PersianFormat.digits(order.number)}',
                          style: theme.titleSmall),
                      if (order.isFromCustomer)
                        const StatusChip(
                            label: 'مشتری',
                            tone: StatusTone.info,
                            icon: Icons.smartphone),
                    ],
                  ),
                  Text(
                    '${_when()} • ${PersianFormat.digits(order.itemCount)} آیتم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(PersianFormat.money(order.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  StatusChip(
                      label: order.status.label, tone: order.status.tone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableBadge extends StatelessWidget {
  const _TableBadge({required this.number});

  final int? number;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          number == null ? '—' : PersianFormat.digits(number),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.primaryDark),
        ),
      );
}
