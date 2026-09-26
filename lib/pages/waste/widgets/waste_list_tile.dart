// lib/pages/waste/widgets/waste_list_tile.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/waste.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';

/// کارت یک رکورد ضایعات برای موبایل.
class WasteListTile extends StatelessWidget {
  const WasteListTile({super.key, required this.waste});

  final Waste waste;

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
                child: Text(waste.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
              ),
              if (waste.totalCost > 0)
                Text(PersianFormat.money(waste.totalCost),
                    style: theme.titleSmall?.copyWith(color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(waste.unit.format(waste.quantity), style: theme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              StatusChip(label: waste.reason.label, tone: StatusTone.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(PersianFormat.dateTime(waste.wastedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall),
              ),
            ],
          ),
          if (waste.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(waste.note!, style: theme.bodySmall),
          ],
        ],
      ),
    );
  }
}
