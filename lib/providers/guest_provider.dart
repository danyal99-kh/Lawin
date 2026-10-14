import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/guest.dart';
import '../repositories/guest_repository.dart';

/// داده‌ی صفحه‌ی مهمان‌ها: گروه‌های مهمان بر اساس نام، جمع کل مهمان‌نوازی و
/// ثبت‌های نامِ انتخاب‌شده.
///
/// همه‌ی ارقام از بک‌اند می‌آید؛ این Provider هیچ محاسبه‌ی مالی نمی‌کند.
class GuestProvider extends ChangeNotifier {
  GuestProvider(this._repository);

  final GuestRepository _repository;

  ViewState<List<GuestGroup>> _groupsState = const ViewState.initial();
  ViewState<GuestSummary> _summaryState = const ViewState.initial();
  ViewState<List<Guest>> _ordersState = const ViewState.initial();

  ViewState<List<GuestGroup>> get groupsState => _groupsState;
  ViewState<GuestSummary> get summaryState => _summaryState;
  ViewState<List<Guest>> get ordersState => _ordersState;

  String _query = '';
  String get query => _query;

  String? _selectedName;
  String? get selectedName => _selectedName;

  bool _busy = false;
  bool get busy => _busy;

  List<GuestGroup> get groups => _groupsState.data ?? const [];
  GuestSummary? get summary => _summaryState.data;

  Future<void> load() async {
    await _loadGroups();
    await _loadSummary();
  }

  Future<void> _loadGroups() async {
    final previous = _groupsState.data;
    _groupsState = ViewState<List<GuestGroup>>.loading(previous: previous);
    _notify();
    final result = await _repository.getGroups(
        query: _query.trim().isEmpty ? null : _query.trim());
    _groupsState = result.when<ViewState<List<GuestGroup>>>(
      success: (list) => list.isEmpty
          ? const ViewState<List<GuestGroup>>.empty()
          : ViewState.success(list),
      failure: (f) => ViewState.error(f, previous: previous),
    );
    _notify();
  }

  Future<void> _loadSummary() async {
    final previous = _summaryState.data;
    _summaryState = ViewState<GuestSummary>.loading(previous: previous);
    _notify();
    final result = await _repository.getSummary();
    _summaryState = result.when<ViewState<GuestSummary>>(
      success: (s) => ViewState.success(s),
      failure: (f) => ViewState.error(f, previous: previous),
    );
    _notify();
  }

  Future<void> search(String value) async {
    if (_query == value) return;
    _query = value;
    _notify();
    await _loadGroups();
  }

  Future<void> refresh() async {
    await _loadGroups();
    await _loadSummary();
    final name = _selectedName;
    if (name != null) await selectGroup(name);
  }

  /// انتخاب یک گروه → ثبت‌های فعال آن نام را می‌آورد.
  Future<void> selectGroup(String? name) async {
    _selectedName = name;
    if (name == null) {
      _ordersState = const ViewState.initial();
      _notify();
      return;
    }
    _ordersState = ViewState<List<Guest>>.loading(previous: _ordersState.data);
    _notify();

    final result = await _repository.getOrders(name);
    _ordersState = result.when<ViewState<List<Guest>>>(
      success: (list) => list.isEmpty
          ? const ViewState<List<Guest>>.empty()
          : ViewState.success(list),
      failure: (f) => ViewState.error(f, previous: _ordersState.data),
    );
    _notify();
  }

  Future<void> clearSelection() => selectGroup(null);

  /// تغییر نام یک ثبت مهمان. null یعنی موفق.
  Future<AppFailure?> rename(int id, String name) async {
    _busy = true;
    _notify();
    final result = await _repository.rename(id, name);
    _busy = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      _notify();
      return failure;
    }
    await refresh();
    return null;
  }

  /// لغو مهمان‌نوازی. null یعنی موفق.
  Future<AppFailure?> cancel(int id) async {
    _busy = true;
    _notify();
    final result = await _repository.cancel(id);
    _busy = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      _notify();
      return failure;
    }
    await refresh();
    return null;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
