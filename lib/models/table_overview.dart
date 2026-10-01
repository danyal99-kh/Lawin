import 'cafe_table.dart';
import 'enums.dart';
import 'order.dart';
import 'table_session.dart';
import 'waiter_call.dart';

/// نمای کامل یک میز برای صفحه‌ی میزها: خود میز، نشست فعال، آخرین نشست بسته‌شده و سفارش‌های باز.
/// معادل یک آیتم از `GET /api/v1/tables/`.
class TableOverview {
  const TableOverview({
    required this.table,
    this.activeSession,
    this.lastSession,
    this.openOrders = const [],
    this.waiterCall,
  });

  final CafeTable table;
  final TableSession? activeSession;

  /// آخرین نشستی که بسته شده (برای نمایش زمان خروج میز خالی).
  final TableSession? lastSession;
  final List<Order> openOrders;

  /// درخواست فعال گارسون برای این میز (بک‌اند در `waiter_call` همین را می‌فرستد).
  final WaiterCall? waiterCall;

  TableStatus get status => table.status;

  /// مبلغ فعلی = جمع سفارش‌های باز میز.
  int get currentAmount => openOrders.fold(0, (sum, o) => sum + o.total);
  bool get hasOpenOrders => openOrders.isNotEmpty;

  factory TableOverview.fromJson(Map<String, dynamic> json) {
    TableSession? session(String key) => json[key] == null
        ? null
        : TableSession.fromJson(json[key] as Map<String, dynamic>);
    return TableOverview(
      table: CafeTable.fromJson(json['table'] as Map<String, dynamic>),
      activeSession: session('active_session'),
      lastSession: session('last_session'),
      openOrders: (json['open_orders'] as List<dynamic>? ?? const [])
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      waiterCall: WaiterCall.fromJsonNullable(json['waiter_call']),
    );
  }

  Map<String, dynamic> toJson() => {
        'table': table.toJson(),
        'active_session': activeSession?.toJson(),
        'last_session': lastSession?.toJson(),
        'open_orders': openOrders.map((o) => o.toJson()).toList(),
        'waiter_call': waiterCall?.toJson(),
      };
}
