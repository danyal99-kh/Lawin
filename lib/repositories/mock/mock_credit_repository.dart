import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/credit.dart';
import '../../models/enums.dart';
import '../credit_repository.dart';

/// پیاده‌سازی Mock نسیه: همان قواعد بک‌اند (قدیمی‌ترین اول، بدون
/// بیش‌پرداخت، idempotency) را روی لیست درون‌حافظه‌ای اجرا می‌کند تا UI
/// بدون سرور هم رفتار واقعی را ببیند.
class MockCreditRepository implements CreditRepository {
  MockCreditRepository({DateTime? now}) {
    final clock = now ?? DateTime.now();
    DateTime ago(int days) =>
        DateTime(clock.year, clock.month, clock.day - days, 20, 30);

    _paymentSeq = 0;

    _debtors.addAll([
      Debtor(
        id: 1,
        name: 'شرکت آریا',
        phone: '09120000001',
        debt: 320000,
        openCredits: 2,
        extended: 920000,
        lastActivity: ago(1),
        createdAt: ago(20),
      ),
      Debtor(
        id: 2,
        name: 'دفتر مرکزی نگین',
        debt: 150000,
        openCredits: 1,
        extended: 150000,
        lastActivity: ago(3),
        createdAt: ago(12),
      ),
      Debtor(
        id: 3,
        name: 'کافه لاله',
        debt: 0,
        openCredits: 0,
        extended: 480000,
        lastActivity: ago(6),
        createdAt: ago(40),
      ),
    ]);

    _credits.addAll([
      Credit(
        id: 1,
        debtorId: 1,
        debtorName: 'شرکت آریا',
        orderId: 'mock-order-1001',
        orderNumber: 1001,
        amount: 600000,
        remainingAmount: 300000,
        status: CreditStatus.open,
        createdAt: ago(18),
      ),
      Credit(
        id: 2,
        debtorId: 1,
        debtorName: 'شرکت آریا',
        orderId: 'mock-order-1002',
        orderNumber: 1002,
        amount: 420000,
        remainingAmount: 20000,
        status: CreditStatus.open,
        createdAt: ago(10),
      ),
      Credit(
        id: 3,
        debtorId: 2,
        debtorName: 'دفتر مرکزی نگین',
        orderId: 'mock-order-1003',
        orderNumber: 1003,
        amount: 150000,
        remainingAmount: 150000,
        status: CreditStatus.open,
        createdAt: ago(5),
      ),
      Credit(
        id: 4,
        debtorId: 3,
        debtorName: 'کافه لاله',
        orderId: 'mock-order-1004',
        orderNumber: 1004,
        amount: 480000,
        remainingAmount: 0,
        status: CreditStatus.settled,
        createdAt: ago(40),
      ),
    ]);

    _payments.addAll([
      CreditPayment(
        id: ++_paymentSeq,
        creditId: 1,
        debtorId: 1,
        debtorName: 'شرکت آریا',
        orderId: 'mock-order-1001',
        orderNumber: 1001,
        amount: 300000,
        account: CashAccount.cash,
        createdAt: ago(16),
      ),
      CreditPayment(
        id: ++_paymentSeq,
        creditId: 4,
        debtorId: 3,
        debtorName: 'کافه لاله',
        orderId: 'mock-order-1004',
        orderNumber: 1004,
        amount: 480000,
        account: CashAccount.bank,
        createdAt: ago(34),
      ),
    ]);

    _recompute();
  }

  final List<Debtor> _debtors = [];
  final List<Credit> _credits = [];
  final List<CreditPayment> _payments = [];
  final Map<String, SettleResult> _idempotency = {};

  late int _paymentSeq;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  /// جمع‌ها همیشه از خودِ ردیف‌ها محاسبه می‌شوند، دقیقاً مثل `debtor_totals`.
  void _recompute() {
    for (var i = 0; i < _debtors.length; i++) {
      final d = _debtors[i];
      final own = _credits.where((c) => c.debtorId == d.id);
      var debt = 0;
      var open = 0;
      var extended = 0;
      DateTime? last;
      for (final c in own) {
        debt += c.remainingAmount;
        extended += c.amount;
        if (c.status.isOpen) open++;
        if (last == null || c.createdAt.isAfter(last)) last = c.createdAt;
      }
      for (final p in _payments.where((p) => p.debtorId == d.id)) {
        if (last == null || p.createdAt.isAfter(last)) last = p.createdAt;
      }
      _debtors[i] = Debtor(
        id: d.id,
        name: d.name,
        phone: d.phone,
        note: d.note,
        debt: debt,
        openCredits: open,
        extended: extended,
        lastActivity: last,
        createdAt: d.createdAt,
      );
    }
  }

