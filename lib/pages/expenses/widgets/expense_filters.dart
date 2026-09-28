// lib/pages/expenses/widgets/expense_filters.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/enums.dart';
import '../../../providers/expense_provider.dart';

/// جستجوی عنوان + فیلتر دسته‌بندی هزینه.
class ExpenseFilters extends StatelessWidget {
  const ExpenseFilters({
    super.key,
    required this.provider,
    required this.searchController,
  });

  final ExpenseProvider provider;
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
            hintText: 'جستجوی عنوان هزینه…',
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
              selected: provider.category == null,
              label: const Text('همه دسته‌ها'),
              onSelected: (_) => provider.setCategory(null),
            ),
            for (final c in ExpenseCategory.values)
              ChoiceChip(
                showCheckmark: false,
                selected: provider.category == c,
                label: Text(c.label),
                onSelected: (_) => provider.setCategory(c),
              ),
          ],
        ),
      ],
    );
  }
}
