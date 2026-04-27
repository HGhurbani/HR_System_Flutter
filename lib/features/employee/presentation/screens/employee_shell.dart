import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shell_drawer_nav_list_tile.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_providers.dart';
import '../employee_shell_scaffold.dart';

class EmployeeShell extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const EmployeeShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final auth = ref.read(authNotifierProvider.notifier);

    final navItems = [
      _NavItem(
        label: l10n.employeeDashboard,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        route: AppRoutes.employeeDashboard,
      ),
      _NavItem(
        label: l10n.attendance,
        icon: Icons.access_time_outlined,
        activeIcon: Icons.access_time_filled_rounded,
        route: AppRoutes.employeeAttendance,
      ),
      _NavItem(
        label: l10n.salary,
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments_rounded,
        route: AppRoutes.employeeSalary,
      ),
      _NavItem(
        label: l10n.leaves,
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        route: AppRoutes.employeeLeaves,
      ),
      _NavItem(
        label: l10n.myProfile,
        icon: Icons.person_outlined,
        activeIcon: Icons.person_rounded,
        route: AppRoutes.employeeProfile,
      ),
      _NavItem(
        label: l10n.settings,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        route: AppRoutes.employeeSettings,
      ),
    ];

    // Keep bottom navigation short; the full list stays in the Drawer.
    const bottomBranchIndexes = <int>[0, 1, 5]; // Dashboard, Attendance, Settings
    final bottomSelectedIndex = bottomBranchIndexes.indexOf(shell.currentIndex);
    final safeBottomSelectedIndex =
        bottomSelectedIndex >= 0 ? bottomSelectedIndex : 0;

    return Scaffold(
      key: kEmployeeShellScaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      child: Icon(Icons.badge_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.fullName ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final entry in navItems.indexed)
                      ShellDrawerNavListTile(
                        label: entry.$2.label,
                        icon: entry.$2.icon,
                        activeIcon: entry.$2.activeIcon,
                        selected: entry.$1 == shell.currentIndex,
                        onTap: () {
                          Navigator.pop(context);
                          shell.goBranch(entry.$1);
                        },
                      ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final confirm = await context.showConfirmDialog(
                          title: l10n.logout,
                          message: l10n.logoutConfirm,
                          isDanger: true,
                        );
                        if (confirm == true) {
                          auth.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeBottomSelectedIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(bottomBranchIndexes[index]),
        destinations: [
          NavigationDestination(
            icon: Icon(navItems[bottomBranchIndexes[0]].icon),
            selectedIcon: Icon(navItems[bottomBranchIndexes[0]].activeIcon),
            label: navItems[bottomBranchIndexes[0]].label,
          ),
          NavigationDestination(
            icon: Icon(navItems[bottomBranchIndexes[1]].icon),
            selectedIcon: Icon(navItems[bottomBranchIndexes[1]].activeIcon),
            label: navItems[bottomBranchIndexes[1]].label,
          ),
          NavigationDestination(
            icon: Icon(navItems[bottomBranchIndexes[2]].icon),
            selectedIcon: Icon(navItems[bottomBranchIndexes[2]].activeIcon),
            label: navItems[bottomBranchIndexes[2]].label,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
