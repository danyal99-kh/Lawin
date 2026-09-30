import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/api/api_order_repository.dart';
import '../services/realtime_service.dart';
import 'dashboard_provider.dart';
import 'order_provider.dart';
import 'table_provider.dart';

/// رویدادهای لحظه‌ای Django را به Providerهای موجود وصل می‌کند.
class RealtimeSync extends ChangeNotifier {
  RealtimeSync({
    required this.service,
    required this.orders,
    required this.tables,
    required this.dashboard,
    this.changesRepo,
  });

  final RealtimeService service;
  final OrderProvider orders;
  final TableProvider tables;
  final DashboardProvider dashboard;
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

  Future<void> start() async {
    _evSub = service.events.listen(_onEvent);
    _connSub = service.connection.listen((ok) {
      _connected = ok;
      notifyListeners();
      if (ok) _resync(); // بعد از هر اتصال، از دست‌رفته‌ها را جبران کن
    });
    await service.start();
  }

  void _onEvent(RealtimeEvent e) {
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
    }
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
