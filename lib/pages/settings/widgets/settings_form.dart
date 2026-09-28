import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';

/// فرم ویرایش تنظیمات. مقدار اولیه از [settings] گرفته می‌شود؛ چون بعد از
/// ذخیره Provider همین Widget را دوباره (نه از نو) می‌سازد، مقادیر تایپ‌شده‌ی
/// کاربر با به‌روزرسانی‌های بعدی Provider از بین نمی‌رود.
class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cafeName;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _footerNote;
  late bool _autoPrintBarOrders;
  late bool _lowStockAlertEnabled;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _cafeName = TextEditingController(text: s.cafeName);
    _address = TextEditingController(text: s.address ?? '');
    _phone = TextEditingController(text: s.phone ?? '');
    _footerNote = TextEditingController(text: s.receiptFooterNote ?? '');
    _autoPrintBarOrders = s.autoPrintBarOrders;
    _lowStockAlertEnabled = s.lowStockAlertEnabled;
  }

  @override
  void dispose() {
    _cafeName.dispose();
    _address.dispose();
    _phone.dispose();
    _footerNote.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<SettingsProvider>().save(
          AppSettingsDraft(
            cafeName: _cafeName.text,
            address: _address.text,
            phone: _phone.text,
            receiptFooterNote: _footerNote.text,
            autoPrintBarOrders: _autoPrintBarOrders,
            lowStockAlertEnabled: _lowStockAlertEnabled,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تنظیمات ذخیره شد.')));
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'تنظیمات',
            subtitle: 'اطلاعات کافه و رفتار پیش‌فرض سیستم.',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('اطلاعات کافه', style: theme.titleSmall),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _cafeName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'نام کافه'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'نام کافه را وارد کنید.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _address,
                  minLines: 2,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'آدرس (اختیاری)'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  ],
                  decoration:
                      const InputDecoration(labelText: 'شماره تماس (اختیاری)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('چاپ و رسید', style: theme.titleSmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoPrintBarOrders,
                  onChanged: (v) => setState(() => _autoPrintBarOrders = v),
                  title: const Text('چاپ خودکار سفارش بار'),
                  subtitle: const Text(
                      'با ثبت سفارش جدید، بلافاصله برای بار ارسال شود.'),
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _footerNote,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                      labelText: 'یادداشت پایین رسید (اختیاری)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('هشدارها', style: theme.titleSmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _lowStockAlertEnabled,
                  onChanged: (v) => setState(() => _lowStockAlertEnabled = v),
                  title: const Text('هشدار موجودی کم در داشبورد'),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('ذخیره تنظیمات'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text('${AppConstants.appName} — نسخه ۰٫۱٫۰',
                style: theme.bodySmall),
          ),
        ],
      ),
    );
  }
}
