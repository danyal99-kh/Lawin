import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/credit.dart';
import '../../providers/credit_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/debtor_detail_sheet.dart';
import 'widgets/debtor_list_tile.dart';
import 'widgets/debtors_table.dart';
import 'widgets/settle_form.dart';

/// نسیه‌ها / حساب بدهکاران (Accounts Receivable).
///
/// فقط می‌خواند و تسویه ثبت می‌کند؛ هیچ رقمی را اینجا محاسبه نمی‌کند. مانده،
/// وضعیت و تخصیص oldest-first همه سمت بک‌اند تصمیم می‌گیرند.
class ReceivablesPage extends StatefulWidget {
  const ReceivablesPage({super.key});

  @override
  State<ReceivablesPage> createState() => _ReceivablesPageState();
}

class _ReceivablesPageState extends State<ReceivablesPage> {
  static const double _tableMinWidth = 860;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreditProvider>().load();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDetail(Debtor debtor) async {
    final provider = context.read<CreditProvider>();
    await provider.selectDebtor(debtor.id);
    if (!mounted) return;

    final target = await showAdaptiveSheet<Debtor>(
      context: context,
      maxDialogWidth: 640,
      builder: (_) => DebtorDetailSheet(
        onSettle: (d) => Navigator.of(context).pop(d),
      ),
    );
    if (!mounted) return;
    await provider.clearSelection();
    if (target != null) await _openSettle(target);
  }

  Future<void> _openSettle(Debtor debtor) async {
    final ok = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 480,
      builder: (_) => SettleForm(debtor: debtor),
    );
    if (!mounted) return;
    if (ok == true) {
      _snack('تسویه برای «${debtor.name}» ثبت شد.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditProvider>();

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: AsyncStateView<List<Debtor>>(
        state: provider.debtorsState,
        onRetry: provider.refresh,
        emptyTitle: 'هنوز بدهکاری ثبت نشده',
        emptyMessage: 'با پرداخت نسیه، نام بدهکار خودکار ساخته می‌شود.',
        emptyIcon: Icons.account_balance_outlined,
        builder: (context, debtors) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'نسیه‌ها',
                  subtitle: 'جمع طلب‌های وصول‌نشده: '
                      '${PersianFormat.money(provider.totalDebt)}'
                      ' • ${PersianFormat.digits(provider.openDebtors)} بدهکار',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: provider.refresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('تازه‌سازی'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'جست‌وجوی نام بدهکار',
                  ),
                  onChanged: provider.search,
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _tableMinWidth) {
                      return DebtorsTable(
                        debtors: debtors,
                        onSelect: _openDetail,
                      );
                    }
                    return Column(
                      children: [
                        for (final d in debtors)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: DebtorListTile(
                              debtor: d,
                              onTap: () => _openDetail(d),
                            ),
                          ),
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
