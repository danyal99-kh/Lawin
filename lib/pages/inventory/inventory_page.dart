// lib/pages/inventory/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/inventory_filters.dart';
import 'widgets/inventory_form.dart';
import 'widgets/inventory_list_tile.dart';
import 'widgets/inventory_table.dart';

/// مدیریت انبار: تعریف کالا، جستجو و فیلتر بر اساس وضعیت موجودی، ویرایش و حذف.
/// افزایش موجودی (خرید) و کاهش موجودی (ضایعات) در قسمت‌های بعدی همین مرحله اضافه می‌شود.
/// عرض محتوا ≥ ۷۲۰: جدول؛ کمتر: کارت‌های موبایل.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const double _tableMinWidth = 720;

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InventoryProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([InventoryItem? item]) async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 560,
      builder: (_) => InventoryForm(item: item),
    );
    if (saved == true && mounted) {
      _snack(item == null ? 'کالای جدید ثبت شد.' : 'تغییرات ذخیره شد.');
    }
  }

  Future<void> _delete(InventoryItem item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف کالا',
      message: 'کالای «${item.name}» حذف شود؟ این کار قابل بازگشت نیست.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final AppFailure? failure =
        await context.read<InventoryProvider>().delete(item.id);
    if (mounted) _snack(failure?.userMessage ?? 'کالا حذف شد.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<InventoryItem>>(
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
                    title: 'انبار',
                    subtitle: all.isEmpty
                        ? null
                        : 'نمایش ${_fa(visible.length)} از ${_fa(all.length)} کالا',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('کالای جدید'),
                      ),
                    ],
                  ),
                  if (all.isNotEmpty) ...[
                    InventoryFilters(
                        provider: provider, searchController: _search),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (all.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هنوز کالایی در انبار ثبت نشده',
                        message: 'اولین کالای انبار را اضافه کنید.',
                        icon: Icons.inventory_2_outlined,
                        action: FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن کالا'),
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'کالایی با این جستجو یا فیلتر پیدا نشد',
                        icon: Icons.search_off,
                        action: OutlinedButton(
                          onPressed: () {
                            _search.clear();
                            provider.clearFilters();
                          },
                          child: const Text('پاک کردن فیلترها'),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= _tableMinWidth) {
                          return InventoryTable(
                            items: visible,
                            onEdit: _openForm,
                            onDelete: _delete,
                          );
                        }
                        return Column(
                          children: [
                            for (final i in visible)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: InventoryListTile(
                                  item: i,
                                  onEdit: () => _openForm(i),
                                  onDelete: () => _delete(i),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _fa(int n) => PersianFormat.digits(n);
}
