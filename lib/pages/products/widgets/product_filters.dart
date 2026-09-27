import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/product_category.dart';
import '../../../providers/product_provider.dart';

/// جستجوی نام + فیلتر دسته‌بندی + فیلتر وضعیت.
class ProductFilters extends StatelessWidget {
  const ProductFilters({
    super.key,
    required this.provider,
    required this.categories,
    required this.searchController,
  });

  final ProductProvider provider;
  final List<ProductCategory> categories;
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
            hintText: 'جستجوی نام محصول…',
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
            ChoiceChip(
              showCheckmark: false,
              selected: provider.categoryId == null,
              label: const Text('همه دسته‌ها'),
              onSelected: (_) => provider.setCategory(null),
            ),
            for (final c in categories)
              ChoiceChip(
                showCheckmark: false,
                selected: provider.categoryId == c.id,
                label: Text(c.name),
                onSelected: (_) => provider.setCategory(c.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in ProductStatusFilter.values)
              ChoiceChip(
                showCheckmark: false,
                selected: provider.status == s,
                label: Text(s.label),
                onSelected: (_) => provider.setStatus(s),
              ),
          ],
        ),
      ],
    );
  }
}
