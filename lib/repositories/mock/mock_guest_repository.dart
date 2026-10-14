import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/enums.dart';
import '../../models/guest.dart';
import '../guest_repository.dart';
import 'mock_database.dart';

/// پیاده‌سازی Mock مهمان‌نوازی روی همان [MockDatabase] که پرداخت میز در آن
/// مهمان می‌سازد. قواعد بک‌اند (گروه‌بندی بر اساس نام، لغو برگشت‌پذیر) اینجا
/// بازتولید می‌شود تا UI بدون سرور هم رفتار واقعی را ببیند.
class MockGuestRepository implements GuestRepository {
  MockGuestRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  static String _normalize(String name) => name.split(RegExp(r'\s+')).join(' ');

  @override
  Future<Result<List<GuestGroup>>> getGroups({String? query}) async {
    await _latency();
    final q = (query ?? '').trim().toLowerCase();
    final active = _db.guests.where((g) => g.isActive).toList();

    final byName = <String, List<Guest>>{};
    for (final g in active) {
      if (q.isNotEmpty && !g.name.toLowerCase().contains(q)) continue;
      byName.putIfAbsent(g.name, () => []).add(g);
    }

    final groups = <GuestGroup>[];
    byName.forEach((name, list) {
      var total = 0;
      DateTime? last;
      for (final g in list) {
        total += g.amount;
        if (last == null || g.createdAt.isAfter(last)) last = g.createdAt;
      }
      groups.add(GuestGroup(
        name: name,
        totalAmount: total,
        orderCount: list.length,
        lastAt: last,
      ));
    });
    groups.sort((a, b) {
      final byAmount = b.totalAmount.compareTo(a.totalAmount);
      return byAmount != 0 ? byAmount : a.name.compareTo(b.name);
    });
    return Success(List.unmodifiable(groups));
  }

  @override
  Future<Result<GuestSummary>> getSummary() async {
    await _latency();
    final active = _db.guests.where((g) => g.isActive);
    var total = 0;
    var count = 0;
    for (final g in active) {
      total += g.amount;
      count++;
    }
    return Success(GuestSummary(
      totalAmount: total,
      guestCount: count,
      orderCount: count,
    ));
  }

  @override
  Future<Result<List<Guest>>> getOrders(String name) async {
    await _latency();
    final clean = _normalize(name).trim();
    if (clean.isEmpty) {
      return Failure(AppFailure.validation('نام مهمان را مشخص کنید.'));
    }
    final list = _db.guests.where((g) => g.isActive && g.name == clean).toList()
      ..sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return Success(List.unmodifiable(list));
  }

  @override
  Future<Result<Guest>> rename(int id, String name) async {
    await _latency();
    final clean = _normalize(name).trim();
    if (clean.isEmpty) {
      return Failure(AppFailure.validation('نام مهمان را وارد کنید.'));
    }
    if (clean.length > 80) {
      return Failure(AppFailure.validation('نام مهمان حداکثر ۸۰ حرف باشد.'));
    }
    final guest = _db.guestById(id);
    if (guest == null) return Failure(AppFailure.notFound());
    if (!guest.isActive) {
      return Failure(AppFailure.conflict('مهمان لغوشده قابل ویرایش نیست.'));
    }
    final updated = Guest(
      id: guest.id,
      name: clean,
      amount: guest.amount,
      status: guest.status,
      orderId: guest.orderId,
      orderNumber: guest.orderNumber,
      tableNumber: guest.tableNumber,
      createdAt: guest.createdAt,
      cancelledAt: guest.cancelledAt,
    );
    _db.replaceGuest(updated);
    return Success(updated);
  }

  @override
  Future<Result<Guest>> cancel(int id) async {
    await _latency();
    final guest = _db.guestById(id);
    if (guest == null) return Failure(AppFailure.notFound());
    if (!guest.isActive) return Success(guest);

    final orderIndex = _db.orders.indexWhere((o) => o.id == guest.orderId);
    if (orderIndex == -1) return Failure(AppFailure.notFound());

    final now = DateTime.now();
    final order = _db.orders[orderIndex];
    // برگشت کامل (مثل بک‌اند): سفارش لغو/برگشت‌خورده می‌شود، رکورد مهمان
    // حذف نمی‌شود ولی غیرفعال می‌گردد.
    _db.orders[orderIndex] = order.copyWith(
      status: OrderStatus.cancelled,
      paymentStatus: PaymentStatus.refunded,
      clearPaymentMethod: true,
      clearPaidAt: true,
      guestStatus: GuestStatus.cancelled,
    );
    final cancelled = Guest(
      id: guest.id,
      name: guest.name,
      amount: guest.amount,
      status: GuestStatus.cancelled,
      orderId: guest.orderId,
      orderNumber: guest.orderNumber,
      tableNumber: guest.tableNumber,
      createdAt: guest.createdAt,
      cancelledAt: now,
    );
    _db.replaceGuest(cancelled);
    return Success(cancelled);
  }
}
