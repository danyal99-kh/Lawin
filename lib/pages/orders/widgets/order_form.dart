import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/utils/text_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/product.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/table_provider.dart';
import '../../../repositories/order_repository.dart';

Product? _productById(List<Product> products, int id) {
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
}

/// فرم ثبت سفارش جدید برای یک میز (داخل Dialog یا Bottom Sheet). با موفقیت `true` برمی‌گرداند.
class OrderForm extends StatefulWidget {
  const OrderForm({super.key, this.initialTableId});

  /// اگر از میز مشخصی باز شود، از پیش انتخاب می‌شود.
  final int? initialTableId;

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _search = TextEditingController();
  final _note = TextEditingController();
  final Map<int, int> _cart = {}; // productId -> quantity

  int? _tableId;
  bool _saving = false;
  String? _error;
  String? _tableError;

  @override
  void initState() {
    super.initState();
    _tableId = widget.initialTableId;
  }

  @override
  void dispose() {
    _search.dispose();
    _note.dispose();
    super.dispose();
  }

  void _addProduct(Product p) {
    setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1);
  }

  void _changeQuantity(int productId, int delta) {
    setState(() {
      final next = (_cart[productId] ?? 0) + delta;
      if (next <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = next;
      }
    });
  }

  Future<void> _save() async {
    if (_tableId == null) {
      setState(() => _tableError = 'یک میز انتخاب کنید.');
      return;
    }
    if (_cart.isEmpty) {
      setState(() => _error = 'حداقل یک آیتم را اضافه کنید.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _tableError = null;
    });
    final items = [
      for (final entry in _cart.entries)
        OrderItemDraft(productId: entry.key, quantity: entry.value),
    ];
    final note = _note.text.trim();
    final failure = await context.read<OrderProvider>().create(OrderDraft(
          tableId: _tableId!,
          items: items,
          customerNote: note.isEmpty ? null : note,
        ));
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
    final tables = context.watch<TableProvider>().all;
    final products =
        context.watch<ProductProvider>().all.where((p) => p.isActive).toList();
    final query = TextUtils.normalizeFa(_search.text);
    final filtered = query.isEmpty
        ? products
        : products
            .where((p) => TextUtils.normalizeFa(p.name).contains(query))
            .toList();
    final cartTotal = _cart.entries.fold<int>(0, (sum, e) {
      final p = _productById(products, e.key);
      return sum + (p?.price ?? 0) * e.value;
    });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سفارش جدید', style: theme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text('میز', style: theme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            if (tables.isEmpty)
              Text('میزی یافت نشد.', style: theme.bodySmall)
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final t in tables)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: _tableId == t.table.id,
                      label: Text(
                          'میز ${PersianFormat.digits(t.table.number)} • ${t.table.status.label}'),
                      onSelected: (_) => setState(() {
                        _tableId = t.table.id;
                        _tableError = null;
                      }),
                    ),
                ],
              ),
            if (_tableError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(_tableError!,
                    style: theme.bodySmall?.copyWith(color: AppColors.danger)),
              ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'جستجوی محصول…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('محصولی پیدا نشد.', style: theme.bodySmall),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      subtitle: Text(PersianFormat.money(p.price)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _addProduct(p),
                      ),
                      onTap: () => _addProduct(p),
                    );
                  },
                ),
              ),
            const Divider(height: AppSpacing.xl),
            Text('سبد سفارش', style: theme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (_cart.isEmpty)
              Text('هنوز آیتمی اضافه نشده.', style: theme.bodySmall)
            else
              for (final entry in _cart.entries)
                _CartLineRow(
                  product: _productById(products, entry.key),
                  quantity: entry.value,
                  onIncrement: () => _changeQuantity(entry.key, 1),
                  onDecrement: () => _changeQuantity(entry.key, -1),
                ),
            if (_cart.isNotEmpty) ...[
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  Text('جمع کل', style: theme.titleSmall),
                  const Spacer(),
                  Text(PersianFormat.money(cartTotal),
                      style: theme.titleMedium
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              maxLength: 200,
              decoration:
                  const InputDecoration(labelText: 'یادداشت سفارش (اختیاری)'),
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
                        : const Text('ثبت سفارش'),
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

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product? product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final lineTotal = (product?.price ?? 0) * quantity;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(product?.name ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onDecrement,
          ),
          Text(PersianFormat.digits(quantity), style: theme.titleSmall),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onIncrement,
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: Text(PersianFormat.money(lineTotal),
                textAlign: TextAlign.end, style: theme.bodySmall),
          ),
        ],
      ),
    );
  }
}
