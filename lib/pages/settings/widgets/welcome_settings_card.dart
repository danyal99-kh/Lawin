import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_chip.dart';

/// کارت ویرایش پیام خوشامدگویی که در صفحه‌ی مشتری نمایش داده می‌شود.
///
/// مثل بقیه‌ی فرم‌های پروژه، وضعیت در حال ذخیره و پیام خطا را خودش نگه می‌دارد
/// و از Provider فقط نتیجه را می‌گیرد. چون بعد از ذخیره Provider همین Widget را
/// دوباره (نه از نو) می‌سازد، تایپ کاربر با به‌روزرسانی‌های بعدی از بین نمی‌رود.
class WelcomeSettingsCard extends StatefulWidget {
  const WelcomeSettingsCard({super.key, required this.welcome});

  final WelcomeSettings welcome;

  @override
  State<WelcomeSettingsCard> createState() => _WelcomeSettingsCardState();
}

class _WelcomeSettingsCardState extends State<WelcomeSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _message;
  late bool _enabled;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.welcome.title);
    _message = TextEditingController(text: widget.welcome.message);
    _enabled = widget.welcome.enabled;
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<SettingsProvider>().saveWelcome(
          WelcomeSettingsDraft(
            title: _title.text,
            message: _message.text,
            enabled: _enabled,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('پیام خوشامدگویی ذخیره شد.')));
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
            title: 'پیام خوشامدگویی',
            subtitle: 'متنی که مشتری بعد از اسکن QR در صفحه‌ی خوشامد می‌بیند.',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('متن خوشامدگویی', style: theme.titleSmall),
                    const Spacer(),
                    StatusChip(
                      label: _enabled ? 'فعال' : 'غیرفعال',
                      tone: _enabled ? StatusTone.success : StatusTone.neutral,
                      icon: _enabled
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'عنوان'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'عنوان خوشامدگویی را وارد کنید.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _message,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 400,
                  decoration: const InputDecoration(labelText: 'متن خوشامدگویی'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text('نمایش صفحه‌ی خوشامدگویی'),
                  subtitle: const Text(
                      'اگر غیرفعال شود، مشتری مستقیم وارد منو می‌شود.'),
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('ذخیره پیام خوشامدگویی'),
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
