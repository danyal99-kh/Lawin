// lib/models/waste_reason.dart
import 'api_enum.dart';

/// دلیل ثبت ضایعات کالای انبار.
enum WasteReason implements ApiEnum {
  expired('expired', 'تاریخ‌گذشته'),
  damaged('damaged', 'آسیب‌دیده'),
  spoiled('spoiled', 'فاسدشده'),
  preparationError('preparation_error', 'خطای آماده‌سازی'),
  other('other', 'سایر موارد');

  const WasteReason(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}
