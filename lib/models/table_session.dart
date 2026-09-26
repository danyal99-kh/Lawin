/// نشست (Session) یک میز: از اولین سفارش تا پرداخت.
/// زمان ورود و خروج هرگز دستی وارد نمی‌شود:
/// - ورود = لحظه‌ی ثبت اولین سفارش میز
/// - خروج = لحظه‌ی پرداخت صورتحساب و بسته‌شدن سفارش
class TableSession {
  const TableSession({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.enteredAt,
    this.exitedAt,
  });

  final String id;
  final int tableId;
  final int tableNumber;
  final DateTime enteredAt;
  final DateTime? exitedAt;
  bool get isActive => exitedAt == null;
  bool get isOpen => exitedAt == null;

  /// مدت حضور تا [now] (برای نشست باز) یا تا لحظه‌ی خروج (برای نشست بسته).
  Duration durationAt(DateTime now) {
    final d = (exitedAt ?? now).difference(enteredAt);
    return d.isNegative ? Duration.zero : d;
  }

  TableSession copyWith({DateTime? exitedAt}) => TableSession(
        id: id,
        tableId: tableId,
        tableNumber: tableNumber,
        enteredAt: enteredAt,
        exitedAt: exitedAt ?? this.exitedAt,
      );

  factory TableSession.fromJson(Map<String, dynamic> json) {
    final exited = json['exited_at'] as String?;
    return TableSession(
      id: json['id'] as String,
      tableId: json['table_id'] as int,
      tableNumber: json['table_number'] as int,
      enteredAt: DateTime.parse(json['entered_at'] as String).toLocal(),
      exitedAt: exited == null ? null : DateTime.parse(exited).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_number': tableNumber,
        'entered_at': enteredAt.toUtc().toIso8601String(),
        'exited_at': exitedAt?.toUtc().toIso8601String(),
      };
}
