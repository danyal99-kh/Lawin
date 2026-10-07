import 'package:cafe_book_admin/providers/auth_provider.dart';
import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_destination.dart';
import 'brand_header.dart';
import 'nav_item_tile.dart';

/// Sidebar دائمی (سمت راست در RTL). حالت [compact] برای پنجره‌های میانی فقط آیکن دارد.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<NavigationProvider>().current;
    return Container(
      width: compact ? 84 : 264,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: BorderDirectional(end: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            BrandHeader(compact: compact),
            const Divider(),
            // ListView تا در ارتفاع کم پنجره Overflow ایجاد نشود.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                children: [
                  for (final d in AppDestination.values)
                    NavItemTile(
                      destination: d,
                      selected: d == current,
                      compact: compact,
                      onTap: () => context.read<NavigationProvider>().select(d),
                    ),
                ],
              ),
            ),
            const Divider(),
            // خروج کامل نشست (توکن سمت سرور هم باطل می‌شود).
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: compact
                  ? Tooltip(
                      message: 'خروج از حساب',
                      child: IconButton(
                        icon: const Icon(Icons.logout_outlined),
                        color: AppColors.danger,
                        onPressed: () => context.read<AuthProvider>().logout(),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<AuthProvider>().logout(),
                        icon: const Icon(Icons.logout_outlined, size: 18),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        label: const Text('خروج از حساب'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
