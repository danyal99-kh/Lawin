import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/guest.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';

/// کارت یک گروه مهمان برای موبایل.
class GuestGroupTile extends StatelessWidget {
  const GuestGroupTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  final GuestGroup group;
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
                Text(group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${PersianFormat.digits(group.orderCount)} سفارش'
                  ' • آخرین ثبت: '
                  '${group.lastAt == null ? '—' : PersianFormat.dateTime(group.lastAt!)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(
                  label: PersianFormat.money(group.totalAmount),
                  tone: StatusTone.info,
                  icon: Icons.card_giftcard_outlined,
                ),
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
