import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/input_formatters.dart';
import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/inventory_item.dart';
import '../../../models/product.dart';
import '../../../models/recipe.dart';
import '../../../providers/recipe_provider.dart';

/// فرم تعریف/ویرایش دستور مصرف یک محصول: انتخاب کالاهای انبار و مقدار مصرفی هرکدام.
class RecipeForm extends StatefulWidget {
  const RecipeForm({
    super.key,
    required this.product,
    required this.recipe,
    required this.inventoryItems,
  });

  final Product product;
  final Recipe? recipe;
  final List<InventoryItem> inventoryItems;

  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RowState {
  _RowState(this.item, double quantity)
      : controller = TextEditingController(
            text: quantity == 0
                ? ''
                : PersianFormat.number(quantity, decimals: 2));

  final InventoryItem item;
  final TextEditingController controller;

  double? get quantity => double.tryParse(
      TextUtils.latinDigits(controller.text.trim()).replaceAll('٫', '.'));
}

class _RecipeFormState extends State<RecipeForm> {
  late List<_RowState> _rows;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final byId = {for (final i in widget.inventoryItems) i.id: i};
    _rows = [
      for (final ri in widget.recipe?.items ?? const [])
        if (byId[ri.inventoryItemId] != null)
          _RowState(byId[ri.inventoryItemId]!, ri.quantity),
    ];
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  List<InventoryItem> get _available => widget.inventoryItems
      .where((i) => !_rows.any((r) => r.item.id == i.id))
      .toList();

  Future<void> _addRow() async {
    final picked = await showModalBottomSheet<InventoryItem>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('انتخاب کالای انبار',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (_available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text('همه‌ی کالاهای انبار قبلاً اضافه شده‌اند.'),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final i in _available)
                      ActionChip(
                        label: Text(i.name),
                        onPressed: () => Navigator.of(ctx).pop(i),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _rows.add(_RowState(picked, 0)));
  }

  Future<void> _save() async {
    final items = <RecipeItem>[];
    for (final r in _rows) {
      final q = r.quantity;
      if (q == null || q <= 0) {
        setState(
            () => _error = 'مقدار مصرفی «${r.item.name}» را درست وارد کنید.');
        return;
      }
      items.add(RecipeItem(
        inventoryItemId: r.item.id,
        inventoryItemName: r.item.name,
        unit: r.item.unit,
        quantity: q,
      ));
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure =
        await context.read<RecipeProvider>().save(widget.product.id, items);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('دستور مصرف «${widget.product.name}»',
                style: theme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            if (_rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'هنوز کالایی اضافه نشده. با دکمه‌ی زیر مواد مصرفی این محصول را اضافه کنید.',
                  style: theme.bodySmall,
                ),
              )
            else
              for (final r in _rows)
                _RecipeRowTile(
                    row: r, onRemove: () => setState(() => _rows.remove(r))),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _saving ? null : _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('افزودن ماده مصرفی'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
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
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
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
    );
  }
}

class _RecipeRowTile extends StatelessWidget {
  const _RecipeRowTile({required this.row, required this.onRemove});

  final _RowState row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(row.item.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [LatinDigitsFormatter()],
              decoration: InputDecoration(
                labelText: 'مقدار',
                suffixText: row.item.unit.label,
              ),
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.close, color: AppColors.danger),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
