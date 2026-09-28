import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/report.dart';
import '../../../widgets/panel_card.dart';
import '../../../widgets/state_views.dart';

class TopProductsPanel extends StatelessWidget {
  const TopProductsPanel({super.key, required this.products});

  final List<ProductSales> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final maxRevenue = products.isEmpty
        ? 0
        : products.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);

    return PanelCard(
      title: 'پرفروش‌ترین محصولات',
      icon: Icons.local_cafe_outlined,
      child: products.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyView(
                  title: 'در این بازه فروشی ثبت نشده',
                  icon: Icons.local_cafe_outlined),
            )
          : Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                                width: 22,
                                child: Text(PersianFormat.digits(i + 1),
                                    style: theme.bodySmall)),
                            Expanded(
                              child: Text(products[i].productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.titleSmall),
                            ),
                            Text(
                                '${PersianFormat.digits(products[i].quantity)} عدد',
                                style: theme.bodySmall),
                            const SizedBox(width: AppSpacing.sm),
                            Text(PersianFormat.money(products[i].revenue),
                                style: theme.titleSmall
                                    ?.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: maxRevenue == 0
                                ? 0
                                : products[i].revenue / maxRevenue,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceMuted,
                            color: AppColors.primary,
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
