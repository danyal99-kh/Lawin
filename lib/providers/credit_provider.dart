import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/credit.dart';
import '../models/enums.dart';
import '../repositories/credit_repository.dart';

/// داده‌ی صفحه‌ی نسیه‌ها: بدهکارها با جمع مانده‌شان، نسیه‌های بدهکارِ انتخاب‌شده
/// و وصول‌های ثبت‌شده.
///
/// همه‌ی ارقام از بک‌اند می‌آید؛ این Provider هیچ محاسبه‌ی مالی نمی‌کند.
class CreditProvider extends ChangeNotifier {
  CreditProvider(this._repository);

  final CreditRepository _repository;

  ViewState<List<Debtor>> _debtorsState = const ViewState.initial();
  ViewState<List<Credit>> _creditsState = const ViewState.initial();
  ViewState<List<CreditPayment>> _paymentsState = const ViewState.initial();

  ViewState<List<Debtor>> get debtorsState => _debtorsState;
  ViewState<List<Credit>> get creditsState => _creditsState;
  ViewState<List<CreditPayment>> get paymentsState => _paymentsState;

  String _query = '';
  String get query => _query;

  int? _selectedId;
  int? get selectedId => _selectedId;

  bool _settling = false;
  bool get settling => _settling;

  List<Debtor> get debtors => _debtorsState.data ?? const [];

  List<Credit> get credits => _creditsState.data ?? const [];

  List<CreditPayment> get payments => _paymentsState.data ?? const [];

  /// جمع کل طلب‌های وصول‌نشده — فقط جمع لیستِ خوانده‌شده، نه محاسبه‌ی تازه.
  int get totalDebt => debtors.fold<int>(0, (s, d) => s + d.debt);

  int get openDebtors =>
      debtors.where((d) => d.debt > 0).length;

  Future<void> load() async {
    final previous = _debtorsState.data;
    _debtorsState = ViewState<List<Debtor>>.loading(previous: previous);
    _notify();

    final result =
        await _repository.getDebtors(query: _query.trim().isEmpty ? null : _query.trim());
    _debtorsState = result.when<ViewState<List<Debtor>>>(
      success: (list) =>
          list.isEmpty ? ViewState.empty() : ViewState.success(list),
      failure: (f) => ViewState.error(f, previous: previous),
    );
    _notify();
  }

  Future<void> search(String value) async {
    if (_query == value) return;
    _query = value;
    _notify();
    await load();
  }

  Future<void> refresh() => load();

  /// انتخاب یک بدهکار → نسیه‌ها و وصول‌هایش را می‌آورد.
  Future<void> selectDebtor(int? id) async {
    _selectedId = id;
    if (id == null) {
      _creditsState = const ViewState.initial();
      _paymentsState = const ViewState.initial();
      _notify();
      return;
    }
    _notify();

    _creditsState = ViewState.loading(previous: _creditsState.data);
    _paymentsState = ViewState.loading(previous: _paymentsState.data);
    _notify();

    final detail = await _repository.getDebtor(id);
    _creditsState = detail.when<ViewState<List<Credit>>>(
      success: (d) => d.credits.isEmpty
          ? ViewState.empty()
          : ViewState.success(d.credits),
      failure: (f) => ViewState.error(f, previous: _creditsState.data),
    );
    _notify();

    final payments = await _repository.getPayments(debtorId: id);
    _paymentsState = payments.when<ViewState<List<CreditPayment>>>(
      success: (list) => list.isEmpty
          ? ViewState.empty()
          : ViewState.success(list),
      failure: (f) => ViewState.error(f, previous: _paymentsState.data),
    );
    _notify();
  }

  Future<void> clearSelection() => selectDebtor(null);

  /// ثبت تسویه. null یعنی موفق. بعد از موفقیت بدهکارها و نسیه‌ها را تازه
  /// می‌کنیم چون مانده‌ها را خودِ سرور محاسبه کرده است.
  Future<AppFailure?> settle({
    int? debtorId,
    int? creditId,
    required int amount,
    CashAccount account = CashAccount.cash,
    String? note,
    String? idempotencyKey,
  }) async {
    if (amount <= 0) {
      return AppFailure.validation('مبلغ تسویه را درست وارد کنید.');
    }
    _settling = true;
    _notify();

    final result = await _repository.settle(
      debtorId: debtorId,
      creditId: creditId,
      amount: amount,
      account: account,
      note: note,
      idempotencyKey: idempotencyKey,
    );

    final failure = result.failureOrNull;
    _settling = false;
    if (failure != null) {
      _notify();
      return failure;
    }

    final settledDebtor = result.dataOrNull?.debtorId ?? debtorId;
    await load();
    await selectDebtor(settledDebtor ?? _selectedId);
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
