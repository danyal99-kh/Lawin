import 'package:flutter/foundation.dart';

import '../core/utils/view_state.dart';
import '../models/report.dart';
import '../repositories/report_repository.dart';

/// وضعیت صفحه‌ی گزارش‌ها: بازه‌ی انتخاب‌شده + داده‌ی گزارش.
class ReportProvider extends ChangeNotifier {
  ReportProvider(this._repository);

  final ReportRepository _repository;

  ViewState<SalesReport> _state = const ViewState.initial();
  ViewState<SalesReport> get state => _state;

  ReportPeriod _period = ReportPeriod.month;
  ReportPeriod get period => _period;

  DateTime? _customStart;
  DateTime? _customEnd;
  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;

  bool _disposed = false;

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<SalesReport>.loading(previous: previous);
    _notify();
    final result = (_period == ReportPeriod.custom &&
            _customStart != null &&
            _customEnd != null)
        ? await _repository.getCustomReport(_customStart!, _customEnd!)
        : await _repository.getReport(_period);
    _state = result.when<ViewState<SalesReport>>(
      success: (data) => ViewState<SalesReport>.success(data),
      failure: (f) => ViewState<SalesReport>.error(f, previous: previous),
    );
    _notify();
  }

  Future<void> setPeriod(ReportPeriod p) async {
    if (p == _period) return;
    _period = p;
    await load();
  }

  Future<void> setCustomRange(DateTime start, DateTime end) async {
    _period = ReportPeriod.custom;
    _customStart = start;
    _customEnd = end;
    await load();
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
