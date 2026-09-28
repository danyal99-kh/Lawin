import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/report.dart';
import '../../../widgets/panel_card.dart';
import '../../../widgets/state_views.dart';

/// نمودار میله‌ای ساده‌ی روند فروش/هزینه‌ی روزانه (بدون کتابخانه‌ی خارجی).
class SalesTrendChart extends StatelessWidget {
  const SalesTrendChart({super.key, required this.points});

  final List<DailyPoint> points;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'روند فروش و هزینه',
      icon: Icons.show_chart,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: points.isEmpty
            ? const EmptyView(
                title: 'داده‌ای برای نمایش وجود ندارد', icon: Icons.show_chart)
            : _Chart(points: points),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points});

  final List<DailyPoint> points;

  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    final maxValue = points
        .map((p) => p.sales > p.expenses ? p.sales : p.expenses)
        .fold<int>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final p in points)
                Expanded(
                  child: Tooltip(
                    message: '${PersianFormat.date(p.date)}\n'
                        'فروش: ${PersianFormat.money(p.sales)}\n'
                        'هزینه: ${PersianFormat.money(p.expenses)}',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Bar(
                            height: _height * (p.sales / safeMax),
                            color: AppColors.success),
                        const SizedBox(width: 2),
                        _Bar(
                            height: _height * (p.expenses / safeMax),
                            color: AppColors.wood),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendDot(color: AppColors.success, label: 'فروش'),
            SizedBox(width: AppSpacing.lg),
            _LegendDot(color: AppColors.wood, label: 'هزینه'),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: height.clamp(2, double.infinity),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
