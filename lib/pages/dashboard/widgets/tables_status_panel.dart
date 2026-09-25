import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:cafe_book_admin/responsive/adaptive_grid.dart';
import 'package:cafe_book_admin/widgets/panel_card.dart';
import 'package:cafe_book_admin/widgets/status_tones.dart' show TableStatusTone;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/cafe_table.dart';

import '../../shell/app_destination.dart';

class TablesStatusPanel extends StatelessWidget {
  const TablesStatusPanel({super.key, required this.tables});

  final List<CafeTable> tables;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'وضعیت میزها',
      icon: Icons.table_restaurant_outlined,
      action: TextButton(
        onPressed: () =>
            context.read<NavigationProvider>().select(AppDestination.tables),
        child: const Text('همه میزها'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AdaptiveGrid(
          minItemWidth: 84,
          maxColumns: 10,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final t in tables) _TableTile(table: t)],
        ),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table});

  final CafeTable table;

  @override
  Widget build(BuildContext context) {
    final tone = table.status.tone;
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.foreground.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(PersianFormat.digits(table.number),
              style: theme.titleMedium?.copyWith(color: tone.foreground)),
          Text(
            table.status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall?.copyWith(color: tone.foreground),
          ),
        ],
      ),
    );
  }
}
