// رفتار Mock نسیه: همان قواعد بک‌اند (oldest-first، بدون بیش‌پرداخت،
// idempotency) تا UI را به همان شکل واقعی نشان دهد.
import 'package:cafe_book_admin/models/credit.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/mock/mock_credit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12, 0);

  MockCreditRepository fresh() => MockCreditRepository(now: now);

  group('debtor totals come only from credit rows', () {
    test('seed debtors carry their computed debt', () async {
      final repo = fresh();
      final debtors = (await repo.getDebtors()).dataOrNull!;
      // از داده‌ی اولیه: بدهکار ۱ در مجموع ۳۲۰هزار مانده دارد.
      final d = debtors.firstWhere((x) => x.id == 1);
      expect(d.debt, 320000);
      expect(d.openCredits, 2);
      expect(d.extended, 1020000);
    });
  });

  group('settle', () {
    test('partial payment keeps the oldest credit open with remaining',
        () async {
      final repo = fresh();
      // بدهکار ۲ فقط یک نسیه‌ی ۱۵۰هزار دارد؛ نصفش را واریز می‌کنیم.
      final result =
          (await repo.settle(debtorId: 2, amount: 50000, account: CashAccount.cash))
              .dataOrNull!;
      expect(result.total, 50000);
      expect(result.payments, hasLength(1));

      final credits = (await repo.getCredits(debtorId: 2)).dataOrNull!;
      expect(credits.single.remainingAmount, 100000);
      expect(credits.single.status, CreditStatus.open);
    });

    test('oldest-first: settling the total closes the whole batch', () async {
      final repo = fresh();
      // کل مانده‌ی بدهکار ۱ (۳۲۰هزار) واریز می‌شود؛ قدیمی‌ترین نسیه‌ها اول.
      final result =
          (await repo.settle(debtorId: 1, amount: 320000, account: CashAccount.cash))
              .dataOrNull!;
      expect(result.payments, hasLength(2));

      final credits = (await repo.getCredits(debtorId: 1)).dataOrNull!;
      final first = credits.firstWhere((c) => c.id == 1);
      final second = credits.firstWhere((c) => c.id == 2);
      expect(first.remainingAmount, 0);
      expect(first.status, CreditStatus.settled);
      expect(second.remainingAmount, 0);
      expect(second.status, CreditStatus.settled);
    });

    test('overpayment is rejected: never collect more than the open debt',
        () async {
      final repo = fresh();
      final result =
          await repo.settle(debtorId: 2, amount: 500000, account: CashAccount.cash);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, isNotNull);

      // بدون بیش‌پرداخت، مانده دست‌نخورده می‌ماند.
      final credits = (await repo.getCredits(debtorId: 2)).dataOrNull!;
      expect(credits.single.remainingAmount, 150000);
    });

    test('settling a specific credit only touches that credit', () async {
      final repo = fresh();
      final result = (await repo
              .settle(creditId: 2, amount: 20000, account: CashAccount.bank))
          .dataOrNull!;
      expect(result.total, 20000);
      expect(result.credits.single.id, 2);

      final credits = (await repo.getCredits(debtorId: 1)).dataOrNull!;
      final first = credits.firstWhere((c) => c.id == 1);
      expect(first.remainingAmount, 300000); // دست‌نخورده
    });
  });

  group('idempotency', () {
    test('repeating the same key returns the same result without double-charge',
        () async {
      final repo = fresh();
      final first = await repo.settle(
          debtorId: 2,
          amount: 50000,
          account: CashAccount.cash,
          idempotencyKey: 'dup-key');
      expect(first.failureOrNull, isNull);

      final second = await repo.settle(
          debtorId: 2,
          amount: 50000,
          account: CashAccount.cash,
          idempotencyKey: 'dup-key');
      expect(second.failureOrNull, isNull);
      expect(second.dataOrNull!.total, 50000);
      expect(second.dataOrNull!.payments, hasLength(1));

      // فقط یک بار کم شده.
      final credits = (await repo.getCredits(debtorId: 2)).dataOrNull!;
      expect(credits.single.remainingAmount, 100000);
    });
  });
}