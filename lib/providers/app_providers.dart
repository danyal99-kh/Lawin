import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/providers/accounting_provider.dart';
import 'package:cafe_book_admin/providers/auth_provider.dart';
import 'package:cafe_book_admin/providers/dashboard_provider.dart';
import 'package:cafe_book_admin/providers/expense_provider.dart';
import 'package:cafe_book_admin/providers/incoming_orders_provider.dart';
import 'package:cafe_book_admin/providers/inventory_provider.dart';
import 'package:cafe_book_admin/providers/order_provider.dart';
import 'package:cafe_book_admin/providers/purchase_provider.dart';
import 'package:cafe_book_admin/providers/recipe_provider.dart';
import 'package:cafe_book_admin/providers/report_provider.dart';
import 'package:cafe_book_admin/providers/settings_provider.dart';
import 'package:cafe_book_admin/providers/waiter_call_provider.dart';
import 'package:cafe_book_admin/providers/waste_provider.dart';
import 'package:cafe_book_admin/repositories/accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_category_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_expense_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_inventory_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_order_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_payment_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_product_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_purchase_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_recipe_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_report_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_settings_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_table_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_waste_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_waiter_call_repository.dart';
import 'package:cafe_book_admin/repositories/expense_repository.dart';
import 'package:cafe_book_admin/repositories/inventory_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_expense_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_inventory_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_order_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_payment_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_purchase_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_recipe_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_report_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_settings_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_waiter_call_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_waste_repository.dart';
import 'package:cafe_book_admin/repositories/order_repository.dart';
import 'package:cafe_book_admin/repositories/payment_repository.dart';
import 'package:cafe_book_admin/repositories/purchase_repository.dart';
import 'package:cafe_book_admin/repositories/recipe_repository.dart';
import 'package:cafe_book_admin/repositories/report_repository.dart';
import 'package:cafe_book_admin/repositories/settings_repository.dart';
import 'package:cafe_book_admin/repositories/waiter_call_repository.dart';
import 'package:cafe_book_admin/repositories/waste_repository.dart';
import 'package:cafe_book_admin/services/realtime_service.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../repositories/category_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/mock/mock_category_repository.dart';
import '../repositories/mock/mock_dashboard_repository.dart';
import '../repositories/mock/mock_database.dart';
import '../repositories/mock/mock_product_repository.dart';
import '../repositories/mock/mock_table_repository.dart';
import '../services/image_picker_service.dart';
import '../repositories/table_repository.dart';

import 'category_provider.dart';
import 'navigation_provider.dart';
import 'product_provider.dart';
import 'table_provider.dart';

