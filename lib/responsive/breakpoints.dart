import 'package:flutter/widgets.dart';

enum ScreenType { mobile, tablet, desktop }

/// نقاط شکست Responsive. تمام تصمیم‌های Layout فقط از همین‌جا می‌آیند.
///
/// موبایل:  کمتر از 600
/// تبلت:    600 تا کمتر از 1024
/// دسکتاپ:  1024 و بیشتر (Sidebar دائمی)
abstract final class Breakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double wideDesktop = 1440;

  /// از این عرض پنجره به بالا Sidebar کامل (آیکن + متن) نمایش داده می‌شود؛
  /// بین ۶۰۰ و این مقدار Sidebar فشرده (فقط آیکن).
  static const double sidebarExpandedMin = 1280;

  /// حداقل «عرض محتوا» (نه عرض پنجره) برای چیدمان دو ستونه‌ی داشبورد.
  static const double contentTwoColumnMin = 860;

  /// حداکثر عرض محتوای صفحه؛ روی مانیتورهای خیلی عریض محتوا کشیده نمی‌شود.
  static const double contentMaxWidth = 1440;

  static ScreenType typeFor(double width) {
    if (width < mobileMax) return ScreenType.mobile;
    if (width < tabletMax) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static double pagePaddingFor(ScreenType type) => switch (type) {
        ScreenType.mobile => 16,
        ScreenType.tablet => 20,
        ScreenType.desktop => 28,
      };
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  ScreenType get screenType => Breakpoints.typeFor(screenWidth);
  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  /// انتخاب مقدار بر اساس نوع صفحه‌نمایش. tablet در صورت نبود، از mobile می‌آید.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      switch (screenType) {
        ScreenType.mobile => mobile,
        ScreenType.tablet => tablet ?? mobile,
        ScreenType.desktop => desktop ?? tablet ?? mobile,
      };
}
