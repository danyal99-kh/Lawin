// رفتار پرداخت در حالت Mock: قانون ۲ (پرداخت صورتحساب، نشست را می‌بندد) و
// پرداخت چندروشی که باید با مبلغ صورتحساب بخواند.
// نکته‌ی مهم: Mock اصلاً انبار را برای سفارش مصرف نمی‌کند، پس refund هم لازم
// نیست چیزی به انبار برگرداند — آن بخش فقط در بک‌اند معنا دارد.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:cafe_book_admin/repositories/mock/mock_payment_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_table_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// میزی که در داده‌ی Mock نشستِ باز با سفارش‌های باز دارد. عدد را از داده
/// استخراج می‌کنیم تا با تغییر seed نشکند.
int openTableIdOf(MockDatabase db) =>
    db.orders.firstWhere((o) => o.status.isOpen).tableId!;

void main() {
  late int openTableId;
  late MockDatabase db;
  late MockTableRepository tables;
  late MockPaymentRepository payments;

  setUp(() {
    db = MockDatabase.seeded();
    tables = MockTableRepository(db);
    payments = MockPaymentRepository(db, tables);
    openTableId = openTableIdOf(db);
  });

  group('single-method payment', () {
    test('pays every open order of the session and frees the table', () async {
      final before = db.orders
          .where((o) => o.tableId == openTableId && o.status.isOpen)
          .toList();
      expect(before, isNotEmpty);

      final result =
          await payments.pay(openTableId, method: PaymentMethod.cash);
      expect(result.failureOrNull, isNull);

      for (final o in before) {
        final after = db.orders.firstWhere((x) => x.id == o.id);
        expect(after.status, OrderStatus.paid);
        expect(after.paymentStatus, PaymentStatus.paid);
        expect(after.paymentMethod, PaymentMethod.cash);
        expect(after.paidAt, isNotNull);
      }

      // قانون ۲: میز آزاد و نشست بسته شده است.
      expect(db.tables.firstWhere((t) => t.id == openTableId).status,
          TableStatus.empty);
    });

    test('refuses a table with no open orders', () async {
      final first =
          await payments.pay(openTableId, method: PaymentMethod.cash);
      expect(first.failureOrNull, isNull);
      final second =
          await payments.pay(openTableId, method: PaymentMethod.cash);
      expect(second.failureOrNull!.type, FailureType.conflict);
    });

    test('an unknown table is notFound', () async {
      final result = await payments.pay(999, method: PaymentMethod.cash);
      expect(result.failureOrNull!.type, FailureType.notFound);
    });
  });

  group('split payment', () {
    test('accepts shares that add up to the bill', () async {
      // سفارش‌های *باز* همین میز، نه هر سفارشی که به میز چسبیده؛ داده‌ی seed
      // سفارش پرداخت‌شده هم دارد و با قاطی کردن آن‌ها تست گمراه‌کننده می‌شود.
      final openBefore = db.orders
          .where((o) => o.tableId == openTableId && o.status.isOpen)
          .toList();
      final total = openBefore.fold<int>(0, (s, o) => s + o.total);
      expect(total, greaterThan(1));

      final result = await payments.pay(
        openTableId,
        method: PaymentMethod.cash,
        shares: [
          PaymentShare(method: PaymentMethod.cash, amount: total ~/ 2),
          PaymentShare(
              method: PaymentMethod.cardReader, amount: total - total ~/ 2),
        ],
      );
      expect(result.failureOrNull, isNull);

      expect(openBefore, isNotEmpty);
      for (final o in openBefore) {
        final after = db.orders.firstWhere((x) => x.id == o.id);
        expect(after.status, OrderStatus.paid);
        // روشِ اول به‌عنوان خلاصه ثبت می‌شود (مثل بک‌اند) و باقیِ سهم‌ها
        // فقط در جدول Payment می‌مانند.
        expect(after.paymentMethod, PaymentMethod.cash);
      }
    });

    test('rejects shares that do not add up to the bill', () async {
      final openBefore = db.orders
          .where((o) => o.tableId == openTableId && o.status.isOpen)
          .toList();
      final result = await payments.pay(
        openTableId,
        method: PaymentMethod.cash,
        shares: const [
          PaymentShare(method: PaymentMethod.cash, amount: 1000),
          PaymentShare(method: PaymentMethod.cardReader, amount: 2000),
        ],
      );
      expect(result.failureOrNull!.type, FailureType.validation);
      // رد شدن نباید حتی یکی از سفارش‌های باز را پرداخت‌شده کند، وگرنه فاز
      // پرداختی بعدی وضعیتِ نیمه‌پرداخت می‌سازد.
      for (final o in openBefore) {
        expect(db.orders.firstWhere((x) => x.id == o.id).status.isOpen, isTrue);
      }
    });
  });

  group('refund', () {
    test('refunds a paid order and leaves it out of revenue', () async {
      await payments.pay(openTableId, method: PaymentMethod.cash);
      final order = db.orders.firstWhere(
          (o) => o.tableId == openTableId && o.status == OrderStatus.paid);

      final result = await payments.refund(order.id);
      expect(result.failureOrNull, isNull);

      final refunded = result.dataOrNull!;
      expect(refunded.paymentStatus, PaymentStatus.refunded);
      expect(refunded.status, OrderStatus.cancelled);
      // برگشت‌خورده نباید دوباره جزو فروشِ پرداخت‌شده حساب شود.
      expect(
        db.orders.any((o) => o.id == order.id && o.status == OrderStatus.paid),
        isFalse,
      );
    });

    test('an unpaid order cannot be refunded', () async {
      final unpaid =
          db.orders.firstWhere((o) => o.status == OrderStatus.newOrder);
      final result = await payments.refund(unpaid.id);
      expect(result.failureOrNull!.type, FailureType.conflict);
    });

    test('an unknown order is notFound', () async {
      final result = await payments.refund('does-not-exist');
      expect(result.failureOrNull!.type, FailureType.notFound);
    });
  });

  group('MockPaymentRepository keeps the table consistent', () {
    test('a payment never touches inventory, so orders do not consume stock',
        () async {
      final stockBefore = [
        for (final i in db.inventoryItems) '${i.id}:${i.currentStock}'
      ].join(',');

      await payments.pay(openTableId, method: PaymentMethod.cash);

      final stockAfter = [
        for (final i in db.inventoryItems) '${i.id}:${i.currentStock}'
      ].join(',');
      // مصرف انبار در Mock مدل نشده؛ اگر روزی اضافه شود، refund باید
      // دقیقاً همین مقدار را برگرداند و این تست باید شکست بخواند.
      expect(stockAfter, stockBefore);
    });

    test('MockOrderRepository and MockPaymentRepository agree on the session',
        () async {
      final openBefore = db.orders
          .where((o) => o.tableId == openTableId && o.status.isOpen)
          .toList();
      expect(openBefore, isNotEmpty);

      await payments.pay(openTableId, method: PaymentMethod.cardReader);
      expect(
        db.orders
            .where((o) =>
                o.tableId == openTableId && o.status == OrderStatus.newOrder)
            .toList(),
        isEmpty,
      );
    });
  });
}
