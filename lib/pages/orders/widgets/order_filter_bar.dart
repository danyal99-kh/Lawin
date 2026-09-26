import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../providers/order_provider.dart';

/// فیلتر وضعیت سفارش‌ها با شمارنده؛ روی موبایل به چند خط می‌شکند.
class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({super.key, required this.provider});

  final OrderProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final f in OrderFilter.values)
          ChoiceChip(
            showCheckmark: false,
            selected: provider.filter == f,
            label: Text(
                '${f.label} (${PersianFormat.digits(provider.countFor(f))})'),
            onSelected: (_) => provider.setFilter(f),
          ),
      ],
    );
  }
}
