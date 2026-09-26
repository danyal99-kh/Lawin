// lib/pages/purchases/widgets/purchase_list_tile.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/purchase.dart';
import '../../../widgets/app_card.dart';

/// کارت یک خرید برای موبایل.
class PurchaseListTile extends StatelessWidget {
  const PurchaseListTile({super.key, required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(purchase.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
              ),
              Text(PersianFormat.money(purchase.totalCost),
                  style: theme.titleSmall?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${purchase.unit.format(purchase.quantity)} × '
            '${PersianFormat.money(purchase.unitCost)}',
            style: theme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(PersianFormat.dateTime(purchase.purchasedAt),
              style: theme.bodySmall),
          if (purchase.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(purchase.note!, style: theme.bodySmall),
          ],
        ],
      ),
    );
  }
}
