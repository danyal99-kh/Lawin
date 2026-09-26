import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../core/utils/view_state.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../responsive/breakpoints.dart';
import '../../responsive/page_container.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../shell/app_destination.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/low_stock_banner.dart';
import 'widgets/low_stock_panel.dart';
import 'widgets/recent_expenses_panel.dart';
import 'widgets/recent_orders_panel.dart';
import 'widgets/tables_status_panel.dart';

/// داشبورد ادمین: همه‌ی اطلاعات مهم در یک نگاه.
/// دسکتاپ: دو ستون (میزها + سفارش‌ها | موجودی + هزینه‌ها). موبایل/تبلت: یک ستون عمودی.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // بار اول خود Provider بارگذاری می‌کند؛ در بازدیدهای بعدی (مثلاً بعد از رزرو میز) تازه‌سازی می‌کنیم.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DashboardProvider>();
      if (provider.state.status == ViewStatus.success) provider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<DashboardSummary>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, summary) => SingleChildScrollView(
          // برای Pull-to-refresh حتی وقتی محتوا کوتاه است
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(child: _DashboardContent(summary: summary)),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final lowCount = summary.lowStockItems.length;

    final mainColumn = <Widget>[
      TablesStatusPanel(tables: summary.tables),
      const SizedBox(height: AppSpacing.lg),
      RecentOrdersPanel(orders: summary.recentOrders),
    ];
    final sideColumn = <Widget>[
      LowStockPanel(items: summary.lowStockItems),
      const SizedBox(height: AppSpacing.lg),
      RecentExpensesPanel(expenses: summary.recentExpenses),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'نمای کلی',
          subtitle: PersianFormat.dateWithWeekday(DateTime.now()),
          actions: [
            OutlinedButton.icon(
              onPressed: context.read<DashboardProvider>().load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('تازه‌سازی'),
            ),
          ],
        ),
        DashboardStats(summary: summary),
        if (lowCount > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          LowStockBanner(
            count: lowCount,
            onTap: () => context
                .read<NavigationProvider>()
                .select(AppDestination.inventory),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // چیدمان دو ستونه بر اساس «عرض محتوا» (نه عرض پنجره) تعیین می‌شود.
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= Breakpoints.contentTwoColumnMin) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: mainColumn),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 2,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: sideColumn),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...mainColumn,
                const SizedBox(height: AppSpacing.lg),
                ...sideColumn,
              ],
            );
          },
        ),
      ],
    );
  }
}