// رگرسیون: آیتمِ سفارش بدون محصول کاتالوگ.
//
// بک‌اند `OrderItem.product` با `null=True, on_delete=SET_NULL` تعریف شده است
// (orders/models.py)، پس حذفِ محصولی که در سفارش‌های گذشته بوده، یا داده‌های
// قدیمی، باعث می‌شود `product_id` برابر null برگردد. `serializers.item_dict`
// هم دقیقاً همین null را می‌فرستد.
//
// پیش از این اصلاح، `product_id as int` در OrderItem.fromJson خطای TypeError
// می‌داد؛ چون ApiClient خطای parse را می‌گیرد و به FailureType.unknown تبدیل
// می‌کند، صفحات میز، داشبورد و سفارش‌ها همگی «خطای غیرمنتظره‌ای رخ داد» نشان
// می‌دادند. قرارداد بک‌اند برای گزارش‌ها همین حالت را با `or 0` پوشش می‌دهد
// (core/accounting_api.py).
import 'package:cafe_book_admin/models/dashboard_summary.dart';
import 'package:cafe_book_admin/models/order.dart';
import 'package:cafe_book_admin/models/table_overview.dart';
import 'package:flutter_test/flutter_test.dart';

/// یک آیتم واقعی که بک‌اند با product_id=null برگردانده است.
Map<String, dynamic> orphanItem() => {
      'product_id': null,
      'product_name': 'قهوه تخصصی',
      'quantity': 2,
      'unit_price': 95000,
      'note': null,
    };

Map<String, dynamic> orphanOrder() => {
      'id': '264d2357-057e-48e3-abec-d6ffafcee69d',
      'number': 1012,
      'source': 'customer',
      'table': {'id': 1, 'number': 12},
      'status': 'new',
      'payment_status': 'unpaid',
      'payment_method': null,
      'customer_note': null,
      'items': [orphanItem()],
      'total': 190000,
      'created_at': '2026-10-02T12:49:31.142643+00:00',
      'paid_at': null,
      'bar_printed_at': null,
      'version': 1,
      'session_id': '54cc4bf7-d4fb-4725-9410-a0141d1de25c',
      'updated_at': '2026-10-02T12:49:31.142702+00:00',
    };

void main() {
  group('OrderItem tolerates a null product_id', () {
    test('reads product_id as 0 instead of throwing', () {
      final item = OrderItem.fromJson(orphanItem());
      expect(item.productId, 0);
      expect(item.productName, 'قهوه تخصصی');
      expect(item.lineTotal, 190000);
    });

    test('keeps a real product_id untouched', () {
      final item = OrderItem.fromJson({
        'product_id': 11,
        'product_name': 'لاته',
        'quantity': 1,
        'unit_price': 95000,
        'note': null,
      });
      expect(item.productId, 11);
    });
  });

  group('orders page parses an order containing a null product_id', () {
    final order = Order.fromJson(orphanOrder());

    test('order still loads', () {
      expect(order.number, 1012);
      expect(order.items, hasLength(1));
      expect(order.total, 190000);
    });
  });

  group('tables page parses open_orders containing a null product_id', () {
    final overview = TableOverview.fromJson({
      'table': {'id': 1, 'number': 12, 'status': 'active'},
      'active_session': {
        'id': '54cc4bf7-d4fb-4725-9410-a0141d1de25c',
        'table_id': 1,
        'table_number': 12,
        'entered_at': '2026-10-02T12:49:31.142643+00:00',
        'exited_at': null,
      },
      'last_session': null,
      'open_orders': [orphanOrder()],
      'waiter_call': null,
    });

    test('table overview still loads', () {
      expect(overview.hasOpenOrders, isTrue);
      expect(overview.currentAmount, 190000);
    });
  });

  group('dashboard page parses recent_orders containing a null product_id', () {
    final summary = DashboardSummary.fromJson({
      'today_sales': 0,
      'month_sales': 0,
      'today_expenses': 850000,
      'month_expenses': 850000,
      'today_order_count': 1,
      'tables': [
        {'id': 1, 'number': 12, 'status': 'active'},
      ],
      'low_stock_items': [
        {
          'id': 5,
          'name': 'پودر کاکائو',
          'unit': 'g',
          'current_stock': 0.0,
          'min_stock': 500.0,
          'unit_cost': 300.0,
          'description': null,
        },
      ],
      'recent_orders': [orphanOrder()],
      'recent_expenses': [],
    });

    test('dashboard summary still loads', () {
      expect(summary.todayOrderCount, 1);
      expect(summary.recentOrders, hasLength(1));
      expect(summary.recentOrders.first.items.first.productId, 0);
      expect(summary.lowStockItems.single.currentStock, 0.0);
    });
  });
}