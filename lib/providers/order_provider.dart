import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

/// فیلتر صف سفارش‌ها. «باز» یعنی صف کار آشپزخانه (پیش‌فرض صفحه).
enum OrderFilter {
  open('باز'),
  newOrder('جدید'),
  preparing('در حال آماده‌سازی'),
  ready('آماده'),
  delivered('تحویل‌شده'),
  paid('پرداخت‌شده'),
  cancelled('لغوشده');

  const OrderFilter(this.label);
  final String label;

  bool matches(OrderStatus s) => switch (this) {
        OrderFilter.open => s.isOpen,
        OrderFilter.newOrder => s == OrderStatus.newOrder,
        OrderFilter.preparing => s == OrderStatus.preparing,
        OrderFilter.ready => s == OrderStatus.ready,
        OrderFilter.delivered => s == OrderStatus.delivered,
        OrderFilter.paid => s == OrderStatus.paid,
        OrderFilter.cancelled => s == OrderStatus.cancelled,
      };
}

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._repository);

  final OrderRepository _repository;

  ViewState<List<Order>> _state = const ViewState.initial();
  ViewState<List<Order>> get state => _state;

  OrderFilter _filter = OrderFilter.open;
  OrderFilter get filter => _filter;

  bool _busy = false;

  /// در حال اجرای یک عملیات (ثبت/تغییر وضعیت/لغو) هستیم.
  bool get busy => _busy;

  bool _disposed = false;

  List<Order> get _all => _state.data ?? const [];

  List<Order> get visible =>
      _all.where((o) => _filter.matches(o.status)).toList();

  int countFor(OrderFilter f) => _all.where((o) => f.matches(o.status)).length;

  void setFilter(OrderFilter f) {
    if (f == _filter) return;
    _filter = f;
    _notify();
  }

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<Order>>.loading(previous: previous);
    _notify();
    final result = await _repository.getOrders();
    _state = result.when<ViewState<List<Order>>>(
      success: (list) => ViewState<List<Order>>.success(list),
      failure: (f) => ViewState<List<Order>>.error(f, previous: previous),
    );
    _notify();
  }

  Future<AppFailure?> create(OrderDraft draft) async {
    _busy = true;
    _notify();
    final result = await _repository.create(draft);
    final failure = result.failureOrNull;
    if (failure == null) _upsert(result.dataOrNull!);
    _busy = false;
    _notify();
    return failure;
  }

  Future<AppFailure?> updateStatus(Order order, OrderStatus status) async {
    _busy = true;
    _notify();
    final result = await _repository.updateStatus(order.id, status);
    final failure = result.failureOrNull;
    if (failure == null) _upsert(result.dataOrNull!);
    _busy = false;
    _notify();
    return failure;
  }

  Future<AppFailure?> cancel(Order order) async {
    _busy = true;
    _notify();
    final result = await _repository.cancel(order.id);
    final failure = result.failureOrNull;
    if (failure == null) _upsert(result.dataOrNull!);
    _busy = false;
    _notify();
    return failure;
  }

  Future<AppFailure?> markBarPrinted(Order order) async {
    final result = await _repository.markBarPrinted(order.id);
    final failure = result.failureOrNull;
    if (failure == null) _upsert(result.dataOrNull!);
    _notify();
    return failure;
  }

  void _upsert(Order saved) {
    final exists = _all.any((o) => o.id == saved.id);
    final list = exists
        ? [for (final o in _all) o.id == saved.id ? saved : o]
        : [saved, ..._all];
    _state = ViewState<List<Order>>.success(list);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
