import 'dart:math';

import '../../core/errors/app_failure.dart';
import '../../models/cafe_table.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../models/inventory_item.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/table_session.dart';
import '../../models/table_session.dart';

/// دیتابیس درون‌حافظه‌ای برای توسعه‌ی UI تا زمانی که Django آماده نیست.
/// همه‌ی Mock Repositoryها از یک نمونه‌ی مشترک استفاده می‌کنند تا داده‌ها با هم سازگار باشند.
/// داده‌ها نسبت به «اکنون» ساخته می‌شوند، بنابراین داشبورد همیشه امروز و این ماه را پر نشان می‌دهد.
class MockDatabase {
  MockDatabase._({
    required this.tables,
    required this.orders,
    required this.expenses,
    required this.inventoryItems,
    required this.sessions,
    required this.lastOrderNumber,
    required this.lastSessionNumber,
  });

  final List<CafeTable> tables;
  final List<Order> orders;
  final List<Expense> expenses;
  final List<InventoryItem> inventoryItems;
  final List<TableSession> sessions;
  int lastOrderNumber;
  int lastSessionNumber;

  static const catalog = <(int, String, int)>[
    (1, 'لاته', 95000),
    (2, 'کاپوچینو', 90000),
    (3, 'اسپرسو', 65000),
    (4, 'چای ماسالا', 70000),
    (5, 'چای سیاه', 45000),
    (6, 'آیس‌آمریکانو', 85000),
    (7, 'چیزکیک', 120000),
    (8, 'کیک شکلاتی', 110000),
    (9, 'ساندویچ مرغ', 145000),
    (10, 'تیرامیسو', 130000),
    (11, 'لیموناد', 75000),
  ];

  static const _methods = [
    PaymentMethod.cash,
    PaymentMethod.cardReader,
    PaymentMethod.cardTransfer,
  ];

  // ---------- کمک‌های دسترسی (در Backend واقعی همان کوئری‌های دیتابیس‌اند) ----------

  int nextOrderNumber() => ++lastOrderNumber;
  String nextSessionId() => 'mock-session-${++lastSessionNumber}';

  CafeTable tableById(int id) {
    for (final t in tables) {
      if (t.id == id) return t;
    }
    throw AppFailure.notFound();
  }

  void replaceTable(CafeTable table) {
    final i = tables.indexWhere((t) => t.id == table.id);
    if (i >= 0) tables[i] = table;
  }

  TableSession? activeSessionFor(int tableId) {
    for (final s in sessions.reversed) {
      if (s.tableId == tableId && s.isActive) return s;
    }
    return null;
  }

