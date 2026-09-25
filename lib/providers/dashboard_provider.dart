import 'package:cafe_book_admin/repositories/dashboard_repository.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/view_state.dart';
import '../models/dashboard_summary.dart';

/// وضعیت داشبورد. UI فقط این Provider را می‌خواند، نه Repository را.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  final DashboardRepository _repository;

  ViewState<DashboardSummary> _state = const ViewState.initial();
  ViewState<DashboardSummary> get state => _state;

  bool _disposed = false;

  /// بارگذاری/تازه‌سازی. داده‌ی قبلی هنگام بارگذاری مجدد نگه داشته می‌شود.
  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<DashboardSummary>.loading(previous: previous);
    _notify();
    final result = await _repository.getSummary();
    _state = result.when<ViewState<DashboardSummary>>(
      success: (data) => ViewState<DashboardSummary>.success(data),
      failure: (f) => ViewState<DashboardSummary>.error(f, previous: previous),
    );
    _notify();
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
