import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:cafe_book_admin/widgets/panel_card.dart';
import 'package:cafe_book_admin/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/expense.dart';

import '../../shell/app_destination.dart';

class RecentExpensesPanel extends StatelessWidget {
  const RecentExpensesPanel({super.key, required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return PanelCard(
      title: 'آخرین هزینه‌ها',
      icon: Icons.payments_outlined,
      action: TextButton(
        onPressed: () =>
            context.read<NavigationProvider>().select(AppDestination.expenses),
        child: const Text('همه هزینه‌ها'),
      ),
      child: expenses.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyView(
                title: 'هزینه‌ای ثبت نشده',
                icon: Icons.payments_outlined,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < expenses.length; i++) ...[
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
                              Text(expenses[i].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.titleSmall),
                              Text(
                                '${expenses[i].category.label} • ${PersianFormat.date(expenses[i].date)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            PersianFormat.money(expenses[i].amount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall,
                          ),
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
