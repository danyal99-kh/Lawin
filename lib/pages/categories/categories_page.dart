import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/product_category.dart';
import '../../providers/category_provider.dart';
import '../../responsive/adaptive_grid.dart';
import '../../responsive/page_container.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/category_form_dialog.dart';

/// مدیریت دسته‌بندی محصولات: ایجاد، ویرایش و حذف (با تأیید).
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryProvider>().load();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([ProductCategory? category]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CategoryFormDialog(category: category),
    );
    if (saved == true && mounted) {
      _snack(category == null ? 'دسته‌بندی جدید ثبت شد.' : 'تغییرات ذخیره شد.');
    }
  }

  Future<void> _delete(ProductCategory category) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف دسته‌بندی',
      message: 'دسته‌بندی «${category.name}» حذف شود؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final failure = await context.read<CategoryProvider>().delete(category.id);
    if (mounted) _snack(failure?.userMessage ?? 'دسته‌بندی حذف شد.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<ProductCategory>>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, categories) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'دسته‌بندی محصولات',
                  subtitle: 'دسته‌ای که محصول دارد قابل حذف نیست.',
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('دسته‌بندی جدید'),
                    ),
                  ],
                ),
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: EmptyView(
                      title: 'هنوز دسته‌بندی‌ای ساخته نشده',
                      message: 'مثلاً قهوه، چای، کیک یا دسر.',
                      icon: Icons.category_outlined,
                      action: FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('افزودن دسته‌بندی'),
                      ),
                    ),
                  )
                else
                  AdaptiveGrid(
                    minItemWidth: 280,
                    maxColumns: 4,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final c in categories)
                        _CategoryCard(
                          category: c,
                          onEdit: () => _openForm(c),
                          onDelete: () => _delete(c),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.woodSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.category_outlined,
                color: AppColors.wood, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
                Text('${PersianFormat.digits(category.productCount)} محصول',
                    style: theme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ویرایش',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}