import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/waiter_call.dart';
import '../repositories/api/api_order_repository.dart';
import '../services/realtime_service.dart';
import 'dashboard_provider.dart';
import 'order_provider.dart';
import 'table_provider.dart';
import 'waiter_call_provider.dart';

/// رویدادهای لحظه‌ای Django را به Providerهای موجود وصل می‌کند.
class RealtimeSync extends ChangeNotifier {
  RealtimeSync({
    required this.service,
    required this.orders,
    required this.tables,
    required this.dashboard,
    required this.waiterCalls,
    this.changesRepo,
  });

  final RealtimeService service;
  final OrderProvider orders;
  final TableProvider tables;
  final DashboardProvider dashboard;

  /// درخواست‌های گارسون؛ رویدادهای آن مستقیم روی همین Provider اعمال می‌شود
  /// (بدون بارگذاری مجدد) تا صدای هشدار بدون تأخیر پخش شود.
  final WaiterCallProvider waiterCalls;
  final ApiOrderRepository? changesRepo;

  StreamSubscription? _evSub;
  StreamSubscription? _connSub;
  Timer? _debounce;
  String? _cursor;

  bool _connected = false;
  bool get connected => _connected;

  /// تعداد سفارش‌های جدید مشتری که هنوز دیده نشده (برای Badge/صدا).
  int _unseenCustomerOrders = 0;
  int get unseenCustomerOrders => _unseenCustomerOrders;

  final _newOrderController = StreamController<int>.broadcast();

  /// شماره‌ی سفارش جدید مشتری را می‌دهد (برای SnackBar یا صدا).
  Stream<int> get newCustomerOrder => _newOrderController.stream;

  void markSeen() {
    _unseenCustomerOrders = 0;
    notifyListeners();
  }

  bool _started = false;

  Future<void> start() async {
    if (_started) return; // جلوگیری از Subscribe دوباره
    _started = true;
    _evSub = service.events.listen(handleEvent);
    _connSub = service.connection.listen((ok) {
      _connected = ok;
      notifyListeners();
      if (ok) _resync();
    });
    await service.start();
  }

  /// هنگام خروج از حساب: قطع WebSocket و لغو Subscribeها.
  Future<void> stop() async {
    _started = false;
    _debounce?.cancel();
    await _evSub?.cancel();
    await _connSub?.cancel();
    _evSub = null;
    _connSub = null;
    _connected = false;
    _cursor = null;
    await service.stop();
  }

  /// پخش رویداد به Providerهای مربوطه؛ عمومی است تا تست بتواند همان مسیر
  /// واقعی WebSocket را بدون سرور اجرا کند.
  void handleEvent(RealtimeEvent e) {
    switch (e.name) {
      case 'order_created':
        final o = e.data['order'] as Map<String, dynamic>?;
        if (o?['source'] == 'customer') {
          _unseenCustomerOrders++;
          _newOrderController.add(o!['number'] as int);
          notifyListeners();
        }
        _refreshSoon();
      case 'order_status_changed':
      case 'payment_completed':
      case 'table_status_changed':
        _refreshSoon();
      case 'waiter_call_created':
      case 'waiter_call_acknowledged':
      case 'waiter_call_completed':
        _applyWaiterCall(e);
    }
  }

  /// بک‌اند `{"call": {...}}` می‌فرستد؛ همان شیء، منبع حقیقت است.
  void _applyWaiterCall(RealtimeEvent e) {
    final raw = e.data['call'];
    if (raw is! Map<String, dynamic>) return;
    waiterCalls.applyCall(WaiterCall.fromJson(raw));
  }

  /// چند رویداد پشت‌سرهم → فقط یک بار بارگذاری.
  void _refreshSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      orders.load();
      tables.load();
      dashboard.load();
    });
  }

  Future<void> _resync() async {
    orders.load();
    tables.load();
    dashboard.load();
    waiterCalls.load();
    final repo = changesRepo;
    if (repo != null) {
      final r = await repo.changes(_cursor);
      _cursor = r.dataOrNull?.cursor ?? _cursor;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _evSub?.cancel();
    _connSub?.cancel();
    _newOrderController.close();
    super.dispose();
  }
}
