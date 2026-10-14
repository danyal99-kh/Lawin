import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/product.dart';

/// نمایش قیمت محصول: اگر آفر فعال باشد، قیمت پایه خط‌خورده + قیمت مؤثر + برچسب درصد.
class ProductPrice extends StatelessWidget {
  const ProductPrice({super.key, required this.product, this.compact = false});

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final base = Text(
      PersianFormat.money(product.price),
      style: theme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        decoration: TextDecoration.lineThrough,
      ),
    );
    final finalPrice = Text(
      PersianFormat.money(product.finalPrice),
      style: theme.titleSmall?.copyWith(color: AppColors.primary),
    );

    if (!product.hasOffer) return finalPrice;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          base,
          const SizedBox(width: AppSpacing.xs),
        ],
        finalPrice,
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '${PersianFormat.digits(product.discountPercent)}٪',
            style: theme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
