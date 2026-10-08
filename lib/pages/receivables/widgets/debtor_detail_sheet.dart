import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../core/utils/view_state.dart';
import '../../../models/credit.dart';
import '../../../providers/credit_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/state_views.dart';
import '../../../widgets/status_chip.dart';

/// جزئیات یک بدهکار: نسیه‌هایش، وصول‌هایش و دکمه‌ی تسویه.
class DebtorDetailSheet extends StatefulWidget {
  const DebtorDetailSheet({super.key, this.onSettle});

  /// باز کردن فرم تسویه؛ صفحه‌ی اصلی این را می‌دهد چون Dialog را همان‌جا مدیریت می‌کند.
  final void Function(Debtor debtor)? onSettle;

  @override
  State<DebtorDetailSheet> createState() => _DebtorDetailSheetState();
}

class _DebtorDetailSheetState extends State<DebtorDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CreditProvider>();
      if (provider.creditsState.status == ViewStatus.initial) {
        provider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditProvider>();
    final theme = Theme.of(context).textTheme;

    Debtor? debtor;
    for (final d in provider.debtors) {
      if (d.id == provider.selectedId) {
        debtor = d;
        break;
      }
    }
    if (debtor == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: LoadingView(),
      );
    }
    final d = debtor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.name, style: theme.titleLarge),
              ),
              StatusChip(
                label: d.debt > 0
                    ? PersianFormat.money(d.debt)
                    : 'تسویه‌شده',
                tone: d.debt > 0 ? StatusTone.danger : StatusTone.success,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          if (d.phone != null || d.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              [
                if (d.phone != null) d.phone!,
                if (d.note != null) d.note!,
              ].join(' • '),
              style: theme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Metric(
                label: 'مانده‌ی طلب',
                value: PersianFormat.money(d.debt),
                color: d.debt > 0 ? AppColors.danger : AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _Metric(
                label: 'نسیه‌ی باز',
                value: PersianFormat.digits(d.openCredits),
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.md),
              _Metric(
                label: 'کل نسیه',
                value: PersianFormat.money(d.extended),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: d.debt > 0 && widget.onSettle != null
                ? () => widget.onSettle!(d)
                : null,
            icon: const Icon(Icons.payments_outlined, size: 20),
            label: const Text('ثبت تسویه'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('نسیه‌ها', style: theme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AsyncStateView<List<Credit>>(
            state: provider.creditsState,
            onRetry: () => context.read<CreditProvider>().selectDebtor(d.id),
            emptyTitle: 'نسیه‌ای ثبت نشده',
            emptyIcon: Icons.receipt_long_outlined,
            builder: (context, credits) => Column(
              children: [
                for (final c in credits) _CreditTile(credit: c),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('وصول‌ها', style: theme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AsyncStateView<List<CreditPayment>>(
            state: provider.paymentsState,
            onRetry: () => context.read<CreditProvider>().selectDebtor(d.id),
            emptyTitle: 'هنوز تسویه‌ای ثبت نشده',
            emptyIcon: Icons.history_outlined,
            builder: (context, payments) => Column(
              children: [
                for (final p in payments) _PaymentTile(payment: p),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.bodySmall, maxLines: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child:
                  Text(value, style: theme.titleSmall?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  const _CreditTile({required this.credit});

  final Credit credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سفارش ${PersianFormat.digits(credit.orderNumber)}',
                      style: theme.titleSmall),
                  Text(
                    '${PersianFormat.money(credit.amount)} • '
                    '${PersianFormat.dateTime(credit.createdAt)}',
                    style: theme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  credit.remainingAmount > 0
                      ? PersianFormat.money(credit.remainingAmount)
                      : PersianFormat.money(credit.amount),
                  style: theme.titleSmall?.copyWith(
                      color: credit.remainingAmount > 0
                          ? AppColors.danger
                          : AppColors.success),
                ),
                StatusChip(
                  label: credit.status.label,
                  tone: credit.status.isOpen
                      ? StatusTone.warning
                      : credit.status == CreditStatus.refunded
                          ? StatusTone.neutral
                          : StatusTone.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final CreditPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.arrow_downward,
                size: 18, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PersianFormat.money(payment.amount),
                      style: theme.titleSmall
                          ?.copyWith(color: AppColors.success)),
                  Text(
                    '${payment.account.label} • '
                    '${PersianFormat.dateTime(payment.createdAt)}'
                    '${payment.note == null ? '' : ' • ${payment.note!}'}',
                    style: theme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
