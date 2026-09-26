// lib/pages/inventory/widgets/inventory_table.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/inventory_item.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';
import '../../../widgets/status_tones.dart';

/// جدول کالاهای انبار برای تبلت/دسکتاپ.
class InventoryTable extends StatelessWidget {
  const InventoryTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InventoryItem> items;
  final void Function(InventoryItem) onEdit;
  final void Function(InventoryItem) onDelete;

  static const double _actions = 96;

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
              Expanded(flex: 3, child: Text('نام کالا', style: head)),
              Expanded(flex: 2, child: Text('موجودی فعلی', style: head)),
              Expanded(flex: 2, child: Text('حداقل موجودی', style: head)),
              Expanded(flex: 2, child: Text('قیمت خرید', style: head)),
              Expanded(flex: 2, child: Text('وضعیت', style: head)),
              const SizedBox(width: _actions),
            ],
          ),
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          for (final i in items) ...[
            const Divider(),
            InkWell(
              onTap: () => onEdit(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall),
                          if (i.description != null)
                            Text(i.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(i.unit.format(i.currentStock),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(i.unit.format(i.minStock),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                          i.unitCost == 0
                              ? '—'
                              : PersianFormat.money(i.unitCost),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: StatusChip(
                            label: i.stockStatus.label,
                            tone: i.stockStatus.tone),
                      ),
                    ),
                    SizedBox(
                      width: _actions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'ویرایش',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(i),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => onDelete(i),
                          ),
                        ],
                      ),
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
