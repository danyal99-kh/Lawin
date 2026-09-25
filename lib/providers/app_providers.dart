import 'package:cafe_book_admin/repositories/dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'dashboard_provider.dart';
import 'navigation_provider.dart';

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
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) =>
              DashboardProvider(ctx.read<DashboardRepository>())..load(),
        ),
      ],
      child: child,
    );
  }
}
