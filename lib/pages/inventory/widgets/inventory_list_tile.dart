// lib/pages/inventory/widgets/inventory_list_tile.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/inventory_item.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';
import '../../../widgets/status_tones.dart';

/// کارت کالا برای موبایل (جایگزین ردیف جدول).
class InventoryListTile extends StatelessWidget {
  const InventoryListTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final tone = item.stockStatus.tone;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.inventory_2_outlined, color: tone.foreground),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        tooltip: 'گزینه‌ها',
                        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'موجودی ${item.unit.format(item.currentStock)}'
                  ' • حداقل ${item.unit.format(item.minStock)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusChip(label: item.stockStatus.label, tone: tone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
