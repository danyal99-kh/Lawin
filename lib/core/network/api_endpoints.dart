/// مسیرهای API جنگو. قرارداد کامل در docs/API_CONTRACT.md آمده است.
abstract final class ApiEndpoints {
  static const String _v1 = '/api/v1';

  // Auth
  static const String login = '$_v1/auth/login/';
  static const String refresh = '$_v1/auth/refresh/';

  /// خروج کامل: توکن فعلی سمت سرور باطل می‌شود.
  static const String logout = '$_v1/auth/logout/';

  // Security (رمز امنیتی مالی)
  static const String securityVerify = '$_v1/security/verify/';
  static const String securityPassword = '$_v1/security/password/';

  // Orders (شامل سفارش‌هایی که از بخش مشتری ثبت می‌شوند)
  static const String orders = '$_v1/orders/';
  static String order(String id) => '$_v1/orders/$id/';
  static String orderStatus(String id) => '$_v1/orders/$id/status/';
  static String orderPay(String id) => '$_v1/orders/$id/pay/';

  /// بازگشت کل مبلغ سفارش (فقط refund کامل پشتیبانی می‌شود) و برگرداندن
  /// موجودی مصرف‌شده به انبار.
  static String orderRefund(String id) => '$_v1/orders/$id/refund/';

  /// دریافت افزایشی: فقط سفارش‌های ایجاد/تغییرکرده پس از یک نشانگر (cursor).
  static const String ordersChanges = '$_v1/orders/changes/';

  // Dashboard
  static const String dashboardSummary = '$_v1/dashboard/summary/';

  /// وضعیت باز/بسته بودن کافه: GET وضعیت فعلی، POST با `action`
  /// برای باز/بسته کردن (فقط ادمین).
  static const String cafeStatus = '$_v1/cafe/status/';

  // Tables
  static const String tables = '$_v1/tables/';
  static String tableReserve(int id) => '$_v1/tables/$id/reserve/';
  static const String tableSessions = '$_v1/tables/sessions/';

  // Catalog
  static const String products = '$_v1/products/';
  static String product(int id) => '$_v1/products/$id/';
  static const String categories = '$_v1/categories/';
  static String category(int id) => '$_v1/categories/$id/';
  static String productRecipe(int id) => '$_v1/products/$id/recipe/';
  // Inventory
  static const String inventoryItems = '$_v1/inventory/items/';
  static String inventoryItem(int id) => '$_v1/inventory/items/$id/';
  static const String purchases = '$_v1/inventory/purchases/';
  static String purchase(int id) => '$_v1/inventory/purchases/$id/';
  static const String wastes = '$_v1/inventory/wastes/';
  static String waste(int id) => '$_v1/inventory/wastes/$id/';
  static const String recipes = '$_v1/recipes/';
  // Accounting
  static const String expenses = '$_v1/accounting/expenses/';
  static String expense(int id) => '$_v1/accounting/expenses/$id/';
  static const String transactions = '$_v1/accounting/transactions/';

  // Credit / Accounts Receivable (نسیه)
  /// فهرست نسیه‌ها: `?debtor=<id>&status=open` — قدیمی‌ترین اول.
  static const String credits = '$_v1/credits/';

  /// بدهکارها با جمع مانده‌شان (`?q=` جست‌وجوی نام).
  static const String creditDebtors = '$_v1/credits/debtors/';
  static String creditDebtor(int id) => '$_v1/credits/debtors/$id/';

  /// GET: وصول‌ها (`?debtor=<id>&credit=<id>`) — POST: ثبت تسویه.
  static const String creditPayments = '$_v1/credits/payments/';

  /// بازرسی یکپارچگی دفتر با واقعیت کسب‌وکار. `ok=false` یعنی دفتر با سفارش‌ها
  /// یا موجودی انبار نمی‌خواند و باید بررسی شود.
  static const String accountingVerify = '$_v1/accounting/verify/';

  // Reports
  static const String reports = '$_v1/reports/';
  static const String inventoryReport = '$_v1/reports/inventory/';
  static const String paymentMethodsReport = '$_v1/reports/payment-methods/';
  static const String wasteReport = '$_v1/reports/waste/';
  static const String purchasesReport = '$_v1/reports/purchases/';

  static String orderBarPrinted(String id) => '$_v1/orders/$id/bar-printed/';
  static const String settings = '$_v1/settings/';
  static const String welcomeSettings = '$_v1/settings/welcome/';
  static const String waiterCalls = '$_v1/waiter-calls/';
  static String waiterAck(String id) => '$_v1/waiter-calls/$id/acknowledge/';
  static String waiterComplete(String id) => '$_v1/waiter-calls/$id/complete/';
  static String tablePay(int id) => '$_v1/tables/$id/pay/';
}
