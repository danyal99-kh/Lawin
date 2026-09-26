// lib/pages/waste/widgets/wastes_table.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/waste.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';

/// جدول ضایعات برای تبلت/دسکتاپ.
class WastesTable extends StatelessWidget {
  const WastesTable({super.key, required this.wastes});

  final List<Waste> wastes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final head = theme.labelMedium?.copyWith(color: AppColors.textSecondary);

    Widget header() => Container(
          color: AppColors.surfaceMuted,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('کالا', style: head)),
              Expanded(flex: 2, child: Text('مقدار', style: head)),
              Expanded(flex: 2, child: Text('دلیل', style: head)),
              Expanded(flex: 2, child: Text('ارزش', style: head)),
              Expanded(flex: 2, child: Text('تاریخ', style: head)),
            ],
          ),
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          for (final w in wastes) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall),
                        if (w.note != null)
                          Text(w.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(w.unit.format(w.quantity),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StatusChip(
                          label: w.reason.label, tone: StatusTone.warning),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                        w.totalCost == 0
                            ? '—'
                            : PersianFormat.money(w.totalCost),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall?.copyWith(
                            color: w.totalCost == 0
                                ? AppColors.textSecondary
                                : AppColors.danger)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(PersianFormat.dateTime(w.wastedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
