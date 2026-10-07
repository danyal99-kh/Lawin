import 'package:cafe_book_admin/responsive/adaptive_grid.dart';
import 'package:cafe_book_admin/widgets/stat_card.dart';
import 'package:cafe_book_admin/widgets/status_chip.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/persian_format.dart';
import '../../../models/dashboard_summary.dart';

/// ردیف کارت‌های شمارشی داشبورد (میزها، سفارش‌ها، انبار و نقدینگی).
///
/// کارت‌های مالی فروش/هزینه/سود عمداً اینجا نیستند؛ ارقام مالی فقط در
/// بخش‌های حسابداری و گزارش‌ها نمایش داده می‌شوند. جای آن‌ها را کارت
/// «وضعیت کافه» گرفته که بالای این آمار می‌آید.
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveGrid(
          minItemWidth: 150,
          maxColumns: 4,
          spacing: 12,
          runSpacing: 12,
          children: [
            MetricCard(
              label: 'میزهای فعال',
              value: PersianFormat.digits(summary.activeTables),
              icon: Icons.table_restaurant,
              tone: StatusTone.info,
            ),
            MetricCard(
              label: 'میزهای خالی',
              value: PersianFormat.digits(summary.emptyTables),
              icon: Icons.event_seat_outlined,
              tone: StatusTone.neutral,
            ),
            MetricCard(
              label: 'میزهای رزرو',
              value: PersianFormat.digits(summary.reservedTables),
              icon: Icons.bookmark_outline,
              tone: StatusTone.warning,
            ),
            MetricCard(
              label: 'سفارش‌های امروز',
              value: PersianFormat.digits(summary.todayOrderCount),
              icon: Icons.receipt_long_outlined,
              tone: StatusTone.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdaptiveGrid(
          minItemWidth: 150,
          maxColumns: 4,
          spacing: 12,
          runSpacing: 12,
          children: [
            MetricCard(
              label: 'ضایعات امروز',
              value: PersianFormat.money(summary.todayWaste),
              icon: Icons.delete_outline,
              tone: summary.todayWaste > 0
                  ? StatusTone.warning
                  : StatusTone.neutral,
            ),
          ],
        ),
      ],
    );
  }
}
