// lib/pages/tables/widgets/payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/enums.dart';
import '../../../providers/table_provider.dart';

/// انتخاب روش پرداخت و ثبت پرداخت صورتحساب میز. با موفقیت `true` برمی‌گرداند.
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({
    super.key,
    required this.tableId,
    required this.amount,
  });

  final int tableId;
  final int amount;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure =
        await context.read<TableProvider>().pay(widget.tableId, _method);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('ثبت پرداخت'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('مبلغ قابل پرداخت', style: theme.titleSmall),
                const Spacer(),
                Text(PersianFormat.money(widget.amount),
                    style:
                        theme.titleMedium?.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('روش پرداخت', style: theme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final m in PaymentMethod.values)
                  ChoiceChip(
                    showCheckmark: false,
                    selected: _method == m,
                    label: Text(m.label),
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: theme.bodySmall?.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _saving ? null : _confirm,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('ثبت پرداخت'),
        ),
      ],
    );
  }
}
