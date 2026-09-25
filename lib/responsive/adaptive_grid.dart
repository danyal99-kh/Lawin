import 'package:flutter/widgets.dart';

/// شبکه‌ی واکنش‌گرا بدون عرض ثابت: تعداد ستون‌ها از روی «حداقل عرض هر آیتم» محاسبه می‌شود
/// و آیتم‌ها کل عرض را پر می‌کنند. چون بر پایه‌ی Wrap است، درون Scroll/Column بدون
/// مشکل ارتفاع نامحدود کار می‌کند (برخلاف GridView با shrinkWrap).
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 240,
    this.maxColumns = 6,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : minItemWidth;
        final columns = ((available + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, maxColumns)
            .toInt();
        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
