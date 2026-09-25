import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:cafe_book_admin/widgets/panel_card.dart';
import 'package:cafe_book_admin/widgets/state_views.dart';
import 'package:cafe_book_admin/widgets/status_chip.dart';
import 'package:cafe_book_admin/widgets/status_tones.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/inventory_item.dart';

import '../../shell/app_destination.dart';

class LowStockPanel extends StatelessWidget {
  const LowStockPanel({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return PanelCard(
      title: 'موجودی‌های کم',
      icon: Icons.inventory_2_outlined,
      action: TextButton(
        onPressed: () =>
            context.read<NavigationProvider>().select(AppDestination.inventory),
        child: const Text('انبار'),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyView(
                title: 'موجودی همه‌ی اقلام کافی است',
                icon: Icons.check_circle_outline,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(items[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.titleSmall),
                              Text(
                                'موجودی ${items[i].unit.format(items[i].currentStock)}'
                                ' • حداقل ${items[i].unit.format(items[i].minStock)}',
                                style: theme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(
                          label: items[i].stockStatus.label,
                          tone: items[i].stockStatus.tone,
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
