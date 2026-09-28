/// تنظیمات کلی برنامه: اطلاعات کافه و رفتار پیش‌فرض سیستم.
/// در مرحله‌ی اتصال به Django با یک Endpoint ساده (GET/PATCH) جایگزین می‌شود.
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
        cafeName: json['cafe_name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        receiptFooterNote: json['receipt_footer_note'] as String?,
        autoPrintBarOrders: json['auto_print_bar_orders'] as bool? ?? true,
        lowStockAlertEnabled: json['low_stock_alert_enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'cafe_name': cafeName,
        'address': address,
        'phone': phone,
        'receipt_footer_note': receiptFooterNote,
        'auto_print_bar_orders': autoPrintBarOrders,
        'low_stock_alert_enabled': lowStockAlertEnabled,
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
  AppSettingsDraft normalized() {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return AppSettingsDraft(
      cafeName: cafeName.trim(),
      address: clean(address),
      phone: clean(phone),
      receiptFooterNote: clean(receiptFooterNote),
      autoPrintBarOrders: autoPrintBarOrders,
      lowStockAlertEnabled: lowStockAlertEnabled,
    );
  }
}
