import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../providers/table_provider.dart';

/// فیلتر وضعیت میزها با شمارنده؛ روی موبایل به چند خط می‌شکند.
class TableFilterBar extends StatelessWidget {
  const TableFilterBar({super.key, required this.provider});

  final TableProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final f in TableFilter.values)
          ChoiceChip(
            showCheckmark: false,
            selected: provider.filter == f,
            label: Text('${f.label} (${PersianFormat.digits(provider.countFor(f))})'),
            onSelected: (_) => provider.setFilter(f),
          ),
      ],
    );
  }
}