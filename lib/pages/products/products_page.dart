import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/product_filters.dart';
import 'widgets/product_form.dart';
import 'widgets/product_list_tile.dart';
import 'widgets/products_table.dart';

/// مدیریت محصولات: جستجو، فیلتر، ایجاد، ویرایش، حذف (با تأیید) و فعال/غیرفعال.
/// عرض محتوا ≥ ۷۲۰: جدول؛ کمتر: کارت‌های موبایل.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const double _tableMinWidth = 720;

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await Future.wait([
      context.read<ProductProvider>().load(),
      context.read<CategoryProvider>().load(),
    ]);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Product? product]) async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 560,
      builder: (_) => ProductForm(product: product),
    );
    if (saved == true && mounted) {
      _snack(product == null ? 'محصول جدید ثبت شد.' : 'تغییرات ذخیره شد.');
    }
  }

  Future<void> _delete(Product product) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف محصول',
      message: 'محصول «${product.name}» حذف شود؟ این کار قابل بازگشت نیست.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final AppFailure? failure =
        await context.read<ProductProvider>().delete(product.id);
    if (mounted) _snack(failure?.userMessage ?? 'محصول حذف شد.');
  }

  Future<void> _toggle(Product product) async {
    final failure = await context.read<ProductProvider>().toggleActive(product);
    if (failure != null && mounted) _snack(failure.userMessage);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final names = {for (final c in categories) c.id: c.name};

    return RefreshIndicator(
      onRefresh: _reload,
      child: AsyncStateView<List<Product>>(
        state: provider.state,
        onRetry: _reload,
        builder: (context, all) {
          final visible = provider.visible;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'محصولات',
                    subtitle: all.isEmpty
                        ? null
                        : 'نمایش ${_fa(visible.length)} از ${_fa(all.length)} محصول',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('محصول جدید'),
                      ),
                    ],
                  ),
                  if (all.isNotEmpty) ...[
                    ProductFilters(
                      provider: provider,
                      categories: categories,
                      searchController: _search,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (all.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هنوز محصولی ثبت نشده',
                        message: 'اولین محصول منو را اضافه کنید.',
                        icon: Icons.local_cafe_outlined,
                        action: FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن محصول'),
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'محصولی با این جستجو یا فیلتر پیدا نشد',
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
                          return ProductsTable(
                            products: visible,
                            categoryNames: names,
                            onEdit: _openForm,
                            onDelete: _delete,
                            onToggle: _toggle,
                          );
                        }
                        return Column(
                          children: [
                            for (final p in visible)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.md),
                                child: ProductListTile(
                                  product: p,
                                  categoryName: names[p.categoryId] ?? '—',
                                  onEdit: () => _openForm(p),
                                  onDelete: () => _delete(p),
                                  onToggle: () => _toggle(p),
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