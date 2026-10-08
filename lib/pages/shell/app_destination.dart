import 'package:flutter/material.dart';

/// بخش‌های اصلی برنامه، به ترتیب نمایش در Sidebar/Drawer.
/// [plannedStage] شماره‌ی مرحله‌ای است که صفحه‌ی واقعی آن پیاده‌سازی می‌شود.
enum AppDestination {
  dashboard('داشبورد', Icons.dashboard_outlined, Icons.dashboard, 2),
  tables('میزها', Icons.table_restaurant_outlined, Icons.table_restaurant, 3),
  orders('سفارش‌ها', Icons.receipt_long_outlined, Icons.receipt_long, 7),
  products('محصولات', Icons.local_cafe_outlined, Icons.local_cafe, 4),
  categories('دسته‌بندی‌ها', Icons.category_outlined, Icons.category, 4),
  inventory('انبار', Icons.inventory_2_outlined, Icons.inventory_2, 5),
  recipes('دستور مصرف', Icons.menu_book_outlined, Icons.menu_book, 6),
  purchases('خریدها', Icons.shopping_cart_outlined, Icons.shopping_cart, 5),
  waste('ضایعات', Icons.delete_outline, Icons.delete, 5),
  accounting('حسابداری', Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet, 10),
  expenses('هزینه‌ها', Icons.payments_outlined, Icons.payments, 10),
  receivables('نسیه‌ها', Icons.account_balance_outlined, Icons.account_balance,
      10),
  reports('گزارش‌ها', Icons.bar_chart_outlined, Icons.bar_chart, 11),
  settings('تنظیمات', Icons.settings_outlined, Icons.settings, 9);

  const AppDestination(
      this.label, this.icon, this.selectedIcon, this.plannedStage);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int plannedStage;
}
