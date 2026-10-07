import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/security_gate_provider.dart';
import '../../widgets/app_card.dart';
import '../shell/app_destination.dart';

/// دروازه‌ی رمز امنیتی مقابل محتوای مالی.
///
/// اگر بخشِ [section] هنوز باز نشده باشد، به‌جای [child] صفحه‌ی رمز امنیتی
/// نشان داده می‌شود و فقط «ورود امنیتی» (که از Backend بلیت می‌گیرد) آن را
/// باز می‌کند.
class SecurityGate extends StatelessWidget {
  const SecurityGate({super.key, required this.section, required this.child});

  final SecuritySection section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gate = context.watch<SecurityGateProvider>();
    if (!gate.isLocked(section)) return child;
    return _SecurityPrompt(section: section);
  }
}

class _SecurityPrompt extends StatefulWidget {
  const _SecurityPrompt({required this.section});

  final SecuritySection section;

  @override
  State<_SecurityPrompt> createState() => _SecurityPromptState();
}

class _SecurityPromptState extends State<_SecurityPrompt> {
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _notConfigured = false;

  String get _sectionTitle => switch (widget.section) {
        SecuritySection.accounting => 'حسابداری و هزینه‌ها',
        SecuritySection.reports => 'گزارش‌ها',
      };

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _notConfigured = false;
    });
    final failure =
        await context.read<SecurityGateProvider>().unlock(widget.section, _password.text);
    if (!context.mounted) return;
    if (failure == null) return; // گیت با watch باز شد؛ باید به child برویم.
    setState(() {
      if (failure.type == FailureType.securityNotConfigured) {
        _notConfigured = true;
        _error = null;
      } else {
        _error = failure.type == FailureType.security
            ? 'رمز امنیتی صحیح نیست.'
            : failure.userMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<SecurityGateProvider>().busy;
    final theme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 22, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text('رمز امنیتی $_sectionTitle',
                                style: theme.titleSmall),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'برای دیدن این بخش، رمز امنیتی مشترک حسابداری را وارد کنید.',
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_notConfigured) ...[
                        const SizedBox(height: AppSpacing.md),
                        _ErrorBanner(
                          message:
                              'رمز امنیتی هنوز تنظیم نشده است. اول آن را از «تنظیمات› رمز امنیتی» تعیین کنید.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => context
                                .read<NavigationProvider>()
                                .select(AppDestination.settings),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('رفتن به تنظیمات'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          textDirection: TextDirection.ltr,
                          onSubmitted: (_) => busy ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: 'رمز امنیتی',
                            prefixIcon: const Icon(Icons.key_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _error!,
                            style: theme.bodySmall
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('ورود'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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