import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/widgets/panel_card.dart';
import 'package:cafe_book_admin/widgets/state_views.dart';
import 'package:cafe_book_admin/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../providers/waiter_call_provider.dart';

/// پنل درخواست‌های گارسون در داشبورد: همه‌ی درخواست‌های فعال با دکمه‌های «دیدم» و «انجام شد».
/// خودش Provider را می‌خواند تا با هر تغییر وضعیت دوباره ساخته شود.
class WaiterCallsPanel extends StatelessWidget {
  const WaiterCallsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaiterCallProvider>();
    final theme = Theme.of(context).textTheme;
    final calls = provider.calls;

    return PanelCard(
      title: 'درخواست‌های گارسون',
      icon: Icons.pan_tool_alt_outlined,
      action: provider.pendingCount > 0
          ? StatusChip(
              label: '${PersianFormat.digits(provider.pendingCount)} در انتظار',
              tone: StatusTone.warning,
              icon: Icons.notifications_active_outlined,
            )
          : null,
      child: calls.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyView(
                title: 'درخواست فعالی وجود ندارد',
                icon: Icons.pan_tool_alt_outlined,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < calls.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'میز ${PersianFormat.digits(calls[i].tableNumber)}',
                                  style: theme.titleSmall),
                              Text(
                                '${calls[i].status.label} • ${PersianFormat.duration(calls[i].age)} پیش',
                                style: theme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (calls[i].isPending)
                          TextButton(
                            onPressed: provider.isBusy(calls[i].id)
                                ? null
                                : () => _run(context,
                                    () => provider.acknowledge(calls[i].id)),
                            child: const Text('دیدم'),
                          ),
                        TextButton(
                          onPressed: provider.isBusy(calls[i].id)
                              ? null
                              : () => _run(context,
                                  () => provider.complete(calls[i].id)),
                          child: const Text('انجام شد'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// اجرای اقدام گارسون؛ فقط خطا به کاربر نشان داده می‌شود.
  Future<void> _run(
    BuildContext context,
    Future<AppFailure?> Function() action,
  ) async {
    final failure = await action();
    if (failure == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure.userMessage)));
  }
}
