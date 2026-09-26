import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../core/utils/view_state.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/table_provider.dart';
import '../../responsive/adaptive_grid.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/order_card.dart';
import 'widgets/order_filter_bar.dart';
import 'widgets/order_form.dart';

/// مدیریت سفارش‌ها: صف کار آشپزخانه (جدید/آماده‌سازی/آماده/تحویل‌شده) + تاریخچه‌ی پرداخت/لغو.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderProvider>().load();
      // محصولات و میزها برای فرم ثبت سفارش لازم‌اند؛ اگر هنوز بار نشده‌اند بارگذاری کن.
      final products = context.read<ProductProvider>();
      if (products.state.status == ViewStatus.initial) products.load();
      final tables = context.read<TableProvider>();
      if (tables.state.status == ViewStatus.initial) tables.load();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm() async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 560,
      builder: (_) => const OrderForm(),
    );
    if (saved == true && mounted) _snack('سفارش جدید ثبت شد.');
  }

  Future<void> _advance(Order order, OrderStatus next) async {
    final failure =
        await context.read<OrderProvider>().updateStatus(order, next);
    if (mounted && failure != null) _snack(failure.userMessage);
  }

  Future<void> _cancel(Order order) async {
    final ok = await showConfirmDialog(
      context,
      title: 'لغو سفارش',
      message:
          'سفارش ${PersianFormat.digits(order.number)} لغو شود؟ این کار قابل بازگشت نیست.',
      confirmLabel: 'لغو سفارش',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final failure = await context.read<OrderProvider>().cancel(order);
    if (mounted) _snack(failure?.userMessage ?? 'سفارش لغو شد.');
  }

  Future<void> _print(Order order) async {
    final failure = await context.read<OrderProvider>().markBarPrinted(order);
    if (mounted) {
      _snack(failure?.userMessage ?? 'سفارش برای چاپ به بار ارسال شد.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<Order>>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, all) {
          final visible = provider.visible;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'سفارش‌ها',
                    subtitle: all.isEmpty
                        ? null
                        : 'نمایش ${PersianFormat.digits(visible.length)} از ${PersianFormat.digits(all.length)} سفارش',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                      FilledButton.icon(
                        onPressed: _openForm,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('سفارش جدید'),
                      ),
                    ],
                  ),
                  if (all.isNotEmpty) ...[
                    OrderFilterBar(provider: provider),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (all.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هنوز سفارشی ثبت نشده',
                        message: 'اولین سفارش را برای یکی از میزها ثبت کنید.',
                        icon: Icons.receipt_long_outlined,
                        action: FilledButton.icon(
                          onPressed: _openForm,
                          icon: const Icon(Icons.add),
                          label: const Text('ثبت سفارش'),
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'سفارشی با این وضعیت وجود ندارد',
                        icon: Icons.filter_alt_off_outlined,
                        action: OutlinedButton(
                          onPressed: () => provider.setFilter(OrderFilter.open),
                          child: const Text('نمایش سفارش‌های باز'),
                        ),
                      ),
                    )
                  else
                    AdaptiveGrid(
                      minItemWidth: 300,
                      maxColumns: 3,
                      children: [
                        for (final o in visible)
                          OrderCard(
                            order: o,
                            busy: provider.busy,
                            onAdvance: (next) => _advance(o, next),
                            onCancel: () => _cancel(o),
                            onPrint: () => _print(o),
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
