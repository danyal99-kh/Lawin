// lib/pages/purchases/widgets/purchases_table.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/purchase.dart';
import '../../../widgets/app_card.dart';

/// جدول خریدها برای تبلت/دسکتاپ.
class PurchasesTable extends StatelessWidget {
  const PurchasesTable({super.key, required this.purchases});

  final List<Purchase> purchases;

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
              Expanded(flex: 2, child: Text('قیمت واحد', style: head)),
              Expanded(flex: 2, child: Text('مبلغ کل', style: head)),
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
          for (final p in purchases) ...[
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
                        Text(p.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall),
                        if (p.note != null)
                          Text(p.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(p.unit.format(p.quantity),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(PersianFormat.money(p.unitCost),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(PersianFormat.money(p.totalCost),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall
                            ?.copyWith(color: AppColors.primary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(PersianFormat.dateTime(p.purchasedAt),
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
