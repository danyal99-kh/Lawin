import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import 'app_destination.dart';
import 'brand_header.dart';
import 'nav_item_tile.dart';

/// Drawer موبایل؛ همان آیتم‌های Sidebar را دارد.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<NavigationProvider>().current;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const BrandHeader(),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  for (final d in AppDestination.values)
                    NavItemTile(
                      destination: d,
                      selected: d == current,
                      onTap: () {
                        context.read<NavigationProvider>().select(d);
                        Navigator.of(context).pop(); // بستن Drawer
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
