import 'package:cafe_book_admin/pages/inventory/inventory_page.dart';
import 'package:cafe_book_admin/pages/orders/orders_page.dart';
import 'package:cafe_book_admin/pages/purchases/purchases_page.dart';
import 'package:cafe_book_admin/pages/recipes/recipes_page.dart';
import 'package:cafe_book_admin/pages/waste/waste_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../../responsive/breakpoints.dart';
import '../categories/categories_page.dart';
import '../dashboard/dashboard_page.dart';
import '../products/products_page.dart';
import '../tables/tables_page.dart';
import 'app_destination.dart';
import 'app_drawer.dart';
import 'app_sidebar.dart';
import 'placeholder_page.dart';
import 'shell_header.dart';

/// قاب اصلی برنامه.
///
/// - عرض ≥ ۱۲۸۰: Sidebar کامل (سمت راست) + Header
/// - ۶۰۰ ≤ عرض < ۱۲۸۰: Sidebar فشرده (آیکن) + Header
/// - عرض < ۶۰۰ (موبایل): AppBar + Drawer + Bottom Navigation
///
/// صفحه‌ها Scaffold/AppBar نمی‌سازند؛ فقط محتوا را برمی‌گردانند.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final current =
        context.select<NavigationProvider, AppDestination>((n) => n.current);
    final width = MediaQuery.sizeOf(context).width;
    final page = KeyedSubtree(key: ValueKey(current), child: _pageFor(current));

    if (width >= Breakpoints.mobileMax) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(compact: width < Breakpoints.sidebarExpandedMin),
            Expanded(
              child: Column(
                children: [
                  ShellHeader(title: current.label),
                  Expanded(child: page),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _MobileShell(current: current, page: page);
  }

  static Widget _pageFor(AppDestination d) => switch (d) {
        AppDestination.dashboard => const DashboardPage(),
        AppDestination.tables => const TablesPage(),
        AppDestination.orders => const OrdersPage(),
        AppDestination.products => const ProductsPage(),
        AppDestination.categories => const CategoriesPage(),
        _ => PlaceholderPage(destination: d),
      };
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.current, required this.page});

  final AppDestination current;
  final Widget page;

  static const _bottom = [
    AppDestination.dashboard,
    AppDestination.tables,
    AppDestination.orders,
  ];

  @override
  Widget build(BuildContext context) {
    final bottomIndex = _bottom.indexOf(current);
    return PopScope(
      // دکمه‌ی بازگشت اندروید: از هر بخش به داشبورد، و از داشبورد خروج.
      canPop: current == AppDestination.dashboard,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<NavigationProvider>().select(AppDestination.dashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(current.label)),
        drawer: const AppDrawer(),
        body: page,
        bottomNavigationBar: Builder(
          builder: (ctx) => NavigationBar(
            selectedIndex: bottomIndex == -1 ? _bottom.length : bottomIndex,
            onDestinationSelected: (i) {
              if (i < _bottom.length) {
                ctx.read<NavigationProvider>().select(_bottom[i]);
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
            destinations: [
              for (final d in _bottom)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
              const NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu),
                label: 'بیشتر',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
