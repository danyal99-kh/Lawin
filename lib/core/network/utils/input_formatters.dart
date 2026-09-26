import 'package:flutter/services.dart';

import 'text_utils.dart';

/// ارقام فارسی/عربی تایپ‌شده را هنگام ورود به لاتین تبدیل می‌کند
/// (بعد از آن می‌توان از FilteringTextInputFormatter.digitsOnly استفاده کرد).
class LatinDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final converted = TextUtils.latinDigits(newValue.text);
    return converted == newValue.text
        ? newValue
        : newValue.copyWith(text: converted);
  }
}