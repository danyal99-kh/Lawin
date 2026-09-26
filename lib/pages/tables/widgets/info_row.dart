import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_ranges.dart';
import '../../../core/utils/persian_format.dart';

/// اگر امروز است فقط ساعت، وگرنه تاریخ و ساعت.
String shortWhen(DateTime dt) => DateRanges.sameDay(dt, DateTime.now())
    ? PersianFormat.time(dt)
    : PersianFormat.dateTime(dt);

/// یک ردیف «آیکن + برچسب … مقدار» که با کمبود عرض، مقدار را کوچک می‌کند (بدون Overflow).
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required String value,
    TextStyle? valueStyle,
  })  : _value = value,
        _valueStyle = valueStyle,
        _child = null;

  const InfoRow.widget({
    super.key,
    required this.icon,
    required this.label,
    required Widget child,
  })  : _value = null,
        _valueStyle = null,
        _child = child;

  final IconData icon;
  final String label;
  final String? _value;
  final TextStyle? _valueStyle;
  final Widget? _child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: theme.bodySmall),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: _child ?? Text(_value ?? '', style: _valueStyle ?? theme.titleSmall),
            ),
          ),
        ],
      ),
    );
  }
}