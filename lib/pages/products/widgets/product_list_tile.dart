import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/product.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/product_image.dart';
import 'product_price.dart';
import 'product_status_switch.dart';

/// کارت محصول برای موبایل (جایگزین ردیف جدول).
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onOffer,
  });

  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(imageUrl: product.imageUrl, size: 60),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        tooltip: 'گزینه‌ها',
                        onSelected: (v) => switch (v) {
                          'edit' => onEdit(),
                          'offer' => onOffer(),
                          _ => onDelete(),
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                          PopupMenuItem(
                              value: 'offer',
                              child: Text('آفر / تخفیف')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                ProductPrice(product: product),
                const SizedBox(height: AppSpacing.xs),
                ProductStatusSwitch(product: product, onChanged: onToggle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}