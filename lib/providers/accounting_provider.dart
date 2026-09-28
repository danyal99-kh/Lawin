// lib/providers/accounting_provider.dart
import 'package:flutter/foundation.dart';

import '../core/utils/date_ranges.dart';
import '../core/utils/view_state.dart';
import '../models/accounting_entry.dart';
import '../repositories/accounting_repository.dart';

enum AccountingPeriod {
  today('امروز'),
  week('این هفته'),
  month('این ماه'),
  all('همه');

  const AccountingPeriod(this.label);
  final String label;
}

/// دفتر حسابداری: ترکیب درآمد (سفارش‌های پرداخت‌شده) و هزینه‌ها، با فیلتر بازه‌ی زمانی.
class AccountingProvider extends ChangeNotifier {
  AccountingProvider(this._repository);

  final AccountingRepository _repository;

  ViewState<List<AccountingEntry>> _state = const ViewState.initial();
  ViewState<List<AccountingEntry>> get state => _state;

  AccountingPeriod _period = AccountingPeriod.month;
  AccountingPeriod get period => _period;

  bool _disposed = false;

  List<AccountingEntry> get _all => _state.data ?? const [];

  DateTime? _periodStart(DateTime now) => switch (_period) {
        AccountingPeriod.today => DateRanges.startOfDay(now),
        AccountingPeriod.week => DateRanges.startOfWeek(now),
        AccountingPeriod.month => DateRanges.startOfJalaliMonth(now),
        AccountingPeriod.all => null,
      };

  List<AccountingEntry> get visible {
    final start = _periodStart(DateTime.now());
    if (start == null) return _all;
    return _all.where((e) => !e.date.isBefore(start)).toList();
  }

  int get totalIncome =>
      visible.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);

  int get totalExpense =>
      visible.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);

  int get profit => totalIncome - totalExpense;

  void setPeriod(AccountingPeriod p) {
    if (p == _period) return;
    _period = p;
    _notify();
  }

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<AccountingEntry>>.loading(previous: previous);
    _notify();
    final result = await _repository.getEntries();
    _state = result.when<ViewState<List<AccountingEntry>>>(
      success: (list) => ViewState<List<AccountingEntry>>.success(list),
      failure: (f) =>
          ViewState<List<AccountingEntry>>.error(f, previous: previous),
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
