import 'package:cafe_book_admin/responsive/adaptive_grid.dart';
import 'package:cafe_book_admin/widgets/stat_card.dart';
import 'package:cafe_book_admin/widgets/status_chip.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/dashboard_summary.dart';

/// ردیف کارت‌های مالی (فروش / هزینه / سود) و کارت‌های شمارشی میز و سفارش.
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    Color? profitColor(int v) => v < 0 ? AppColors.danger : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveGrid(
          minItemWidth: 230,
          maxColumns: 3,
          children: [
            StatCard(
              title: 'فروش',
              icon: Icons.trending_up,
              accent: AppColors.success,
              todayValue: PersianFormat.money(summary.todaySales),
              monthValue: PersianFormat.money(summary.monthSales),
            ),
            StatCard(
              title: 'هزینه',
              icon: Icons.south_west,
              accent: AppColors.wood,
              todayValue: PersianFormat.money(summary.todayExpenses),
              monthValue: PersianFormat.money(summary.monthExpenses),
            ),
            StatCard(
              title: 'سود',
              icon: Icons.account_balance_wallet_outlined,
              accent: AppColors.primary,
              todayValue: PersianFormat.money(summary.todayProfit),
              monthValue: PersianFormat.money(summary.monthProfit),
              todayValueColor: profitColor(summary.todayProfit),
              monthValueColor: profitColor(summary.monthProfit),
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
      ],
    );
  }
}
