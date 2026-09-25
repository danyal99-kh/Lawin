import 'package:flutter/material.dart';

import '../core/errors/app_failure.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/view_state.dart';

/// حالت Loading
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      );
}

/// حالت Empty
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.title = 'موردی برای نمایش وجود ندارد',
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _CenteredMessage(
        icon: icon,
        iconColor: AppColors.neutral,
        title: title,
        message: message,
        action: action,
      );
}

/// حالت Error با دکمه‌ی «تلاش مجدد». فقط پیام فارسی کاربر نمایش داده می‌شود.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isNetwork = failure.type == FailureType.network ||
        failure.type == FailureType.timeout;
    return _CenteredMessage(
      icon: isNetwork ? Icons.cloud_off_outlined : Icons.error_outline,
      iconColor: AppColors.danger,
      title: isNetwork ? 'ارتباط برقرار نشد' : 'خطا',
      message: failure.userMessage,
      action: (onRetry != null && failure.isRetryable)
          ? OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            )
          : null,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(height: AppSpacing.md),
              Text(title,
                  style: theme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(message!,
                    style: theme.bodySmall, textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// نمایش خودکار Loading/Error/Empty/Success بر پایه‌ی ViewState.
/// همه‌ی صفحاتی که از Provider داده می‌گیرند از همین ویجت استفاده می‌کنند.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyTitle = 'موردی برای نمایش وجود ندارد',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  final ViewState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ViewStatus.initial:
        return const LoadingView();
      case ViewStatus.loading:
        final data = state.data;
        if (data == null) return const LoadingView();
        // داده‌ی قبلی را نگه می‌داریم و فقط نوار پیشرفت نشان می‌دهیم.
        return Stack(
          children: [
            builder(context, data),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ],
        );
      case ViewStatus.empty:
        return EmptyView(
            title: emptyTitle, message: emptyMessage, icon: emptyIcon);
      case ViewStatus.error:
        return ErrorView(
          failure: state.failure ?? AppFailure.unknown(),
          onRetry: onRetry,
        );
      case ViewStatus.success:
        return builder(context, state.data as T);
    }
  }
}
