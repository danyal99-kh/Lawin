// lib/pages/purchases/widgets/purchase_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/input_formatters.dart';
import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/inventory_item.dart';
import '../../../models/purchase.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/purchase_provider.dart';

/// فرم ثبت خرید کالای انبار (داخل Dialog یا Bottom Sheet). با موفقیت `true` برمی‌گرداند.
class PurchaseForm extends StatefulWidget {
  const PurchaseForm({super.key, required this.items});

  /// کالاهای قابل‌انتخاب؛ باید غیرخالی باشد.
  final List<InventoryItem> items;

  @override
  State<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _unitCost;
  late final TextEditingController _note;
  late InventoryItem _selected;

  bool _saving = false;
  String? _error;

  static final _numberFormatters = <TextInputFormatter>[LatinDigitsFormatter()];

  @override
  void initState() {
    super.initState();
    _selected = widget.items.first;
    _quantity = TextEditingController();
    _unitCost = TextEditingController(text: _trim(_selected.unitCost));
    _note = TextEditingController();
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
    _note.dispose();
    super.dispose();
  }

  double? _parse(String s) =>
      double.tryParse(TextUtils.latinDigits(s.trim()).replaceAll(',', ''));

  double? get _quantityValue => _parse(_quantity.text);
  double? get _unitCostValue => _parse(_unitCost.text);

  void _selectItem(InventoryItem item) {
    setState(() {
      _selected = item;
      _unitCost.text = _trim(item.unitCost);
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<PurchaseProvider>().record(
          PurchaseDraft(
            itemId: _selected.id,
            quantity: _quantityValue ?? 0,
            unitCost: _unitCostValue ?? 0,
            note: _note.text,
          ),
        );
    if (!mounted) return;
    if (failure == null) {
      // تازه‌سازی انبار تا موجودی و قیمت جدید در همه‌جا نمایش داده شود.
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
    final unitCost = _unitCostValue;
    final total =
        (quantity != null && unitCost != null) ? quantity * unitCost : null;

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
              Text('ثبت خرید', style: theme.titleLarge),
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
                      onSelected: (_) => _selectItem(i),
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
                  labelText: 'مقدار خرید',
                  suffixText: _selected.unit.label,
                  helperText:
                      quantity == null ? null : _selected.unit.format(quantity),
                ),
                validator: (v) {
                  final n = _parse(v ?? '');
                  if (n == null || n <= 0) return 'مقدار خرید را وارد کنید.';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _unitCost,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: _numberFormatters,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'قیمت خرید هر ${_selected.unit.label}',
                  suffixText: 'تومان',
                  helperText:
                      (unitCost == null) ? null : PersianFormat.money(unitCost),
                ),
                validator: (v) {
                  final n = _parse(v ?? '');
                  if (n == null || n < 0) return 'قیمت خرید معتبر نیست.';
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
              if (total != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Text('مبلغ کل خرید', style: theme.titleSmall),
                      const Spacer(),
                      Text(PersianFormat.money(total),
                          style: theme.titleMedium
                              ?.copyWith(color: AppColors.primaryDark)),
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
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ثبت خرید'),
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
