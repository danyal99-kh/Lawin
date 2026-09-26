// lib/pages/inventory/widgets/inventory_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/input_formatters.dart';
import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/enums.dart';
import '../../../models/inventory_draft.dart';
import '../../../models/inventory_item.dart';
import '../../../providers/inventory_provider.dart';

/// فرم ایجاد/ویرایش کالای انبار (داخل Dialog یا Bottom Sheet). با موفقیت `true` برمی‌گرداند.
/// واحد پایه فقط هنگام ایجاد قابل انتخاب است؛ چون موجودی فعلی بر همان واحد ثبت شده.
class InventoryForm extends StatefulWidget {
  const InventoryForm({super.key, this.item});

  /// null یعنی کالای جدید.
  final InventoryItem? item;

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _minStock;
  late final TextEditingController _unitCost;
  late final TextEditingController _initialStock;
  late final TextEditingController _description;
  late BaseUnit _unit;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.item != null;

  static final _numberFormatters = <TextInputFormatter>[LatinDigitsFormatter()];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _minStock = TextEditingController(text: i == null ? '' : _trim(i.minStock));
    _unitCost = TextEditingController(text: i == null ? '' : _trim(i.unitCost));
    _initialStock = TextEditingController();
    _description = TextEditingController(text: i?.description ?? '');
    _unit = i?.unit ?? BaseUnit.gram;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _minStock.dispose();
    _unitCost.dispose();
    _initialStock.dispose();
    _description.dispose();
    super.dispose();
  }

  double? _parse(String s) =>
      double.tryParse(TextUtils.latinDigits(s.trim()).replaceAll(',', ''));

  double? get _minStockValue => _parse(_minStock.text);
  double? get _unitCostValue => _parse(_unitCost.text);
  double? get _initialStockValue => _parse(_initialStock.text);

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<InventoryProvider>().save(
          InventoryItemDraft(
            name: _name.text,
            unit: _unit,
            minStock: _minStockValue ?? 0,
            unitCost: _unitCostValue ?? 0,
            description: _description.text,
            initialStock: _isEdit ? 0 : (_initialStockValue ?? 0),
          ),
          id: widget.item?.id,
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
    final minStock = _minStockValue;
    final unitCost = _unitCostValue;
    final initialStock = _initialStockValue;

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
              Text(_isEdit ? 'ویرایش کالا' : 'کالای جدید',
                  style: theme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'نام کالا'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نام کالا را وارد کنید.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('واحد پایه', style: theme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final u in BaseUnit.values)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: _unit == u,
                      label: Text(u.label),
                      onSelected:
                          _isEdit ? null : (_) => setState(() => _unit = u),
                    ),
                ],
              ),
              if (_isEdit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('واحد پایه بعد از ثبت قابل تغییر نیست.',
                      style: theme.bodySmall),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _minStock,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: _numberFormatters,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'حداقل موجودی',
                  suffixText: _unit.label,
                  helperText: minStock == null ? null : _unit.format(minStock),
                ),
                validator: (v) {
                  final n = _parse(v ?? '');
                  if (n == null || n < 0) return 'حداقل موجودی معتبر نیست.';
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
                  labelText: 'قیمت خرید هر ${_unit.label}',
                  suffixText: 'تومان',
                  helperText: (unitCost == null || unitCost == 0)
                      ? null
                      : PersianFormat.money(unitCost),
                ),
                validator: (v) {
                  final n = _parse(v ?? '');
                  if (n == null || n < 0) return 'قیمت خرید معتبر نیست.';
                  return null;
                },
              ),
              if (!_isEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _initialStock,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: _numberFormatters,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'موجودی اولیه (اختیاری)',
                    suffixText: _unit.label,
                    helperText: (initialStock == null || initialStock == 0)
                        ? null
                        : _unit.format(initialStock),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = _parse(v);
                    if (n == null || n < 0) return 'موجودی اولیه معتبر نیست.';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _description,
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
