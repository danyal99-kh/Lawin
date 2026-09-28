import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/report.dart';
import '../../../widgets/panel_card.dart';
import '../../../widgets/state_views.dart';

class ExpenseBreakdownPanel extends StatelessWidget {
  const ExpenseBreakdownPanel({super.key, required this.items});

  final List<ExpenseByCategory> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final total = items.fold<int>(0, (s, e) => s + e.amount);

    return PanelCard(
      title: 'تفکیک هزینه‌ها',
      icon: Icons.pie_chart_outline,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyView(
                  title: 'در این بازه هزینه‌ای ثبت نشده',
                  icon: Icons.payments_outlined),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(items[i].category.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.titleSmall),
                            ),
                            Text(
                              total == 0
                                  ? '—'
                                  : '${PersianFormat.digits(((items[i].amount / total) * 100).round())}٪',
                              style: theme.bodySmall,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(PersianFormat.money(items[i].amount),
                                style: theme.titleSmall
                                    ?.copyWith(color: AppColors.wood)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : items[i].amount / total,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceMuted,
                            color: AppColors.wood,
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