  @override
  Future<Result<List<Credit>>> getCredits(
      {int? debtorId, CreditStatus? status}) async {
    await _latency();
    var list = [..._credits];
    if (debtorId != null) {
      list = list.where((c) => c.debtorId == debtorId).toList();
    }
    if (status != null) {
      list = list.where((c) => c.status == status).toList();
    }
    list.sort((a, b) {
      final byDate = a.createdAt.compareTo(b.createdAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return Success(List.unmodifiable(list));
  }

  @override
  Future<Result<List<Debtor>>> getDebtors({String? query}) async {
    await _latency();
    final q = (query ?? '').trim().toLowerCase();
    final list = _debtors
        .where((d) => q.isEmpty || d.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.debt.compareTo(a.debt));
    return Success(List.unmodifiable(list));
  }

  @override
  Future<Result<DebtorDetail>> getDebtor(int id) async {
    await _latency();
    Debtor? debtor;
    for (final d in _debtors) {
      if (d.id == id) {
        debtor = d;
        break;
      }
    }
    if (debtor == null) return Failure(AppFailure.notFound());
    final own = _credits.where((c) => c.debtorId == id).toList()
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return Success(DebtorDetail(
      debtor: debtor,
      credits: List.unmodifiable(own),
    ));
  }

  @override
  Future<Result<List<CreditPayment>>> getPayments({int? debtorId}) async {
    await _latency();
    final list = _payments.where((p) => debtorId == null || p.debtorId == debtorId)
        .toList()
      ..sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return Success(List.unmodifiable(list.take(500)));
  }

  @override
  Future<Result<SettleResult>> settle({
    int? debtorId,
    int? creditId,
    required int amount,
    required CashAccount account,
    String? note,
    String? idempotencyKey,
  }) async {
    await _latency();

    if (amount <= 0) {
      return Failure(AppFailure.validation('مبلغ تسویه را درست وارد کنید.'));
    }
    if (debtorId == null && creditId == null) {
      return Failure(AppFailure.validation('بدهکار یا نسیه را مشخص کنید.'));
    }

    final key = (idempotencyKey ?? '').trim();
    if (key.isNotEmpty) {
      final hit = _idempotency[key];
      if (hit != null) return Success(hit);
    }

    var open = _credits
        .where((c) =>
            c.status.isOpen &&
            c.remainingAmount > 0 &&
            (debtorId == null || c.debtorId == debtorId) &&
            (creditId == null || c.id == creditId))
        .toList()
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    if (open.isEmpty) {
      return Failure(AppFailure.conflict('نسیه بازی برای این بدهکار وجود ندارد.'));
    }
    if (creditId != null && debtorId != null && open.first.debtorId != debtorId) {
      return Failure(AppFailure.validation('این نسیه متعلق به آن بدهکار نیست.'));
    }

    final totalOpen =
        open.fold<int>(0, (s, c) => s + c.remainingAmount);
    if (amount > totalOpen) {
      // اصل «بیش‌پرداخت ممنوع»: هرگز بیشتر از مانده وصول نمی‌شود.
      return Failure(AppFailure.conflict(
          'مبلغ تسویه (${amount.toString()}) از مانده‌ی نسیه '
          '(${totalOpen.toString()}) بیشتر است.'));
    }

    var left = amount;
    var taken = 0;
    final changed = <Credit>[];
    final created = <CreditPayment>[];
    final now = DateTime.now();

    for (final c in open) {
      if (left <= 0) break;
      final pay = c.remainingAmount < left ? c.remainingAmount : left;
      if (pay <= 0) continue;
      left -= pay;
      taken += pay;

      final remaining = c.remainingAmount - pay;
      final updated = Credit(
        id: c.id,
        debtorId: c.debtorId,
        debtorName: c.debtorName,
        orderId: c.orderId,
        orderNumber: c.orderNumber,
        amount: c.amount,
        remainingAmount: remaining,
        status: remaining == 0 ? CreditStatus.settled : CreditStatus.open,
        createdAt: c.createdAt,
      );
      _credits[_credits.indexOf(c)] = updated;
      changed.add(updated);

      final payment = CreditPayment(
        id: ++_paymentSeq,
        creditId: c.id,
        debtorId: c.debtorId,
        debtorName: c.debtorName,
        orderId: c.orderId,
        orderNumber: c.orderNumber,
        amount: pay,
        account: account,
        note: (note ?? '').isEmpty ? null : note,
        createdAt: now,
      );
      _payments.add(payment);
      created.add(payment);
    }

    if (taken == 0) {
      return Failure(AppFailure.conflict('مبلغی وصول نشد.'));
    }

    _recompute();
    final result = SettleResult(
      total: taken,
      payments: List.unmodifiable(created),
      credits: List.unmodifiable(changed),
      debtorId: changed.first.debtorId,
      debtorName: changed.first.debtorName,
    );
    if (key.isNotEmpty) _idempotency[key] = result;
    return Success(result);
  }
}
