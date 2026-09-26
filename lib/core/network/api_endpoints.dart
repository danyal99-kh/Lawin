/// مسیرهای API جنگو. قرارداد کامل در docs/API_CONTRACT.md آمده است.
abstract final class ApiEndpoints {
  static const String _v1 = '/api/v1';

  // Auth
  static const String login = '$_v1/auth/login/';
  static const String refresh = '$_v1/auth/refresh/';

  // Orders (شامل سفارش‌هایی که از بخش مشتری ثبت می‌شوند)
  static const String orders = '$_v1/orders/';
  static String order(String id) => '$_v1/orders/$id/';
  static String orderStatus(String id) => '$_v1/orders/$id/status/';
  static String orderPay(String id) => '$_v1/orders/$id/pay/';

  /// دریافت افزایشی: فقط سفارش‌های ایجاد/تغییرکرده پس از یک نشانگر (cursor).
  static const String ordersChanges = '$_v1/orders/changes/';

  // Dashboard
  static const String dashboardSummary = '$_v1/dashboard/summary/';

  // Tables
  static const String tables = '$_v1/tables/';
  static String tableReserve(int id) => '$_v1/tables/$id/reserve/';
  static const String tableSessions = '$_v1/tables/sessions/';

  // Catalog
  static const String products = '$_v1/products/';
  static String product(int id) => '$_v1/products/$id/';
  static const String categories = '$_v1/categories/';
  static String category(int id) => '$_v1/categories/$id/';

  // Inventory
  static const String inventoryItems = '$_v1/inventory/items/';
  static const String purchases = '$_v1/inventory/purchases/';
  static const String wastes = '$_v1/inventory/wastes/';

  // Accounting
  static const String expenses = '$_v1/accounting/expenses/';
  static const String transactions = '$_v1/accounting/transactions/';
  static const String reports = '$_v1/reports/';
}