import '../constants/app_constants.dart';
import 'jalali.dart';

/// قالب‌بندی اعداد، پول، زمان و تاریخ به فارسی.
abstract final class PersianFormat {
  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// تبدیل ارقام لاتین به فارسی در یک رشته.
  static String digits(Object? value) {
    final s = value.toString();
    final b = StringBuffer();
    for (final c in s.runes) {
      if (c >= 0x30 && c <= 0x39) {
        b.write(_fa[c - 0x30]);
      } else {
        b.writeCharCode(c);
      }
    }
    return b.toString();
  }

  /// عدد با جداکننده‌ی هزارگان: 1250000 → ۱٬۲۵۰٬۰۰۰
  static String number(num value, {int decimals = 0}) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final b = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final fromEnd = intPart.length - i;
      b.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) b.write('٬');
    }
    var out = b.toString();
    if (decimals > 0) {
      final frac = parts[1].replaceFirst(RegExp(r'0+$'), '');
      if (frac.isNotEmpty) out = '$out٫$frac';
    }
    return digits(negative ? '−$out' : out);
  }

  /// مبلغ به تومان: ۱٬۲۵۰٬۰۰۰ تومان
  static String money(num value, {bool withUnit = true}) => withUnit
      ? '${number(value)} ${AppConstants.currencyLabel}'
      : number(value);

  /// مدت زمان: ۱ ساعت و ۳۳ دقیقه
  static String duration(Duration d) {
    final totalMinutes = d.inMinutes;
    if (totalMinutes < 1) return 'کمتر از ۱ دقیقه';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${digits(m)} دقیقه';
    if (m == 0) return '${digits(h)} ساعت';
    return '${digits(h)} ساعت و ${digits(m)} دقیقه';
  }

  /// مدت زمان زنده برای میزها: ۰۱:۳۳:۰۵
  static String clockDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return digits('${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}');
  }

  /// ساعت: ۱۸:۴۲
  static String time(DateTime dt) => digits(
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');

  /// تاریخ شمسی: ۱۴۰۵/۰۷/۰۲
  static String date(DateTime dt) => digits(Jalali.fromDateTime(dt).format());

  /// تاریخ شمسی کامل: ۲ مهر ۱۴۰۵
  static String dateLong(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    return '${digits(j.day)} ${Jalali.monthNames[j.month - 1]} ${digits(j.year)}';
  }

  /// پنجشنبه ۲ مهر ۱۴۰۵
  static String dateWithWeekday(DateTime dt) =>
      '${Jalali.weekdayName(dt)} ${dateLong(dt)}';

  static String dateTime(DateTime dt) => '${date(dt)} - ${time(dt)}';
}
