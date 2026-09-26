// lib/pages/waste/widgets/waste_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/input_formatters.dart';
import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/inventory_item.dart';
import '../../../models/waste.dart';
import '../../../models/waste_reason.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/waste_provider.dart';

/// فرم ثبت ضایعات کالای انبار (داخل Dialog یا Bottom Sheet). با موفقیت `true` برمی‌گرداند.
class WasteForm extends StatefulWidget {
  const WasteForm({super.key, required this.items});

  /// کالاهای قابل‌انتخاب (فقط کالاهایی که موجودی دارند)؛ باید غیرخالی باشد.
  final List<InventoryItem> items;

  @override
  State<WasteForm> createState() => _WasteFormState();
}

class _WasteFormState extends State<WasteForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _note;
  late InventoryItem _selected;
  WasteReason _reason = WasteReason.expired;

  bool _saving = false;
  String? _error;

  static final _numberFormatters = <TextInputFormatter>[LatinDigitsFormatter()];

  @override
  void initState() {
    super.initState();
    _selected = widget.items.first;
    _quantity = TextEditingController();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  double? _parse(String s) =>
      double.tryParse(TextUtils.latinDigits(s.trim()).replaceAll(',', ''));

  double? get _quantityValue => _parse(_quantity.text);

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<WasteProvider>().record(
          WasteDraft(
            itemId: _selected.id,
            quantity: _quantityValue ?? 0,
            reason: _reason,
            note: _note.text,
          ),
        );
    if (!mounted) return;
    if (failure == null) {
      // تازه‌سازی انبار تا موجودی جدید در همه‌جا نمایش داده شود.
      await context.read<InventoryProvider>().load();
      if (!mounted) return;
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
    final quantity = _quantityValue;
    final estimatedCost =
        quantity == null ? null : quantity * _selected.unitCost;

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
              Text('ثبت ضایعات', style: theme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Text('کالا', style: theme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final i in widget.items)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: _selected.id == i.id,
                      label: Text(i.name),
                      onSelected: (_) => setState(() => _selected = i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'موجودی فعلی: ${_selected.unit.format(_selected.currentStock)}',
                style: theme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('دلیل', style: theme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final r in WasteReason.values)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: _reason == r,
                      label: Text(r.label),
                      onSelected: (_) => setState(() => _reason = r),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _quantity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: _numberFormatters,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'مقدار ضایعات',
                  suffixText: _selected.unit.label,
                  helperText:
                      quantity == null ? null : _selected.unit.format(quantity),
                ),
                validator: (v) {
                  final n = _parse(v ?? '');
                  if (n == null || n <= 0) return 'مقدار ضایعات را وارد کنید.';
                  if (n > _selected.currentStock) {
                    return 'بیشتر از موجودی فعلی است.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                maxLength: 200,
                decoration:
                    const InputDecoration(labelText: 'توضیحات (اختیاری)'),
              ),
              if (estimatedCost != null && estimatedCost > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Text('ارزش تقریبی ضایعات', style: theme.titleSmall),
                      const Spacer(),
                      Text(PersianFormat.money(estimatedCost),
                          style: theme.titleMedium
                              ?.copyWith(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
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
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ثبت ضایعات'),
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