  TableSession? sessionById(String id) {
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  void replaceSession(TableSession session) {
    final i = sessions.indexWhere((s) => s.id == session.id);
    if (i >= 0) sessions[i] = session;
  }

  /// آخرین Session بسته‌شده‌ی یک میز.
  TableSession? lastClosedSessionFor(int tableId) {
    TableSession? best;
    for (final s in sessions) {
      if (s.tableId != tableId || s.isActive) continue;
      if (best == null || s.exitedAt!.isAfter(best.exitedAt!)) best = s;
    }
    return best;
  }

  Order? openOrderForSession(String sessionId) {
    for (final o in orders.reversed) {
      if (o.sessionId == sessionId && o.status.isOpen) return o;
    }
    return null;
  }

  void replaceOrder(Order order) {
    final i = orders.indexWhere((o) => o.id == order.id);
    if (i >= 0) orders[i] = order;
  }

  // ---------- داده‌ی اولیه ----------

  factory MockDatabase.seeded({DateTime? now}) {
    final clock = now ?? DateTime.now();
    final rnd = Random(7);
    final todayStart = DateTime(clock.year, clock.month, clock.day);
    final orders = <Order>[];
    final sessions = <TableSession>[];
    var counter = 1000;

    Order build({
      required DateTime createdAt,
      required OrderStatus status,
      required int table,
      OrderSource source = OrderSource.admin,
      PaymentMethod? method,
      DateTime? paidAt,
    }) {
      final lines = <OrderItem>[];
      final used = <int>{};
      final wanted = 1 + rnd.nextInt(3);
      while (lines.length < wanted) {
        final p = catalog[rnd.nextInt(catalog.length)];
        if (!used.add(p.$1)) continue;
        lines.add(OrderItem(
          productId: p.$1,
          productName: p.$2,
          quantity: 1 + rnd.nextInt(3),
          unitPrice: p.$3,
        ));
      }
      counter++;
      final isPaid = status == OrderStatus.paid;
      final sessionId = 'mock-session-$counter';
      // هر سفارش یک Session دارد: ورود = زمان اولین سفارش، خروج = زمان پرداخت.
      sessions.add(TableSession(
        id: sessionId,
        tableId: table,
        tableNumber: table,
        enteredAt: createdAt,
        exitedAt: isPaid ? paidAt : null,
      ));
      return Order(
        id: 'mock-order-$counter',
        number: counter,
        source: source,
        tableId: table,
        tableNumber: table,
        sessionId: sessionId,
        status: status,
        paymentStatus: isPaid ? PaymentStatus.paid : PaymentStatus.unpaid,
        paymentMethod: isPaid ? method : null,
        items: lines,
        createdAt: createdAt,
        paidAt: paidAt,
      );
    }

    // ۱۰ روز گذشته: سفارش‌های پرداخت‌شده
    for (var daysAgo = 10; daysAgo >= 1; daysAgo--) {
      final day =
          DateTime(todayStart.year, todayStart.month, todayStart.day - daysAgo);
      final count = 9 + rnd.nextInt(6);
      for (var i = 0; i < count; i++) {
        final created = day.add(
            Duration(hours: 10 + rnd.nextInt(12), minutes: rnd.nextInt(60)));
        orders.add(build(
          createdAt: created,
          status: OrderStatus.paid,
          table: 1 + rnd.nextInt(10),
          method: _methods[rnd.nextInt(_methods.length)],
          paidAt: created.add(Duration(minutes: 30 + rnd.nextInt(60))),
        ));
      }
    }

    // امروز: ۵ سفارش پرداخت‌شده که زمان‌شان تا «اکنون» پخش شده است
    final minutesToday = max(1, clock.difference(todayStart).inMinutes);
    for (var i = 0; i < 5; i++) {
      final created = todayStart
          .add(Duration(minutes: (minutesToday * (i + 1) / 7).floor()));
      final paid = created.add(const Duration(minutes: 30));
      orders.add(build(
        createdAt: created,
        status: OrderStatus.paid,
        table: 1 + rnd.nextInt(10),
        method: _methods[rnd.nextInt(_methods.length)],
        paidAt: paid.isAfter(clock) ? clock : paid,
      ));
    }

    // امروز: سه سفارش باز (یکی از بخش مشتری برای تست جریان دریافت سفارش)
    orders.add(build(
      createdAt: clock.subtract(const Duration(minutes: 48)),
      status: OrderStatus.delivered,
      table: 2,
    ));
    orders.add(build(
      createdAt: clock.subtract(const Duration(minutes: 22)),
      status: OrderStatus.preparing,
      table: 5,
    ));
    orders.add(build(
      createdAt: clock.subtract(const Duration(minutes: 9)),
      status: OrderStatus.newOrder,
      table: 7,
      source: OrderSource.customer,
    ));

    DateTime at(int daysAgo, [int hour = 12]) => DateTime(
        todayStart.year, todayStart.month, todayStart.day - daysAgo, hour);

    final expenses = <Expense>[
      Expense(
          id: 1,
          title: 'خرید شیر',
          amount: 850000,
          category: ExpenseCategory.rawMaterials,
          date: at(0, 9)),
      Expense(
          id: 2,
          title: 'لیوان کاغذی و دستمال',
          amount: 320000,
          category: ExpenseCategory.supplies,
          date: at(0, 10)),
      Expense(
          id: 3,
          title: 'تعمیر دستگاه اسپرسو',
          amount: 1800000,
          category: ExpenseCategory.repairs,
          date: at(1)),
      Expense(
          id: 4,
          title: 'اینترنت ماهانه',
          amount: 450000,
          category: ExpenseCategory.internet,
          date: at(2)),
      Expense(
          id: 5,
          title: 'قبض برق',
          amount: 1200000,
          category: ExpenseCategory.electricity,
          date: at(3)),
      Expense(
          id: 6,
          title: 'تبلیغات اینستاگرام',
          amount: 600000,
          category: ExpenseCategory.advertising,
          date: at(4)),
      Expense(
          id: 7,
          title: 'حقوق کارکنان',
          amount: 10000000,
          category: ExpenseCategory.salary,
          date: at(6)),
      Expense(
          id: 8,
          title: 'اجاره‌ی کافه',
          amount: 8000000,
          category: ExpenseCategory.rent,
          date: at(8)),
    ];

    const tableStatuses = {
      2: TableStatus.active,
      5: TableStatus.active,
      7: TableStatus.active,
      9: TableStatus.reserved,
    };
    final tables = [
      for (var n = 1; n <= 10; n++)
        CafeTable(
            id: n, number: n, status: tableStatuses[n] ?? TableStatus.empty),
    ];

    final inventory = <InventoryItem>[
      const InventoryItem(
          id: 1,
          name: 'دانه‌ی قهوه اسپرسو',
          unit: BaseUnit.gram,
          currentStock: 4200,
          minStock: 2000,
          unitCost: 900),
      const InventoryItem(
          id: 2,
          name: 'شیر',
          unit: BaseUnit.milliliter,
          currentStock: 3500,
          minStock: 10000,
          unitCost: 55),
      const InventoryItem(
          id: 3,
          name: 'شکر',
          unit: BaseUnit.gram,
          currentStock: 6000,
          minStock: 2000,
          unitCost: 40),
      const InventoryItem(
          id: 4,
          name: 'سیروپ کارامل',
          unit: BaseUnit.milliliter,
          currentStock: 300,
          minStock: 500,
          unitCost: 120),
      const InventoryItem(
          id: 5,
          name: 'پودر کاکائو',
          unit: BaseUnit.gram,
          currentStock: 0,
          minStock: 500,
          unitCost: 300),
      const InventoryItem(
          id: 6,
          name: 'چای سیاه',
          unit: BaseUnit.gram,
          currentStock: 2500,
          minStock: 1000,
          unitCost: 220),
      const InventoryItem(
          id: 7,
          name: 'لیوان کاغذی',
          unit: BaseUnit.piece,
          currentStock: 250,
          minStock: 100,
          unitCost: 2500),
      const InventoryItem(
          id: 8,
          name: 'خامه',
          unit: BaseUnit.milliliter,
          currentStock: 4000,
          minStock: 1500,
          unitCost: 150),
    ];

    const categoryNames = ['قهوه', 'چای', 'نوشیدنی سرد', 'کیک', 'غذا', 'دسر'];
    final categories = [
      for (var i = 0; i < categoryNames.length; i++)
        ProductCategory(id: i + 1, name: categoryNames[i]),
    ];
    // شناسه‌ی محصول → شناسه‌ی دسته (۱ قهوه، ۲ چای، ۳ نوشیدنی سرد، ۴ کیک، ۵ غذا، ۶ دسر)
    const productCategory = {
      1: 1,
      2: 1,
      3: 1,
      12: 1,
      4: 2,
      5: 2,
      6: 3,
      11: 3,
      7: 4,
      8: 4,
      9: 5,
      13: 5,
      10: 6,
      14: 6,
    };
    const descriptions = {
      1: 'اسپرسو دوبل با شیر بخارداده و فوم نرم',
      2: 'اسپرسو، شیر و فوم غلیظ',
      7: 'چیزکیک نیویورکی با سس توت‌فرنگی',
      10: 'تیرامیسوی ایتالیایی با قهوه و کاکائو',
    };
    final products = <Product>[
      for (final c in _catalog)
        Product(
          id: c.$1,
          name: c.$2,
          categoryId: productCategory[c.$1]!,
          price: c.$3,
          description: descriptions[c.$1],
        ),
      const Product(id: 12, name: 'موکا', categoryId: 1, price: 105000),
      const Product(
          id: 13,
          name: 'سالاد سزار',
          categoryId: 5,
          price: 135000,
          isActive: false),
      const Product(id: 14, name: 'براونی', categoryId: 6, price: 95000),
    ];

    return MockDatabase._(
      categories: categories,
      products: products,
      productSeq: 14,
      categorySeq: categoryNames.length,
      tables: tables,
      orders: orders,
      expenses: expenses,
      inventoryItems: inventory,
      sessions: sessions,
      lastOrderNumber: counter,
      lastSessionNumber: counter,
    );
  }
}
