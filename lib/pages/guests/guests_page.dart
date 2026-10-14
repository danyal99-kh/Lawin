import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/persian_format.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import 'widgets/guest_group_sheet.dart';
import 'widgets/guest_group_tile.dart';
import 'widgets/guests_table.dart';

/// مهمان‌ها / پذیرایی رایگان.
///
/// فقط می‌خواند، نام را تغییر می‌دهد و لغو می‌کند؛ هیچ رقمی را اینجا محاسبه
/// نمی‌کند. جمع‌ها، وضعیت و اثر دفتری همه سمت بک‌اند تصمیم می‌گیرند. ثبت مهمان
/// از مسیر پرداخت میز (گزینه‌ی «مهمان») انجام می‌شود.
class GuestsPage extends StatefulWidget {
  const GuestsPage({super.key});

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  static const double _tableMinWidth = 760;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GuestProvider>().load();
    });
  }

  Future<void> _openGroup(GuestGroup group) async {
    final provider = context.read<GuestProvider>();
    await provider.selectGroup(group.name);
    if (!mounted) return;

    await showAdaptiveSheet<void>(
      context: context,
      maxDialogWidth: 640,
      builder: (_) => GuestGroupSheet(group: group),
    );
    if (!mounted) return;
    await provider.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestProvider>();
    final summary = provider.summary;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: AsyncStateView<List<GuestGroup>>(
        state: provider.groupsState,
        onRetry: provider.refresh,
        emptyTitle: 'هنوز مهمانی ثبت نشده',
        emptyMessage: 'با پرداخت میز و انتخاب گزینه‌ی «مهمان»، پذیرایی رایگان '
            'این‌جا ثبت می‌شود.',
        emptyIcon: Icons.card_giftcard_outlined,
        builder: (context, groups) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'مهمان‌ها',
                  subtitle: summary == null
                      ? 'پذیرایی رایگان'
                      : 'جمع مهمان‌نوازی: '
                          '${PersianFormat.money(summary.totalAmount)}'
                          ' • ${PersianFormat.digits(summary.guestCount)} ثبت',
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
                    hintText: 'جست‌وجوی نام مهمان',
                  ),
                  onChanged: provider.search,
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _tableMinWidth) {
                      return GuestsTable(
                        groups: groups,
                        onSelect: _openGroup,
                      );
                    }
                    return Column(
                      children: [
                        for (final g in groups)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: GuestGroupTile(
                              group: g,
                              onTap: () => _openGroup(g),
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
