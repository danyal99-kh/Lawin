// رفتار Mock مهمان‌نوازی: ثبت از مسیر پرداخت، گروه‌بندی بر اساس نام،
// تغییر نام و لغو برگشت‌پذیر — هماهنگ با قواعد بک‌اند.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:cafe_book_admin/repositories/mock/mock_guest_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_payment_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_table_repository.dart';
import 'package:flutter_test/flutter_test.dart';

int openTableIdOf(MockDatabase db) =>
    db.orders.firstWhere((o) => o.status.isOpen).tableId!;

void main() {
  late MockDatabase db;
  late MockGuestRepository guests;
  late MockPaymentRepository payments;

  setUp(() {
    db = MockDatabase.seeded();
    guests = MockGuestRepository(db);
    payments = MockPaymentRepository(db, MockTableRepository(db));
  });

  group('seeded data', () {
    test('groups are grouped by name and the summary matches', () async {
      final groups = (await guests.getGroups()).dataOrNull!;
      expect(groups, isNotEmpty);

      // «آقای رضایی» در seed دو بار آمده و در یک گروه جمع شده است.
      final rezae = groups.firstWhere((g) => g.name == 'آقای رضایی');
      expect(rezae.orderCount, 2);

      final summary = (await guests.getSummary()).dataOrNull!;
      final total = groups.fold<int>(0, (s, g) => s + g.totalAmount);
      expect(summary.totalAmount, total);
    });
  });

  group('registering a guest through payment', () {
    test('pay(method: guest) records a guest and does not collect money',
        () async {
      final tableId = openTableIdOf(db);
      final openOrders = db.orders
          .where((o) => o.tableId == tableId && o.status.isOpen)
          .toList();
      final guestsBefore = db.guests.length;

      final result = await payments.pay(tableId,
          method: PaymentMethod.guest, guestName: 'آقای مهمان');
      expect(result.failureOrNull, isNull);

      expect(db.guests.length, guestsBefore + openOrders.length);
      for (final o in openOrders) {
        final after = db.orders.firstWhere((x) => x.id == o.id);
        expect(after.paymentStatus, PaymentStatus.guest);
        expect(after.paymentMethod, PaymentMethod.guest);
        expect(after.guestName, 'آقای مهمان');
        expect(after.isGuest, isTrue);
      }

      final groups = (await guests.getGroups()).dataOrNull!;
      expect(groups.any((g) => g.name == 'آقای مهمان'), isTrue);
    });

    test('a guest payment without a name is rejected', () async {
      final tableId = openTableIdOf(db);
      final before = db.guests.length;
      final result = await payments.pay(tableId, method: PaymentMethod.guest);
      expect(result.failureOrNull!.type, FailureType.validation);
      expect(db.guests.length, before);
    });
  });

  group('rename', () {
    test('moves a guest to a new name group', () async {
      final guest = db.guests.firstWhere((g) => g.name == 'خانم موسوی');

      final result = await guests.rename(guest.id, 'خانم جدید');
      expect(result.failureOrNull, isNull);

      final groups = (await guests.getGroups()).dataOrNull!;
      expect(groups.any((g) => g.name == 'خانم جدید'), isTrue);
      expect(groups.any((g) => g.name == 'خانم موسوی'), isFalse);
    });

    test('an empty name is rejected', () async {
      final guest = db.guests.first;
      final result = await guests.rename(guest.id, '   ');
      expect(result.failureOrNull, isNotNull);
    });
  });

  group('cancel', () {
    test('cancels the guest and refunds/cancels its order', () async {
      final guest = db.guests.firstWhere((g) => g.isActive);
      final summaryBefore = (await guests.getSummary()).dataOrNull!.totalAmount;

      final result = await guests.cancel(guest.id);
      expect(result.failureOrNull, isNull);

      final record = db.guests.firstWhere((g) => g.id == guest.id);
      expect(record.status, GuestStatus.cancelled);
      expect(record.isActive, isFalse);
      expect(record.cancelledAt, isNotNull);

      final order = db.orders.firstWhere((o) => o.id == guest.orderId);
      expect(order.status, OrderStatus.cancelled);
      expect(order.paymentStatus, PaymentStatus.refunded);

      final summaryAfter = (await guests.getSummary()).dataOrNull!.totalAmount;
      expect(summaryAfter, summaryBefore - guest.amount);
    });

    test('an unknown guest is notFound', () async {
      final result = await guests.cancel(9999);
      expect(result.failureOrNull!.type, FailureType.notFound);
    });
  });

  group('getOrders', () {
    test('returns active records of one normalized name', () async {
      final list = (await guests.getOrders(' آقای   رضایی ')).dataOrNull!;
      expect(list, isNotEmpty);
      expect(list.every((g) => g.name == 'آقای رضایی'), isTrue);
      expect(list.every((g) => g.isActive), isTrue);
    });
  });
}
