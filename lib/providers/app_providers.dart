import 'package:flutter/foundation.dart';
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
import '../repositories/mock/mock_product_repository.dart';
import '../repositories/mock/mock_table_repository.dart';
import '../services/image_picker_service.dart';
import 'category_provider.dart';
import 'dashboard_provider.dart';
import 'navigation_provider.dart';
import 'product_provider.dart';
import 'table_provider.dart';
import 'table_provider.dart';

/// نقطه‌ی تزریق وابستگی‌ها.
///
/// مرحله ۱۲ (اتصال به Django): اینجا بر اساس `AppConfig.useMock` به‌جای
/// Mock*Repository از Api*Repository استفاده می‌شود؛ هیچ Provider یا صفحه‌ای تغییر نمی‌کند.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MockDatabase>(create: (_) => MockDatabase.seeded()),
        Provider<DashboardRepository>(
          create: (ctx) => MockDashboardRepository(ctx.read<MockDatabase>()),
        ),
        Provider<MockTableRepository>(
          create: (ctx) => MockTableRepository(ctx.read<MockDatabase>()),
        ),
        Provider<TableRepository>(
          create: (ctx) => MockTableRepository(ctx.read<MockDatabase>()),
        ),
        Provider<CategoryRepository>(
          create: (ctx) => MockCategoryRepository(ctx.read<MockDatabase>()),
        ),
        Provider<ProductRepository>(
          create: (ctx) => MockProductRepository(ctx.read<MockDatabase>()),
        ),
        Provider<ImagePickerService>(create: (_) => FilePickerImageService()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (ctx) => CategoryProvider(ctx.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ProductProvider(ctx.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TableProvider(ctx.read<TableRepository>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) =>
              DashboardProvider(ctx.read<DashboardRepository>())..load(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) {
            final repo = ctx.read<MockTableRepository>();
            return TableProvider(
              repo,
              // ابزار شبیه‌سازی فقط در Debug + Mock
              devTools: (kDebugMode && AppConfig.useMock) ? repo : null,
            )..load();
          },
        ),
      ],
      child: child,
    );
  }
}