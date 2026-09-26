import 'package:cafe_book_admin/repositories/mock/mock_table_repository.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/enums.dart';
import '../models/table_overview.dart';
import '../repositories/table_repository.dart';

enum TableFilter {
  all('همه'),
  active('فعال'),
  empty('خالی'),
  reserved('رزرو شده');

  const TableFilter(this.label);
  final String label;

  bool matches(TableStatus s) => switch (this) {
        TableFilter.all => true,
        TableFilter.active => s == TableStatus.active,
        TableFilter.empty => s == TableStatus.empty,
        TableFilter.reserved => s == TableStatus.reserved,
      };
}

class TableProvider extends ChangeNotifier {
  TableProvider(this._repository, {MockTableRepository? devTools});

  final TableRepository _repository;

  ViewState<List<TableOverview>> _state = const ViewState.initial();
  ViewState<List<TableOverview>> get state => _state;

  TableFilter _filter = TableFilter.all;
  TableFilter get filter => _filter;

  bool _busy = false;

  /// در حال اجرای یک عملیات (مثل رزرو) هستیم.
  bool get busy => _busy;

  bool _disposed = false;

  List<TableOverview> get _all => _state.data ?? const [];

  List<TableOverview> get visible =>
      _all.where((o) => _filter.matches(o.status)).toList();

  int countFor(TableFilter f) =>
      _all.where((o) => f.matches(o.status)).length;

  void setFilter(TableFilter f) {
    if (f == _filter) return;
    _filter = f;
    _notify();
  }

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<TableOverview>>.loading(previous: previous);
    _notify();
    final result = await _repository.getTables();
    _state = result.when<ViewState<List<TableOverview>>>(
      success: (list) => list.isEmpty
          ? const ViewState<List<TableOverview>>.empty()
          : ViewState<List<TableOverview>>.success(list),
      failure: (f) =>
          ViewState<List<TableOverview>>.error(f, previous: previous),
    );
    _notify();
  }

  /// رزرو/لغو رزرو. در صورت موفقیت null، در غیر این صورت خطای قابل‌نمایش برمی‌گردد.
  Future<AppFailure?> setReserved(int tableId, bool reserved) async {
    _busy = true;
    _notify();
    final result =
        await _repository.setReserved(tableId, reserved: reserved);
    AppFailure? failure;
    result.when<void>(
      success: (updated) {
        _state = ViewState<List<TableOverview>>.success([
          for (final o in _all)
            if (o.table.id == updated.table.id) updated else o,
        ]);
      },
      failure: (f) => failure = f,
    );
    _busy = false;
    _notify();
    return failure;
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