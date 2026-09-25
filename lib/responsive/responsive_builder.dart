import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Builder بر پایه‌ی LayoutBuilder: نوع صفحه‌نمایش را از «عرض در دسترس همین ویجت» می‌سنجد،
/// نه از کل پنجره؛ بنابراین داخل پنل‌ها و ستون‌ها هم درست کار می‌کند.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(
      BuildContext context, ScreenType type, BoxConstraints constraints) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return builder(context, Breakpoints.typeFor(width), constraints);
        },
      );
}

/// انتخاب ساده‌ی ویجت بر اساس نوع صفحه‌نمایش.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
        builder: (context, type, _) => switch (type) {
          ScreenType.mobile => mobile,
          ScreenType.tablet => tablet ?? mobile,
          ScreenType.desktop => desktop ?? tablet ?? mobile,
        },
      );
}
