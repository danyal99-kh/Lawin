import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';

/// هدر بالای محتوا در تبلت/دسکتاپ (در موبایل AppBar استفاده می‌شود).
class ShellHeader extends StatelessWidget {
  const ShellHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge),
          ),
          const Spacer(),
          Flexible(
            flex: 2,
            child: Text(
              PersianFormat.dateWithWeekday(DateTime.now()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySoft,
            child:
                Icon(Icons.person_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('ادمین', style: theme.labelLarge),
        ],
      ),
    );
  }
}
