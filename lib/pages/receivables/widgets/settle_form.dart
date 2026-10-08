import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/input_formatters.dart';
import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/credit.dart';
import '../../../models/enums.dart';
import '../../../providers/credit_provider.dart';

/// فرم تسویه‌ی نسیه (داخل Dialog/Bottom Sheet). با موفقیت `true` برمی‌گرداند.
///
/// فقط «مبلغ» از کاربر گرفته می‌شود؛ مانده و وضعیت را سرور محاسبه می‌کند.
/// پرداخت جزئی مجاز است و oldest-first بین نسیه‌های باز تقسیم می‌شود.
class SettleForm extends StatefulWidget {
  const SettleForm({
    super.key,
    required this.debtor,
    this.credit,
  });

  final Debtor debtor;

  /// اگر داده شود، فقط همین نسیه تسویه می‌شود؛ وگرنه کل مانده‌ی بدهکار.
  final Credit? credit;

  @override
  State<SettleForm> createState() => _SettleFormState();
}

class _SettleFormState extends State<SettleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late CashAccount _account;

  bool _saving = false;
  String? _error;

  /// کلید یکتای هر بار باز شدن فرم: اگر کلیک دوباره بخورد یا شب قطع شود،
  /// سرور همان تسویه را می‌شناسد و دوباره پول کم نمی‌کند.
  late final String _idempotencyKey;

  int get _total =>
      widget.credit?.remainingAmount ?? widget.debtor.debt;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
    _account = CashAccount.cash;
    _idempotencyKey =
        'adm-${DateTime.now().microsecondsSinceEpoch}-${widget.debtor.id}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _amountValue =>
      int.tryParse(TextUtils.latinDigits(_amount.text.trim()));

  void _fillAll() {
    _amount.text = '$_total';
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final failure = await context.read<CreditProvider>().settle(
          debtorId: widget.debtor.id,
          creditId: widget.credit?.id,
          amount: _amountValue ?? 0,
          account: _account,
          note: _note.text,
          idempotencyKey: _idempotencyKey,
        );

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
    final amount = _amountValue;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تسویه‌ی نسیه', style: theme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.credit == null
                    ? 'بدهکار: ${widget.debtor.name}'
                    : 'بدهکار: ${widget.debtor.name} • سفارش '
                        '${PersianFormat.digits(widget.credit!.orderNumber)}',
                style: theme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 20, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('مانده‌ی قابل وصول',
                          style: theme.bodyMedium),
                    ),
                    Text(PersianFormat.money(_total), style: theme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  LatinDigitsFormatter(),
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'مبلغ تسویه',
                  suffixText: 'تومان',
                  helperText: (amount == null || amount == 0)
                      ? null
                      : PersianFormat.money(amount),
                  suffixIcon: _total > 0
                      ? IconButton(
                          tooltip: 'پرداخت کل',
                          icon: const Icon(Icons.all_inclusive, size: 20),
                          onPressed: _fillAll,
                        )
                      : null,
                ),
                validator: (v) {
                  final n =
                      int.tryParse(TextUtils.latinDigits((v ?? '').trim()));
                  if (n == null || n <= 0) return 'مبلغ تسویه را وارد کنید.';
                  if (n > _total) {
                    return 'بیش از مانده‌ی طلب است (${PersianFormat.money(_total)}).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('پول به کدام حساب رسید؟', style: theme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final a in CashAccount.values)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: _account == a,
                      label: Text(a.label),
                      onSelected: (_) => setState(() => _account = a),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                maxLength: 200,
                decoration:
                    const InputDecoration(labelText: 'توضیحات (اختیاری)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_error!,
                            style: theme.bodyMedium
                                ?.copyWith(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('انصراف'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ثبت تسویه'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
