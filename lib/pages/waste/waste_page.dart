// lib/pages/waste/waste_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/waste.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/waste_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/waste_form.dart';
import 'widgets/waste_list_tile.dart';
import 'widgets/wastes_table.dart';

/// تاریخچه‌ی ضایعات انبار و ثبت ضایعات جدید. با ثبت هر ضایعات، موجودی کالای
/// مربوطه در بخش «انبار» به‌طور خودکار کم می‌شود.
/// عرض محتوا ≥ ۷۲۰: جدول؛ کمتر: کارت‌های موبایل.
class WastePage extends StatefulWidget {
  const WastePage({super.key});

  @override
  State<WastePage> createState() => _WastePageState();
}

class _WastePageState extends State<WastePage> {
  static const double _tableMinWidth = 720;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WasteProvider>().load();
      context.read<InventoryProvider>().load();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm() async {
    final items = context
        .read<InventoryProvider>()
        .all
        .where((i) => i.currentStock > 0)
        .toList();
    if (items.isEmpty) {
      _snack('کالایی با موجودی برای ثبت ضایعات وجود ندارد.');
      return;
    }
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 560,
      builder: (_) => WasteForm(items: items),
    );
    if (saved == true && mounted) _snack('ضایعات با موفقیت ثبت شد.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WasteProvider>();
    final hasAvailableItems =
        context.watch<InventoryProvider>().all.any((i) => i.currentStock > 0);

    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<Waste>>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, wastes) {
          final total = wastes.fold<double>(0, (sum, w) => sum + w.totalCost);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'ضایعات',
                    subtitle: wastes.isEmpty
                        ? null
                        : 'جمع ${PersianFormat.digits(wastes.length)} مورد: '
                            '${PersianFormat.money(total)}',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                      FilledButton.icon(
                        onPressed: hasAvailableItems ? _openForm : null,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('ثبت ضایعات'),
                      ),
                    ],
                  ),
                  if (wastes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هنوز ضایعاتی ثبت نشده',
                        message: hasAvailableItems
                            ? 'کسری موجودی به دلیل خرابی یا انقضا را ثبت کنید.'
                            : 'کالایی با موجودی برای ثبت ضایعات وجود ندارد.',
                        icon: Icons.delete_outline,
                        action: hasAvailableItems
                            ? FilledButton.icon(
                                onPressed: _openForm,
                                icon: const Icon(Icons.add),
                                label: const Text('ثبت ضایعات'),
                              )
                            : null,
                      ),
                    )
                  else ...[
                    const SizedBox(height: AppSpacing.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= _tableMinWidth) {
                          return WastesTable(wastes: wastes);
                        }
                        return Column(
                          children: [
                            for (final w in wastes)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: WasteListTile(waste: w),
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
