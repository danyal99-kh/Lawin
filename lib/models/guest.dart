import 'api_enum.dart';
import 'enums.dart';

/// یک ثبت مهمان (پذیرایی رایگان) روی یک سفارش واقعی.
///
/// قالب JSON در `guests/serializers.py` (بک‌اند) تعریف شده است.
class Guest {
  const Guest({
    required this.id,
    required this.name,
    required this.amount,
    required this.status,
    required this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    required this.createdAt,
    this.cancelledAt,
  });

  final int id;
  final String name;
  final int amount;
  final GuestStatus status;
  final String orderId;
  final int orderNumber;
  final int tableNumber;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  bool get isActive => status.isActive;

  factory Guest.fromJson(Map<String, dynamic> json) {
    final cancelled = json['cancelled_at'] as String?;
    return Guest(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: parseApiEnum(GuestStatus.values, json['status'],
          fallback: GuestStatus.active),
      orderId: json['order_id'] as String? ?? '',
      orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
      tableNumber: (json['table_number'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      cancelledAt:
          cancelled == null ? null : DateTime.parse(cancelled).toLocal(),
    );
  }
}

/// گروه مهمان‌ها بر اساس نام: جمع مبلغ، تعداد سفارش و آخرین ثبت.
class GuestGroup {
  const GuestGroup({
    required this.name,
    required this.totalAmount,
    required this.orderCount,
    this.lastAt,
  });

  final String name;
  final int totalAmount;
  final int orderCount;
  final DateTime? lastAt;

  factory GuestGroup.fromJson(Map<String, dynamic> json) {
    final last = json['last_at'] as String?;
    return GuestGroup(
      name: json['name'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      lastAt: last == null ? null : DateTime.parse(last).toLocal(),
    );
  }
}

/// جمع کل مهمان‌نوازیِ فعال (بدون توجه به جست‌وجو).
class GuestSummary {
  const GuestSummary({
    required this.totalAmount,
    required this.guestCount,
    required this.orderCount,
  });

  final int totalAmount;
  final int guestCount;
  final int orderCount;

  factory GuestSummary.fromJson(Map<String, dynamic> json) => GuestSummary(
        totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
        guestCount: (json['guest_count'] as num?)?.toInt() ?? 0,
        orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      );
}
