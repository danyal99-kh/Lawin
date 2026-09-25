import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';

/// هشدار واضح موجودی کم: «۳ قلم کالا موجودی کمی دارند».
class LowStockBanner extends StatelessWidget {
  const LowStockBanner({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.warningSoft,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '${PersianFormat.digits(count)} قلم کالا موجودی کمی دارند',
                  style: theme.titleSmall?.copyWith(color: AppColors.warning),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('مشاهده انبار',
                  style: theme.labelLarge?.copyWith(color: AppColors.warning)),
              const Icon(Icons.chevron_left, color: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}
