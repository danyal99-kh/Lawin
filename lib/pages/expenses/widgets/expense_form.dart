import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/input_formatters.dart';
import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/enums.dart';
import '../../../models/expense.dart';
import '../../../providers/expense_provider.dart';

/// فرم ایجاد/ویرایش هزینه (داخل Dialog یا Bottom Sheet). با موفقیت `true` برمی‌گرداند.
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.expense});

  /// null یعنی هزینه‌ی جدید.
  final Expense? expense;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late ExpenseCategory _category;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(text: e == null ? '' : e.amount.toString());
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? ExpenseCategory.other;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _amountValue =>
      int.tryParse(TextUtils.latinDigits(_amount.text.trim()));

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<ExpenseProvider>().save(
          ExpenseDraft(
            title: _title.text,
            amount: _amountValue ?? 0,
            category: _category,
            note: _note.text,
          ),
          id: widget.expense?.id,
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
              Text(_isEdit ? 'ویرایش هزینه' : 'هزینه‌ی جدید',
                  style: theme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'عنوان هزینه'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'عنوان هزینه را وارد کنید.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('دسته‌بندی', style: theme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in ExpenseCategory.values)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: _category == c,
                      label: Text(c.label),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
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
                  labelText: 'مبلغ',
                  suffixText: 'تومان',
                  helperText: (amount == null || amount == 0)
                      ? null
                      : PersianFormat.money(amount),
                ),
                validator: (v) {
                  final n =
                      int.tryParse(TextUtils.latinDigits((v ?? '').trim()));
                  if (n == null || n <= 0) return 'مبلغ هزینه را وارد کنید.';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ذخیره'),
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
