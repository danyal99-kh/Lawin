import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// لحن معنایی رنگ وضعیت‌ها.
/// سبز: موفق/پرداخت‌شده/موجود | نارنجی: هشدار/رزرو/در انتظار
/// قرمز: خطا/کسری/ضایعات | خاکستری: خالی/غیرفعال | فیروزه‌ای: اطلاع‌رسانی
enum StatusTone {
  success(AppColors.success, AppColors.successSoft),
  warning(AppColors.warning, AppColors.warningSoft),
  danger(AppColors.danger, AppColors.dangerSoft),
  neutral(AppColors.neutral, AppColors.neutralSoft),
  info(AppColors.info, AppColors.infoSoft);

  const StatusTone(this.foreground, this.background);
  final Color foreground;
  final Color background;
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: tone.foreground);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone.foreground),
            const SizedBox(width: AppSpacing.xs),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: tone.foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm - 2),
          ],
          Flexible(
            child: Text(label,
                style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
