// lib/pages/expenses/expenses_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/expense_filters.dart';
import 'widgets/expense_form.dart';
import 'widgets/expense_list_tile.dart';
import 'widgets/expenses_table.dart';

/// مدیریت هزینه‌ها: جستجو، فیلتر دسته‌بندی، ثبت، ویرایش و حذف.
/// عرض محتوا ≥ ۷۲۰: جدول؛ کمتر: کارت‌های موبایل.
class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  static const double _tableMinWidth = 720;

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpenseProvider>().load();
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

  Future<void> _openForm([Expense? expense]) async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 560,
      builder: (_) => ExpenseForm(expense: expense),
    );
    if (saved == true && mounted) {
      _snack(expense == null ? 'هزینه جدید ثبت شد.' : 'تغییرات ذخیره شد.');
    }
  }

  Future<void> _delete(Expense expense) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف هزینه',
      message: 'هزینه «${expense.title}» حذف شود؟ این کار قابل بازگشت نیست.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final AppFailure? failure =
        await context.read<ExpenseProvider>().delete(expense.id);
    if (mounted) _snack(failure?.userMessage ?? 'هزینه حذف شد.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<Expense>>(
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
                    title: 'هزینه‌ها',
                    subtitle: all.isEmpty
                        ? null
                        : 'جمع ${_fa(visible.length)} هزینه: '
                            '${PersianFormat.money(provider.totalAmount)}',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('هزینه جدید'),
                      ),
                    ],
                  ),
                  if (all.isNotEmpty) ...[
                    ExpenseFilters(
                        provider: provider, searchController: _search),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (all.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هنوز هزینه‌ای ثبت نشده',
                        message: 'اولین هزینه‌ی کافه را ثبت کنید.',
                        icon: Icons.payments_outlined,
                        action: FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن هزینه'),
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'هزینه‌ای با این جستجو یا فیلتر پیدا نشد',
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
                          return ExpensesTable(
                            expenses: visible,
                            onEdit: _openForm,
                            onDelete: _delete,
                          );
                        }
                        return Column(
                          children: [
                            for (final e in visible)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: ExpenseListTile(
                                  expense: e,
                                  onEdit: () => _openForm(e),
                                  onDelete: () => _delete(e),
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
