import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_destination.dart';

/// یک آیتم ناوبری. حالت [compact] فقط آیکن (با Tooltip) نشان می‌دهد.
class NavItemTile extends StatelessWidget {
  const NavItemTile({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      color: color,
      size: 22,
    );

    final content = compact
        ? Center(child: icon)
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          );

    final tile = Material(
      color: selected ? AppColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(height: 48, child: content),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: compact ? Tooltip(message: destination.label, child: tile) : tile,
    );
  }
}
