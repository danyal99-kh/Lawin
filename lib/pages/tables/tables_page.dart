import 'package:cafe_book_admin/pages/tables/widgets/payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/enums.dart';
import '../../models/table_overview.dart';
import '../../providers/table_provider.dart';
import '../../responsive/adaptive_grid.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/table_card.dart';
import 'widgets/table_detail.dart';
import 'widgets/table_filter_bar.dart';

/// صفحه‌ی میزها: وضعیت لحظه‌ای هر میز، مدت حضور زنده و جزئیات هر میز.
class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  @override
  void initState() {
    super.initState();
    // با هر ورود به صفحه داده تازه می‌شود.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TableProvider>().load();
    });
  }

  Future<void> _openDetail(TableOverview overview) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TableProvider>();
    final number = PersianFormat.digits(overview.table.number);

    if (overview.status == TableStatus.active && overview.hasOpenOrders) {
      final action = await showAdaptiveSheet<String>(
        context: context,
        builder: (ctx) => TableDetail(
          overview: overview,
          onToggleReserved: () {},
          onPay: () => Navigator.of(ctx).pop('pay'),
        ),
      );
      if (action != 'pay' || !mounted) return;
      final paid = await showDialog<bool>(
        context: context,
        builder: (_) => PaymentDialog(
          tableId: overview.table.id,
          amount: overview.currentAmount,
        ),
      );
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(paid == true
              ? 'صورتحساب میز $number با موفقیت پرداخت شد.'
              : 'پرداخت انجام نشد.'),
        ));
      }
      return;
    }

    final willReserve = overview.status != TableStatus.reserved;
    final confirmed = await showAdaptiveSheet<bool>(
      context: context,
      builder: (ctx) => TableDetail(
        overview: overview,
        onToggleReserved: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed != true) return;

    final failure = await provider.setReserved(overview.table.id, willReserve);
    messenger.showSnackBar(SnackBar(
      content: Text(failure?.userMessage ??
          (willReserve ? 'میز $number رزرو شد.' : 'رزرو میز $number لغو شد.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TableProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<TableOverview>>(
        state: provider.state,
        onRetry: provider.load,
        emptyTitle: 'میزی تعریف نشده است',
        emptyIcon: Icons.table_restaurant_outlined,
        builder: (context, _) {
          final visible = provider.visible;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'وضعیت میزها',
                    subtitle:
                        'زمان ورود با اولین سفارش و زمان خروج با پرداخت، خودکار ثبت می‌شود.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                    ],
                  ),
                  TableFilterBar(provider: provider),
                  const SizedBox(height: AppSpacing.lg),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'میزی با این وضعیت وجود ندارد',
                        icon: Icons.filter_alt_off_outlined,
                      ),
                    )
                  else
                    AdaptiveGrid(
                      minItemWidth: 260,
                      maxColumns: 5,
                      children: [
                        for (final o in visible)
                          TableCard(
                            overview: o,
                            onTap: () => _openDetail(o),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
