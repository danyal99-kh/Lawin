/// ابزارهای متن فارسی برای جستجو و ورودی‌ها.
abstract final class TextUtils {
  /// یکسان‌سازی متن برای جستجو: ی/ک عربی → فارسی، نیم‌فاصله → فاصله، حذف فاصله‌های اضافه.
  static String normalizeFa(String s) => latinDigits(s)
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('\u200c', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  /// ارقام فارسی (۰-۹) و عربی (٠-٩) → لاتین.
  static String latinDigits(String s) {
    final b = StringBuffer();
    for (final c in s.runes) {
      if (c >= 0x06F0 && c <= 0x06F9) {
        b.writeCharCode(c - 0x06F0 + 0x30);
      } else if (c >= 0x0660 && c <= 0x0669) {
        b.writeCharCode(c - 0x0660 + 0x30);
      } else {
        b.writeCharCode(c);
      }
    }
    return b.toString();
  }
}