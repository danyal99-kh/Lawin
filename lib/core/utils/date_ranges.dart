import 'jalali.dart';

/// بازه‌های زمانی گزارش‌ها. ماه بر اساس تقویم شمسی و هفته از «شنبه» شروع می‌شود.
abstract final class DateRanges {
  static DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static DateTime endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day + 1);

  /// شنبه‌ی همان هفته.
  static DateTime startOfWeek(DateTime dt) {
    final daysSinceSaturday = (dt.weekday + 1) % 7;
    return DateTime(dt.year, dt.month, dt.day - daysSinceSaturday);
  }

  /// اول ماه شمسی (مثلاً ۱ مهر) به‌صورت DateTime میلادی.
  static DateTime startOfJalaliMonth(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    return DateTime(dt.year, dt.month, dt.day - (j.day - 1));
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// آیا [dt] در بازه‌ی [start, end) است؟
  static bool inRange(DateTime dt, DateTime start, DateTime end) =>
      !dt.isBefore(start) && dt.isBefore(end);
}