/// نقطه‌ی تزریق وابستگی‌ها.
///
/// همه‌جا بر اساس `AppConfig.useMock` بین Mock*Repository و Api*Repository
/// سوییچ می‌کنیم؛ هیچ Provider یا صفحه‌ای به این انتخاب وابسته نیست.
///
/// نکته‌ی مهم: Providerهایی که به توکن ورود نیاز دارند (Dashboard, Table,
/// Order, ...) اینجا load() نمی‌شوند؛ بارگذاری اولیه‌شان بعد از موفقیت
/// ورود (AuthGate) در initState پوسته‌ی اصلی برنامه انجام می‌شود.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ---------- زیرساخت شبکه و احراز هویت ----------
        Provider<TokenStorage>(create: (_) => PrefsTokenStorage()),
        Provider<ApiClient>(
          create: (ctx) => ApiClient(ctx.read<TokenStorage>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              AuthProvider(ctx.read<ApiClient>(), ctx.read<TokenStorage>())
                ..restore(),
        ),

        // ---------- داده‌ی Mock (فقط وقتی USE_MOCK=true واقعاً استفاده می‌شود) ----------
        Provider<MockDatabase>(create: (_) => MockDatabase.seeded()),

        // ---------- ناوبری ----------
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // ---------- Dashboard ----------
        Provider<DashboardRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockDashboardRepository(ctx.read<MockDatabase>())
              : ApiDashboardRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => DashboardProvider(ctx.read<DashboardRepository>()),
        ),

        // ---------- Tables ----------
        Provider<TableRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockTableRepository(ctx.read<MockDatabase>())
              : ApiTableRepository(ctx.read<ApiClient>()),
        ),
        Provider<PaymentRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockPaymentRepository(
                  ctx.read<MockDatabase>(),
                  MockTableRepository(ctx.read<MockDatabase>()),
                )
              : ApiPaymentRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TableProvider(
            ctx.read<TableRepository>(),
            ctx.read<PaymentRepository>(),
          ),
        ),

        // ---------- Categories ----------
        Provider<CategoryRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockCategoryRepository(ctx.read<MockDatabase>())
              : ApiCategoryRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CategoryProvider(ctx.read<CategoryRepository>()),
        ),

        // ---------- Products ----------
        Provider<ProductRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockProductRepository(ctx.read<MockDatabase>())
              : ApiProductRepository(ctx.read<ApiClient>()),
        ),
        Provider<ImagePickerService>(create: (_) => FilePickerImageService()),
        ChangeNotifierProvider(
          create: (ctx) => ProductProvider(ctx.read<ProductRepository>()),
        ),

        // ---------- Inventory ----------
        Provider<InventoryRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockInventoryRepository(ctx.read<MockDatabase>())
              : ApiInventoryRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => InventoryProvider(ctx.read<InventoryRepository>()),
        ),

        // ---------- Purchases ----------
        Provider<PurchaseRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockPurchaseRepository(ctx.read<MockDatabase>())
              : ApiPurchaseRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PurchaseProvider(ctx.read<PurchaseRepository>()),
        ),

        // ---------- Wastes ----------
        Provider<WasteRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockWasteRepository(ctx.read<MockDatabase>())
              : ApiWasteRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => WasteProvider(ctx.read<WasteRepository>()),
        ),

        // ---------- Recipes ----------
        Provider<RecipeRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockRecipeRepository(ctx.read<MockDatabase>())
              : ApiRecipeRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => RecipeProvider(ctx.read<RecipeRepository>()),
        ),

        // ---------- Orders ----------
        Provider<OrderRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockOrderRepository(ctx.read<MockDatabase>())
              : ApiOrderRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => OrderProvider(ctx.read<OrderRepository>()),
        ),

        // ---------- Expenses ----------
        Provider<ExpenseRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockExpenseRepository(ctx.read<MockDatabase>())
              : ApiExpenseRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ExpenseProvider(ctx.read<ExpenseRepository>()),
        ), // ---------- Realtime (WebSocket) ----------
        Provider<RealtimeService>(
          create: (ctx) =>
              RealtimeService(() => ctx.read<TokenStorage>().read()),
          dispose: (_, s) => s.dispose(),
        ),
        // ---------- Waiter calls (درخواست گارسون) ----------
        Provider<WaiterCallRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockWaiterCallRepository(ctx.read<MockDatabase>())
              : ApiWaiterCallRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<WaiterCallProvider>(
          create: (ctx) => WaiterCallProvider(ctx.read<WaiterCallRepository>()),
        ),
        ChangeNotifierProvider<RealtimeSync>(
          create: (ctx) => RealtimeSync(
            service: ctx.read<RealtimeService>(),
            orders: ctx.read<OrderProvider>(),
            tables: ctx.read<TableProvider>(),
            dashboard: ctx.read<DashboardProvider>(),
            waiterCalls: ctx.read<WaiterCallProvider>(),
            changesRepo: AppConfig.useMock
                ? null
                : ApiOrderRepository(ctx.read<ApiClient>()),
          ),
        ), // ---------- Accounting ----------
        Provider<AccountingRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockAccountingRepository(ctx.read<MockDatabase>())
              : ApiAccountingRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AccountingProvider(ctx.read<AccountingRepository>()),
        ), // ---------- Reports ----------
        Provider<ReportRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockReportRepository(ctx.read<MockDatabase>())
              : ApiReportRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ReportProvider(ctx.read<ReportRepository>()),
        ), // ---------- Settings ----------
        Provider<SettingsRepository>(
          create: (ctx) => AppConfig.useMock
              ? MockSettingsRepository()
              : ApiSettingsRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SettingsProvider(ctx.read<SettingsRepository>()),
        ),
      ],
      child: child,
    );
  }
}
