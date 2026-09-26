import 'package:cafe_book_admin/core/network/utils/input_formatters.dart';
import 'package:cafe_book_admin/core/network/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/product.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../services/image_picker_service.dart';
import '../../../widgets/product_image.dart';

/// فرم ایجاد/ویرایش محصول (داخل Dialog یا Bottom Sheet). با موفقیت `true` برمی‌گرداند.
class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.product});

  /// null یعنی محصول جدید.
  final Product? product;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _image;
  int? _categoryId;
  late bool _isActive;

  bool _saving = false;
  String? _error;
  String? _categoryError;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toString());
    _description = TextEditingController(text: p?.description ?? '');
    _image = TextEditingController(text: p?.imageUrl ?? '');
    _categoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _image.dispose();
    super.dispose();
  }

  int? get _priceValue =>
      int.tryParse(TextUtils.latinDigits(_price.text.trim()));

  Future<void> _pickImage() async {
    try {
      final path = await context.read<ImagePickerService>().pickImagePath();
      if (path != null && mounted) setState(() => _image.text = path);
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = f.userMessage);
    }
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_categoryId == null) {
      setState(() => _categoryError = 'دسته‌بندی را انتخاب کنید.');
      return;
    }
    if (!valid) return;

    setState(() {
      _saving = true;
      _error = null;
      _categoryError = null;
    });
    final failure = await context.read<ProductProvider>().save(
          ProductDraft(
            name: _name.text,
            categoryId: _categoryId!,
            price: _priceValue ?? 0,
            description: _description.text,
            imageUrl: _image.text,
            isActive: _isActive,
          ),
          id: widget.product?.id,
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
    final categories = context.watch<CategoryProvider>().categories;
    final price = _priceValue;

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
              Text(_isEdit ? 'ویرایش محصول' : 'محصول جدید',
                  style: theme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'نام محصول'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'نام محصول را وارد کنید.' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('دسته‌بندی', style: theme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              if (categories.isEmpty)
                Text('ابتدا از بخش «دسته‌بندی‌ها» یک دسته بسازید.',
                    style: theme.bodySmall?.copyWith(color: AppColors.danger))
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in categories)
                      ChoiceChip(
                        showCheckmark: false,
                        selected: _categoryId == c.id,
                        label: Text(c.name),
                        onSelected: (_) => setState(() {
                          _categoryId = c.id;
                          _categoryError = null;
                        }),
                      ),
                  ],
                ),
              if (_categoryError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(_categoryError!,
                      style:
                          theme.bodySmall?.copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  LatinDigitsFormatter(),
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'قیمت فروش',
                  suffixText: 'تومان',
                  helperText:
                      (price == null || price == 0) ? null : PersianFormat.money(price),
                ),
                validator: (v) {
                  final n = int.tryParse(TextUtils.latinDigits((v ?? '').trim()));
                  if (n == null || n <= 0) return 'قیمت فروش را وارد کنید.';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration:
                    const InputDecoration(labelText: 'توضیحات (اختیاری)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(imageUrl: _image.text, size: 72),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _image,
                          textDirection: TextDirection.ltr,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'آدرس یا مسیر تصویر (اختیاری)'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _saving ? null : _pickImage,
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('انتخاب از دستگاه'),
                            ),
                            if (_image.text.trim().isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _image.clear()),
                                child: const Text('حذف تصویر'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('فعال (قابل سفارش)'),
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