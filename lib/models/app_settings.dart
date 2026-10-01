/// تنظیمات کلی برنامه: اطلاعات کافه و رفتار پیش‌فرض سیستم.
///
/// نام propertyها در Dart همان naming داخلی پنل است (مثلاً `cafeName`)؛ کلیدهای
/// JSON دقیقاً همان چیزی است که Django در `GET/PATCH /api/v1/settings/` می‌گیرد.
class AppSettings {
  const AppSettings({
    required this.cafeName,
    this.address,
    this.phone,
    this.receiptFooterNote,
    this.autoPrintBarOrders = true,
    this.lowStockAlertEnabled = true,
  });

  final String cafeName;
  final String? address;
  final String? phone;

  /// متن پایین رسید (مثلاً «با تشکر از خرید شما»).
  final String? receiptFooterNote;

  /// چاپ خودکار سفارش بار بلافاصله پس از ثبت سفارش.
  final bool autoPrintBarOrders;

  /// نمایش بنر هشدار موجودی کم در داشبورد.
  final bool lowStockAlertEnabled;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        cafeName: json['name'] as String,
        address: (json['address'] as String?)?.clean,
        phone: (json['phone'] as String?)?.clean,
        receiptFooterNote: (json['receipt_note'] as String?)?.clean,
        autoPrintBarOrders: json['auto_print'] as bool? ?? true,
        lowStockAlertEnabled: json['low_stock_alert'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': cafeName,
        'address': address,
        'phone': phone,
        'receipt_note': receiptFooterNote,
        'auto_print': autoPrintBarOrders,
        'low_stock_alert': lowStockAlertEnabled,
      };
}

/// داده‌ی فرم ویرایش تنظیمات.
class AppSettingsDraft {
  const AppSettingsDraft({
    required this.cafeName,
    this.address,
    this.phone,
    this.receiptFooterNote,
    this.autoPrintBarOrders = true,
    this.lowStockAlertEnabled = true,
  });

  final String cafeName;
  final String? address;
  final String? phone;
  final String? receiptFooterNote;
  final bool autoPrintBarOrders;
  final bool lowStockAlertEnabled;

  /// حذف فاصله‌های اضافه؛ متن خالی → null.
  AppSettingsDraft normalized() => AppSettingsDraft(
        cafeName: cafeName.trim(),
        address: address.clean,
        phone: phone.clean,
        receiptFooterNote: receiptFooterNote.clean,
        autoPrintBarOrders: autoPrintBarOrders,
        lowStockAlertEnabled: lowStockAlertEnabled,
      );
}

/// پیام خوشامدگویی صفحه‌ی مشتری.
///
/// عمداً یک منبع جدا از [AppSettings] است: در Django هم مدل و endpoint خودش را
/// دارد (`WelcomeMessage` + `/api/v1/settings/welcome/`) چون صفحه‌ی خوشامد
/// جداگانه نمایش/غیرفعال می‌شود.
class WelcomeSettings {
  const WelcomeSettings({
    required this.title,
    required this.message,
    this.enabled = true,
    this.updatedAt,
  });

  final String title;
  final String message;
  final bool enabled;
  final DateTime? updatedAt;

  factory WelcomeSettings.fromJson(Map<String, dynamic> json) => WelcomeSettings(
        title: json['title'] as String,
        message: (json['message'] as String?) ?? '',
        enabled: json['enabled'] as bool? ?? true,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'enabled': enabled,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// داده‌ی فرم ویرایش پیام خوشامدگویی.
class WelcomeSettingsDraft {
  const WelcomeSettingsDraft({
    required this.title,
    required this.message,
    this.enabled = true,
  });

  final String title;
  final String message;
  final bool enabled;

  WelcomeSettingsDraft normalized() => WelcomeSettingsDraft(
        title: title.trim(),
        message: message.trim(),
        enabled: enabled,
      );
}

extension on String? {
  /// فاصله‌های اضافه حذف شود؛ متن خالی → null (هم برای فرم و هم برای پاسخ API).
  String? get clean {
    final t = this?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
