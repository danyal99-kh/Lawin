import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/security_gate_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';

/// کارت «رمز امنیتی» در تنظیمات: تعیین رمز برای اولین بار یا تغییر آن.
///
/// شفاف‌سازی‌ها:
/// - رمز روی دستگاه ذخیره نمی‌شود؛ Backend (PBKDF2) مرجع ذخیره و بررسی است.
/// - بلیت‌های مالیِ قبلی بعد از تغییر رمز بی‌اعتبار می‌شوند و در بخش‌های مالی
///   دوباره رمز خواسته می‌شود.
class SecuritySettingsCard extends StatefulWidget {
  const SecuritySettingsCard({super.key});

  @override
  State<SecuritySettingsCard> createState() => _SecuritySettingsCardState();
}

class _SecuritySettingsCardState extends State<SecuritySettingsCard> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<SecurityGateProvider>().changePassword(
          currentPassword: _current.text,
          newPassword: _new.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      _new.clear();
      _confirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز امنیتی ذخیره شد.')));
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  String? _validateNew(String? value) {
    final v = value ?? '';
    if (v.length < 6) {
      return 'رمز امنیتی باید حداقل ۶ کاراکتر باشد.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _new.text) {
      return 'تکرار رمز با رمز جدید یکسان نیست.';
    }
    return null;
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
            title: 'رمز امنیتی',
            subtitle: 'رمز مشترک ورود به حسابداری، هزینه‌ها و گزارش‌ها.',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رمز فعلی',
                    helperText: 'اگر برای اولین بار است، خالی بگذارید.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _new,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'رمز جدید'),
                  validator: _validateNew,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  onFieldSubmitted: (_) => _saving ? null : _save(),
                  decoration: const InputDecoration(labelText: 'تکرار رمز جدید'),
                  validator: _validateConfirm,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'این رمز فقط سمت سرور به‌صورت هش‌شده نگه‌داری می‌شود؛ '
                  'تغییر آن ورود امنیتیِ قبلی در بخش‌های مالی را می‌بندد.',
                  style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ErrorBanner(message: _error!),
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('ذخیره رمز امنیتی'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}