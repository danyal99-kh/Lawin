import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../core/utils/view_state.dart';
import '../../../models/cafe_status.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cafe_status_provider.dart';
import '../../../widgets/panel_card.dart';
import '../../../widgets/status_chip.dart';

/// بخش «وضعیت کافه» در بالای داشبورد (جایگزین کارت‌های فروش/هزینه/سود).
///
/// وضعیت باز/بسته را از Backend می‌گیرد و تغییر آن را هم از همین‌جا و از طریق
/// API انجام می‌دهد؛ هیچ تصمیم یا محاسبه‌ای در Flutter گرفته نمی‌شود.
class CafeStatusCard extends StatelessWidget {
  const CafeStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CafeStatusProvider>();
    final state = provider.state;

    return PanelCard(
      title: 'وضعیت کافه',
      icon: Icons.local_cafe_outlined,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _body(context, provider, state),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CafeStatusProvider provider,
    ViewState<CafeStatus> state,
  ) {
    // خطا همیشه دیده می‌شود (حتی اگر داده‌ی قبلی هنوز در حافظه باشد) تا
    // کاربر بداند چیزی تازه نشده و بتواند دوباره تلاش کند.
    if (state.status == ViewStatus.error) {
      return _ErrorBody(
        failure: state.failure,
        onRetry: provider.load,
      );
    }
    final status = state.data;
    if (status == null) return const _LoadingBody();
    return _StatusBody(
      status: status,
      saving: provider.saving,
      onOpen: () => _toggle(
        context,
        provider.open,
        'کافه با موفقیت باز شد',
      ),
      onClose: () => _closeCafe(context, provider),
    );
  }

  /// نتیجه‌ی باز/بسته کردن را به کاربر اعلام می‌کند. خطا یعنی وضعیت عوض
  /// نشده؛ پس UI (که از Provider می‌خواند) خودش به حالت قبلی برگشته است.
  Future<void> _toggle(
    BuildContext context,
    Future<AppFailure?> Function() action,
    String successMessage,
  ) async {
    final failure = await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        failure == null ? successMessage : 'تغییر وضعیت کافه انجام نشد',
      ),
    ));
  }

  /// بستن کافه = پایانِ شیفت: اول تأیید می‌گیرد، بعد کافه بسته می‌شود و در
  /// موفقیت، **خروج کامل** انجام می‌شود (توکن هم سمت سرور باطل شده؛ پس
  /// برنامه به صفحه‌ی ورود برمی‌گردد). خطا فقط به‌صورت SnackBar اعلام می‌شود
  /// و نشست باز می‌ماند.
  Future<void> _closeCafe(BuildContext context, CafeStatusProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بستن کافه'),
        content: const Text(
            'با بستن کافه، پایانِ شیفت ثبت می‌شود و برنامه از حساب خارج می‌شود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('بستن کافه'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final failure = await provider.close();
    if (!context.mounted) return;
    if (failure == null) {
      // بستن موفق کافه یعنی پایان شیفت: خروج کامل از حساب. توکن سمت سرور هم
      // در همین بستن باطل شده؛ پس برنامه به صفحه‌ی ورود برمی‌گردد.
      await context.read<AuthProvider>().logout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تغییر وضعیت کافه انجام نشد')),
      );
    }
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.status,
    required this.saving,
    required this.onOpen,
    required this.onClose,
  });

  final CafeStatus status;
  final bool saving;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final tone = status.isOpen ? StatusTone.success : StatusTone.neutral;

    String? label;
    String? value;
    if (status.isOpen) {
      if (status.openedAt != null) {
        label = 'شروع فعالیت';
        value = PersianFormat.time(status.openedAt!);
      }
    } else if (status.closedAt != null) {
      label = 'آخرین فعالیت';
      value = PersianFormat.time(status.closedAt!);
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.isOpen ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: tone.foreground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  status.isOpen ? 'کافه فعال است' : 'کافه بسته است',
                  style: theme.titleSmall?.copyWith(color: tone.foreground),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (label != null) ...[
              Text(label, style: theme.bodySmall),
              Text(value!, style: theme.titleMedium),
            ] else
              Text('هنوز فعالیتی ثبت نشده', style: theme.bodySmall),
          ],
        ),
        if (status.isOpen)
          OutlinedButton.icon(
            onPressed: saving ? null : onClose,
            icon: saving
                ? _spinner(AppColors.primary)
                : const Icon(Icons.lock_outline, size: 18),
            label: const Text('بستن کافه'),
          )
        else
          FilledButton.icon(
            onPressed: saving ? null : onOpen,
            icon: saving
                ? _spinner(AppColors.onPrimary)
                : const Icon(Icons.lock_open_outlined, size: 18),
            label: const Text('باز کردن کافه'),
          ),
      ],
    );
  }

  static Widget _spinner(Color color) => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => SizedBox(
        // ارتفاع ثابت تا کارت هنگام بارگذاری از اندازه نیفتد.
        height: 56,
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'در حال دریافت وضعیت کافه…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure, required this.onRetry});

  final AppFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            failure?.userMessage ?? 'وضعیت کافه دریافت نشد.',
            style: theme.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: onRetry,
          child: const Text('تلاش مجدد'),
        ),
      ],
    );
  }
}
