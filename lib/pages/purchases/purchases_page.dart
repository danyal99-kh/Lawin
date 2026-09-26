// lib/pages/purchases/purchases_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/purchase.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/purchase_form.dart';
import 'widgets/purchase_list_tile.dart';
import 'widgets/purchases_table.dart';

/// تاریخچه‌ی خریدهای انبار و ثبت خرید جدید. با ثبت هر خرید، موجودی کالای
/// مربوطه در بخش «انبار» به‌طور خودکار افزایش می‌یابد.
/// عرض محتوا ≥ ۷۲۰: جدول؛ کمتر: کارت‌های موبایل.
class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  static const double _tableMinWidth = 720;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PurchaseProvider>().load();
      context.read<InventoryProvider>().load();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm() async {
    final items = context.read<InventoryProvider>().all;
    if (items.isEmpty) {
      _snack('ابتدا از بخش «انبار» یک کالا تعریف کنید.');
      return;
    }
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 560,
      builder: (_) => PurchaseForm(items: items),
    );
    if (saved == true && mounted) _snack('خرید با موفقیت ثبت شد.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final hasItems = context.watch<InventoryProvider>().all.isNotEmpty;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<Purchase>>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, purchases) {
          final total =
              purchases.fold<double>(0, (sum, p) => sum + p.totalCost);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'خریدها',
                    subtitle: purchases.isEmpty
                        ? null
                        : 'جمع ${PersianFormat.digits(purchases.length)} خرید: '
                            '${PersianFormat.money(total)}',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                      FilledButton.icon(
                        onPressed: hasItems ? _openForm : null,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('ثبت خرید'),
                      ),
                    ],
                  ),
                  if (purchases.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هنوز خریدی ثبت نشده',
                        message: hasItems
                            ? 'خرید مواد اولیه را از همین‌جا ثبت کنید.'
                            : 'ابتدا از بخش «انبار» یک کالا تعریف کنید.',
                        icon: Icons.shopping_cart_outlined,
                        action: hasItems
                            ? FilledButton.icon(
                                onPressed: _openForm,
                                icon: const Icon(Icons.add),
                                label: const Text('ثبت خرید'),
                              )
                            : null,
                      ),
                    )
                  else ...[
                    const SizedBox(height: AppSpacing.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= _tableMinWidth) {
                          return PurchasesTable(purchases: purchases);
                        }
                        return Column(
                          children: [
                            for (final p in purchases)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: PurchaseListTile(purchase: p),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
