import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/waiter_call.dart';
import '../../../widgets/status_chip.dart';
import '../../../widgets/status_tones.dart';

/// نوار وضعیت درخواست گارسون روی کارت میز.
/// [onAcknowledge] رویداد «دیدم» و [onComplete] رویداد «انجام شد» را می‌فرستد؛
/// اگر null باشد فقط نمایش داده می‌شود (بدون دکمه).
class WaiterCallBanner extends StatelessWidget {
  const WaiterCallBanner({
    super.key,
    required this.call,
    this.onAcknowledge,
    this.onComplete,
    this.busy = false,
  });

  final WaiterCall call;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onComplete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final tone = call.status.tone;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.pan_tool_alt_outlined,
                  size: 18, color: tone.foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.isPending
                          ? 'درخواست گارسون • ${PersianFormat.duration(call.age)} پیش'
                          : 'گارسون در راه میز ${PersianFormat.digits(call.tableNumber)} است',
                      style: theme.titleSmall?.copyWith(color: tone.foreground),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // هنگام ارسال درخواست به سرور، دکمه‌ها قفل و loading کوچک نشان داده می‌شود.
              if (busy) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              StatusChip(label: call.status.label, tone: tone),
            ],
          ),
          if (call.isPending &&
              onAcknowledge != null &&
              onComplete != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onAcknowledge,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('دیدم'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onComplete,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('انجام شد'),
                  ),
                ),
              ],
            ),
          ] else if (onComplete != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: busy ? null : onComplete,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('انجام شد'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
