import 'package:flutter/material.dart';

import '../../../core/utils/persian_format.dart';
import '../../../models/report.dart';
import '../../../responsive/adaptive_grid.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/status_chip.dart';

/// کارت‌های شمارشی خلاصه‌ی گزارش.
///
/// ارقام از دفتر حسابداری بک‌اند خوانده می‌شوند و اینجا دوباره حساب نمی‌شوند.
/// «سود» یعنی [SalesReport.netProfit] (پس از کسر بهای تمام‌شده، هزینه‌های
/// عمومی و ضایعات) و «سود ناخالص» پیش از آن‌هاست.
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
          label: 'بهای تمام‌شده',
          value: PersianFormat.money(report.totalCogs),
          icon: Icons.inventory_2_outlined,
          tone: StatusTone.warning,
        ),
        MetricCard(
          label: 'هزینه و ضایعات',
          value: PersianFormat.money(report.totalExpenses + report.totalWaste),
          icon: Icons.south_west,
          tone: StatusTone.warning,
        ),
        MetricCard(
          label: 'سود خالص',
          value: PersianFormat.money(report.netProfit),
          icon: Icons.account_balance_wallet_outlined,
          tone: report.netProfit < 0 ? StatusTone.danger : StatusTone.info,
        ),
        MetricCard(
          label: 'سود ناخالص',
          value: PersianFormat.money(report.grossProfit),
          icon: Icons.show_chart,
          tone: StatusTone.info,
        ),
        MetricCard(
          label: 'ارزش انبار',
          value: PersianFormat.money(report.inventoryValue),
          icon: Icons.warehouse_outlined,
          tone: StatusTone.neutral,
        ),
        MetricCard(
          label: 'مانده نقدی',
          value: PersianFormat.money(report.closingBalance),
          icon: Icons.account_balance_outlined,
          tone: report.closingBalance < 0
              ? StatusTone.danger
              : StatusTone.success,
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
        MetricCard(
          label: 'مانده‌ی طلب (نسیه)',
          value: PersianFormat.money(report.outstandingReceivables),
          icon: Icons.account_balance_outlined,
          tone: report.outstandingReceivables > 0
              ? StatusTone.danger
              : StatusTone.success,
        ),
        MetricCard(
          label: 'نسیه‌ی فروش در بازه',
          value: PersianFormat.money(report.creditSales),
          icon: Icons.receipt_outlined,
          tone: StatusTone.warning,
        ),
        MetricCard(
          label: 'وصول نسیه در بازه',
          value: PersianFormat.money(report.creditCollections),
          icon: Icons.savings_outlined,
          tone: StatusTone.success,
        ),
      ],
    );
  }
}
