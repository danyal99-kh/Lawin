import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/report.dart';
import '../../providers/report_provider.dart';
import '../../responsive/breakpoints.dart';
import '../../responsive/page_container.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/expense_breakdown_panel.dart';
import 'widgets/report_period_selector.dart';
import 'widgets/report_summary_cards.dart';
import 'widgets/sales_trend_chart.dart';
import 'widgets/top_products_panel.dart';

/// گزارش فروش/هزینه/سود برای یک بازه‌ی زمانی، همراه با پرفروش‌ترین محصولات
/// و تفکیک هزینه‌ها. پیش‌فرض «این ماه» است.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<SalesReport>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, report) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'گزارش‌ها',
                  subtitle: '${PersianFormat.date(report.start)} تا '
                      '${PersianFormat.date(report.end.subtract(const Duration(days: 1)))}',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: provider.load,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('تازه‌سازی'),
                    ),
                  ],
                ),
                ReportPeriodSelector(provider: provider),
                const SizedBox(height: AppSpacing.lg),
                ReportSummaryCards(report: report),
                const SizedBox(height: AppSpacing.lg),
                SalesTrendChart(points: report.dailyPoints),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final topProducts =
                        TopProductsPanel(products: report.topProducts);
                    final expenseBreakdown =
                        ExpenseBreakdownPanel(items: report.expensesByCategory);
                    if (constraints.maxWidth >=
                        Breakpoints.contentTwoColumnMin) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: topProducts),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: expenseBreakdown),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        topProducts,
                        const SizedBox(height: AppSpacing.lg),
                        expenseBreakdown,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
