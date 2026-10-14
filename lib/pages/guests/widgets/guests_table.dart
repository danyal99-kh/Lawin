import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/guest.dart';
import '../../../widgets/app_card.dart';

/// جدول گروه‌های مهمان برای تبلت/دسکتاپ.
class GuestsTable extends StatelessWidget {
  const GuestsTable({
    super.key,
    required this.groups,
    required this.onSelect,
  });

  final List<GuestGroup> groups;
  final void Function(GuestGroup) onSelect;

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
                Expanded(flex: 4, child: Text('مهمان', style: head)),
                Expanded(flex: 2, child: Text('تعداد سفارش', style: head)),
                Expanded(flex: 3, child: Text('جمع مهمان‌نوازی', style: head)),
                Expanded(flex: 3, child: Text('آخرین ثبت', style: head)),
              ],
            ),
          ),
          for (final g in groups) ...[
            const Divider(),
            InkWell(
              onTap: () => onSelect(g),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(PersianFormat.digits(g.orderCount),
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(PersianFormat.money(g.totalAmount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall
                              ?.copyWith(color: AppColors.primary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                          g.lastAt == null
                              ? '—'
                              : PersianFormat.dateTime(g.lastAt!),
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
