import 'dart:async';

import 'package:cafe_book_admin/core/utils/persian_format.dart';
import 'package:cafe_book_admin/pages/accounting/accounting_page.dart';
import 'package:cafe_book_admin/pages/expenses/expenses_page.dart';
import 'package:cafe_book_admin/pages/inventory/inventory_page.dart';
import 'package:cafe_book_admin/pages/orders/orders_page.dart';
import 'package:cafe_book_admin/pages/purchases/purchases_page.dart';
import 'package:cafe_book_admin/pages/recipes/recipes_page.dart';
import 'package:cafe_book_admin/pages/reports/reports_page.dart';
import 'package:cafe_book_admin/pages/settings/settings_page.dart';
import 'package:cafe_book_admin/pages/waste/waste_page.dart';
import 'package:cafe_book_admin/providers/dashboard_provider.dart';
import 'package:cafe_book_admin/providers/incoming_orders_provider.dart';
import 'package:cafe_book_admin/providers/order_provider.dart';
import 'package:cafe_book_admin/providers/table_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
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
/// بارگذاری اولیه‌ی Providerهایی که به توکن ورود نیاز دارند اینجا،
/// بعد از رندر اول (AuthGate از قبل عبور کرده)، انجام می‌شود.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();

  static Widget _pageFor(AppDestination d) => switch (d) {
        AppDestination.dashboard => const DashboardPage(),
        AppDestination.tables => const TablesPage(),
        AppDestination.orders => const OrdersPage(),
        AppDestination.products => const ProductsPage(),
        AppDestination.categories => const CategoriesPage(),
        AppDestination.inventory => const InventoryPage(),
        AppDestination.recipes => const RecipesPage(),
        AppDestination.purchases => const PurchasesPage(),
        AppDestination.waste => const WastePage(),
        AppDestination.expenses => const ExpensesPage(),
        AppDestination.accounting => const AccountingPage(),
        AppDestination.reports => const ReportsPage(),
        AppDestination.settings => const SettingsPage(),
        _ => PlaceholderPage(destination: d),
      };
}

class _AppShellState extends State<AppShell> {
  RealtimeSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load();
      context.read<TableProvider>().load();
      context.read<OrderProvider>().load();
      if (!AppConfig.useMock) {
        _sync = context.read<RealtimeSync>()..start();
      }
    });
  }

  @override
  void dispose() {
    _sync?.stop(); // AppShell با logout از درخت حذف می‌شود
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current =
        context.select<NavigationProvider, AppDestination>((n) => n.current);
    final width = MediaQuery.sizeOf(context).width;
    final page =
        KeyedSubtree(key: ValueKey(current), child: AppShell._pageFor(current));

    final body = width >= Breakpoints.mobileMax
        ? Scaffold(
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
          )
        : _MobileShell(current: current, page: page);

    return AppConfig.useMock ? body : NewOrderListener(child: body);
  }
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

/// وقتی سفارش جدیدی از مشتری می‌رسد (رویداد order_created با source=customer)،
/// هشدار صوتی + SnackBar نشان می‌دهد.
class NewOrderListener extends StatefulWidget {
  const NewOrderListener({super.key, required this.child});
  final Widget child;

  @override
  State<NewOrderListener> createState() => _NewOrderListenerState();
}

class _NewOrderListenerState extends State<NewOrderListener> {
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    final sync = context.read<RealtimeSync>();
    _sub = sync.newCustomerOrder.listen((number) {
      if (!mounted) return;
      SystemSound.play(SystemSoundType.alert);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('سفارش جدید از مشتری: ${PersianFormat.digits(number)}'),
        action: SnackBarAction(
          label: 'مشاهده',
          onPressed: () {
            context.read<NavigationProvider>().select(AppDestination.orders);
            sync.markSeen();
          },
        ),
      ));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
