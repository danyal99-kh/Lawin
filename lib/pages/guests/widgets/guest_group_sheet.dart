import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/guest.dart';
import '../../../providers/guest_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/state_views.dart';
import '../../../widgets/status_chip.dart';

/// جزئیات یک گروه مهمان: همه‌ی ثبت‌های فعال آن نام، همراه تغییر نام و لغو.
///
/// صفحه‌ی اصلی پیش از باز کردن این شیت، `selectGroup` را صدا زده است؛ اینجا
/// فقط وضعیت را تماشا می‌کنیم تا با تغییر نام/لغو خودکار تازه شود.
class GuestGroupSheet extends StatelessWidget {
  const GuestGroupSheet({super.key, required this.group});

  final GuestGroup group;

  Future<void> _rename(BuildContext context, Guest guest) async {
    final controller = TextEditingController(text: guest.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغییر نام مهمان'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'نام مهمان',
            helperText:
                'مبلغ و سند دفتر دست‌نخورده می‌ماند؛ فقط گروه عوض می‌شود.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;
    final failure = await context.read<GuestProvider>().rename(guest.id, name);
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.userMessage)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('نام مهمان به «$name» تغییر کرد.')));
    }
  }

  Future<void> _cancel(BuildContext context, Guest guest) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لغو مهمان‌نوازی'),
        content: const Text(
            'این پذیرایی رایگان باطل می‌شود؛ موجودی مصرف‌شده به انبار برمی‌گردد '
            'و سفارش لغو می‌شود. این کار قابل برگشت نیست.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('لغو کن'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final failure = await context.read<GuestProvider>().cancel(guest.id);
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.userMessage)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('مهمان‌نوازی لغو شد.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestProvider>();
    final theme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(group.name, style: theme.titleLarge)),
              StatusChip(
                label: PersianFormat.money(group.totalAmount),
                tone: StatusTone.info,
                icon: Icons.card_giftcard_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'مجموع ${PersianFormat.digits(group.orderCount)} سفارش مهمان‌شده',
            style: theme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('ثبت‌ها', style: theme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AsyncStateView<List<Guest>>(
            state: provider.ordersState,
            onRetry: () =>
                context.read<GuestProvider>().selectGroup(group.name),
            emptyTitle: 'ثبت فعالی برای این نام نیست',
            emptyIcon: Icons.card_giftcard_outlined,
            builder: (context, guests) => Column(
              children: [
                for (final g in guests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GuestTile(
                      guest: g,
                      busy: provider.busy,
                      onRename: () => _rename(context, g),
                      onCancel: () => _cancel(context, g),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({
    required this.guest,
    required this.busy,
    required this.onRename,
    required this.onCancel,
  });

  final Guest guest;
  final bool busy;
  final VoidCallback onRename;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سفارش ${PersianFormat.digits(guest.orderNumber)}',
                        style: theme.titleSmall),
                    Text(
                      'میز ${PersianFormat.digits(guest.tableNumber)} • '
                      '${PersianFormat.dateTime(guest.createdAt)}',
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(PersianFormat.money(guest.amount),
                  style: theme.titleSmall?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: busy ? null : onRename,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('تغییر نام'),
              ),
              TextButton.icon(
                onPressed: busy ? null : onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('لغو مهمان‌نوازی'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
