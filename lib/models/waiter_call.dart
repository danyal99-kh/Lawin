import 'api_enum.dart';

/// وضعیت درخواست گارسون؛ دقیقاً مطابق `waiter_calls.models.WaiterCall.Status`.
/// بک‌اند «seen» ندارد؛ «acknowledged» یعنی گارسون درخواست را دیده و رسیده است.
enum WaiterCallStatus implements ApiEnum {
  pending('pending', 'در انتظار'),
  acknowledged('acknowledged', 'در حال رسیدن'),
  completed('completed', 'انجام شد');

  const WaiterCallStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  /// فقط این دو وضعیت «فعال» هستند (معادل `waiter_calls.services.ACTIVE`).
  bool get isActive =>
      this == WaiterCallStatus.pending || this == WaiterCallStatus.acknowledged;
}

/// درخواست فراخوان گارسون از سمت مشتریِ نشسته در میز.
/// قرارداد JSON همان `waiter_calls.serializers.call_dict` است.
class WaiterCall {
  const WaiterCall({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.completedAt,
  });

  final String id;
  final int tableId;
  final int tableNumber;
  final WaiterCallStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? completedAt;

  bool get isPending => status == WaiterCallStatus.pending;
  bool get isAcknowledged => status == WaiterCallStatus.acknowledged;
  bool get isCompleted => status == WaiterCallStatus.completed;
  bool get isActive => status.isActive;

  /// چند ثانیه از ثبت درخواست گذشته؛ برای «۲ دقیقه پیش» و مرتب‌سازی.
  Duration get age => DateTime.now().difference(createdAt);

  factory WaiterCall.fromJson(Map<String, dynamic> json) => WaiterCall(
        id: json['id'] as String,
        tableId: (json['table_id'] as num).toInt(),
        tableNumber: (json['table_number'] as num).toInt(),
        status: parseApiEnum(WaiterCallStatus.values, json['status'],
            fallback: WaiterCallStatus.pending),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        acknowledgedAt: _date(json['acknowledged_at']),
        completedAt: _date(json['completed_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_number': tableNumber,
        'status': status.apiValue,
        'created_at': createdAt.toUtc().toIso8601String(),
        'acknowledged_at': acknowledgedAt?.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
      };

  WaiterCall copyWith({
    WaiterCallStatus? status,
    DateTime? acknowledgedAt,
    DateTime? completedAt,
  }) =>
      WaiterCall(
        id: id,
        tableId: tableId,
        tableNumber: tableNumber,
        status: status ?? this.status,
        createdAt: createdAt,
        acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  /// درخواستِ فعالِ همان میز است؟ (برای بازسازی `TableOverview.waiterCall`)
  static WaiterCall? fromJsonNullable(Object? raw) =>
      raw is Map<String, dynamic> ? WaiterCall.fromJson(raw) : null;

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.parse(raw).toLocal() : null;
}
