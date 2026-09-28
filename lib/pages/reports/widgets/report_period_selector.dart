import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/report.dart';
import '../../../providers/report_provider.dart';

/// انتخاب بازه‌ی گزارش؛ گزینه‌ی «بازه‌ی دلخواه» یک Date Range Picker باز می‌کند.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({super.key, required this.provider});

  final ReportProvider provider;

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange:
          (provider.customStart != null && provider.customEnd != null)
              ? DateTimeRange(
                  start: provider.customStart!, end: provider.customEnd!)
              : null,
    );
    if (picked != null) {
      await provider.setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = provider.period == ReportPeriod.custom;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final p
            in ReportPeriod.values.where((p) => p != ReportPeriod.custom))
          ChoiceChip(
            showCheckmark: false,
            selected: provider.period == p,
            label: Text(p.label),
            onSelected: (_) => provider.setPeriod(p),
          ),
        ChoiceChip(
          showCheckmark: false,
          selected: isCustom,
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text(
            isCustom &&
                    provider.customStart != null &&
                    provider.customEnd != null
                ? '${PersianFormat.date(provider.customStart!)} تا ${PersianFormat.date(provider.customEnd!)}'
                : ReportPeriod.custom.label,
          ),
          onSelected: (_) => _pickCustomRange(context),
        ),
      ],
    );
  }
}
