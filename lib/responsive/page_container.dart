import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// محتوای صفحه را وسط‌چین، با حداکثر عرض و Padding متناسب با اندازه‌ی صفحه نمایش می‌دهد.
class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final padding = Breakpoints.pagePaddingFor(context.screenType);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: maxWidth ?? Breakpoints.contentMaxWidth),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}
