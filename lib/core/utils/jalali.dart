/// تبدیل تاریخ میلادی به شمسی (الگوریتم ۳۳ ساله، معتبر برای بازه‌ی کاربردی امروز).
class Jalali {
  const Jalali(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  /// نام روز هفته؛ شاخص بر اساس DateTime.weekday (دوشنبه = ۱ … یکشنبه = ۷).
  static const _weekdayNames = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه',
  ];

  static String weekdayName(DateTime dt) => _weekdayNames[dt.weekday - 1];

  factory Jalali.fromDateTime(DateTime dt) {
    var gy = dt.year;
    final gm = dt.month;
    final gd = dt.day;
    const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int jy;
    if (gy > 1600) {
      jy = 979;
      gy -= 1600;
    } else {
      jy = 0;
      gy -= 621;
    }
    final gy2 = gm > 2 ? gy + 1 : gy;
    var days = 365 * gy +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) -
        80 +
        gd +
        gdm[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final int jm;
    final int jd;
    if (days < 186) {
      jm = 1 + days ~/ 31;
      jd = 1 + days % 31;
    } else {
      jm = 7 + (days - 186) ~/ 30;
      jd = 1 + (days - 186) % 30;
    }
    return Jalali(jy, jm, jd);
  }

  String format({String separator = '/'}) =>
      '$year$separator${month.toString().padLeft(2, '0')}$separator${day.toString().padLeft(2, '0')}';
}
