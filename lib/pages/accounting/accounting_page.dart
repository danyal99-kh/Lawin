// lib/pages/accounting/accounting_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/accounting_entry.dart';
import '../../providers/accounting_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/accounting_entry_tile.dart';
import 'widgets/accounting_summary.dart';

/// حسابداری: دفتر ترکیبی درآمد (سفارش‌های پرداخت‌شده) و هزینه‌ها،
/// با فیلتر بازه‌ی زمانی و خلاصه‌ی سود/زیان.
class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AccountingProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountingProvider>();

    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<List<AccountingEntry>>(
        state: provider.state,
        onRetry: provider.load,
        emptyTitle: 'هنوز تراکنشی ثبت نشده',
        emptyIcon: Icons.account_balance_wallet_outlined,
        builder: (context, _) {
          final visible = provider.visible;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'حسابداری',
                    subtitle:
                        'دفتر ترکیبی درآمد و هزینه‌ها بر اساس بازه‌ی انتخابی.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: provider.load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in AccountingPeriod.values)
                        ChoiceChip(
                          showCheckmark: false,
                          selected: provider.period == p,
                          label: Text(p.label),
                          onSelected: (_) => provider.setPeriod(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AccountingSummary(
                    income: provider.totalIncome,
                    expense: provider.totalExpense,
                    profit: provider.profit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: EmptyView(
                        title: 'تراکنشی در این بازه وجود ندارد',
                        icon: Icons.filter_alt_off_outlined,
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < visible.length; i++) ...[
                            if (i > 0) const Divider(),
                            AccountingEntryTile(entry: visible[i]),
                          ],
                        ],
                      ),
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
