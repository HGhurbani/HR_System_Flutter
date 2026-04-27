import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// List tile used in admin/employee shell drawers: gold highlight when selected,
/// and in dark mode idle rows use gold instead of theme primary (dark green).
class ShellDrawerNavListTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const ShellDrawerNavListTile({
    super.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color? idleIconColor = isDark ? AppColors.goldLight : null;
    final Color? idleTextColor = isDark ? AppColors.goldLight : null;

    return ListTile(
      leading: Icon(
        selected ? activeIcon : icon,
        color: selected ? AppColors.goldDark : idleIconColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.goldDark : idleTextColor,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.gold.withValues(alpha: 0.22),
      splashColor: AppColors.gold.withValues(alpha: 0.14),
      hoverColor: AppColors.gold.withValues(alpha: 0.10),
      onTap: onTap,
    );
  }
}
