import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'app_card.dart';
import 'status_chip.dart';

/// کارت مالی با دو مقدار: امروز (بزرگ) و این ماه.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.todayValue,
    required this.monthValue,
    this.todayValueColor,
    this.monthValueColor,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String todayValue;
  final String monthValue;
  final Color? todayValueColor;
  final Color? monthValueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon, color: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('امروز', style: theme.bodySmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(todayValue,
                style: theme.headlineSmall?.copyWith(color: todayValueColor)),
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Text('این ماه', style: theme.bodySmall),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(monthValue,
                      style:
                          theme.titleSmall?.copyWith(color: monthValueColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// کارت شمارشی کوچک (میز فعال، میز خالی، …).
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatusTone.info,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: tone.foreground, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall),
                Text(value, style: theme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: color, size: size * 0.55),
      );
}
