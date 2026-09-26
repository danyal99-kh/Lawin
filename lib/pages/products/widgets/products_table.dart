import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/product.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/product_image.dart';
import 'product_status_switch.dart';

/// جدول محصولات برای تبلت/دسکتاپ. ستون‌ها Flex هستند؛ هیچ عرض ثابتی که Overflow بسازد وجود ندارد.
class ProductsTable extends StatelessWidget {
  const ProductsTable({
    super.key,
    required this.products,
    required this.categoryNames,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final List<Product> products;
  final Map<int, String> categoryNames;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;
  final void Function(Product) onToggle;

  static const double _thumb = 44;
  static const double _actions = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final head = theme.labelMedium?.copyWith(color: AppColors.textSecondary);

    Widget header() => Container(
          color: AppColors.surfaceMuted,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              const SizedBox(width: _thumb + AppSpacing.md),
              Expanded(flex: 3, child: Text('نام محصول', style: head)),
              Expanded(flex: 2, child: Text('دسته‌بندی', style: head)),
              Expanded(flex: 2, child: Text('قیمت فروش', style: head)),
              Expanded(flex: 3, child: Text('وضعیت', style: head)),
              const SizedBox(width: _actions),
            ],
          ),
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          for (final p in products) ...[
            const Divider(),
            InkWell(
              onTap: () => onEdit(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    ProductImage(imageUrl: p.imageUrl, size: _thumb),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall),
                          if (p.description != null)
                            Text(p.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(categoryNames[p.categoryId] ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(PersianFormat.money(p.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ProductStatusSwitch(
                            product: p, onChanged: () => onToggle(p)),
                      ),
                    ),
                    SizedBox(
                      width: _actions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'ویرایش',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(p),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => onDelete(p),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}