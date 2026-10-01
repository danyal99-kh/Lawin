import 'package:flutter/services.dart';

/// صدای هشدار درخواست گارسون. یک interface تا در تست‌ها قابل جایگزینی باشد
/// و UI/Provider به `SystemSound` مستقیم وابسته نشود.
abstract interface class WaiterAlerter {
  /// یک‌بار پخش صدای هشدار. نباید خطا بدهد.
  Future<void> play();
}

/// پیاده‌سازی واقعی روی `SystemSound` (همان صدایی که برای سفارش جدید استفاده می‌شود).
class SystemWaiterAlerter implements WaiterAlerter {
  const SystemWaiterAlerter();

  @override
  Future<void> play() => SystemSound.play(SystemSoundType.alert);
}
