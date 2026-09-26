// lib/pages/inventory/widgets/inventory_filters.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../providers/inventory_provider.dart';

/// جستجوی نام + فیلتر بر اساس وضعیت موجودی، با شمارنده روی هر فیلتر.
class InventoryFilters extends StatelessWidget {
  const InventoryFilters({
    super.key,
    required this.provider,
    required this.searchController,
  });

  final InventoryProvider provider;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: provider.setQuery,
          decoration: InputDecoration(
            hintText: 'جستجوی نام کالا…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: provider.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'پاک کردن',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      provider.setQuery('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in InventoryStockFilter.values)
              ChoiceChip(
                showCheckmark: false,
                selected: provider.filter == f,
                label: Text(
                    '${f.label} (${PersianFormat.digits(provider.countFor(f))})'),
                onSelected: (_) => provider.setFilter(f),
              ),
          ],
        ),
      ],
    );
  }
}
