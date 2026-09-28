import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/report.dart';
import '../../../responsive/adaptive_grid.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/status_chip.dart';

/// کارت‌های شمارشی خلاصه‌ی گزارش: فروش، هزینه، سود، تعداد و میانگین سفارش.
class ReportSummaryCards extends StatelessWidget {
  const ReportSummaryCards({super.key, required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 200,
      maxColumns: 5,
      spacing: 12,
      runSpacing: 12,
      children: [
        MetricCard(
          label: 'فروش',
          value: PersianFormat.money(report.totalSales),
          icon: Icons.trending_up,
          tone: StatusTone.success,
        ),
        MetricCard(
          label: 'هزینه',
          value: PersianFormat.money(report.totalExpenses),
          icon: Icons.south_west,
          tone: StatusTone.warning,
        ),
        MetricCard(
          label: 'سود',
          value: PersianFormat.money(report.totalProfit),
          icon: Icons.account_balance_wallet_outlined,
          tone: report.totalProfit < 0 ? StatusTone.danger : StatusTone.info,
        ),
        MetricCard(
          label: 'تعداد سفارش',
          value: PersianFormat.digits(report.orderCount),
          icon: Icons.receipt_long_outlined,
          tone: StatusTone.info,
        ),
        MetricCard(
          label: 'میانگین هر سفارش',
          value: PersianFormat.money(report.averageOrderValue),
          icon: Icons.calculate_outlined,
          tone: StatusTone.neutral,
        ),
      ],
    );
  }
}
