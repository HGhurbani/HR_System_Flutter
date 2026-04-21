import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_providers.dart';
import '../admin_shell_scaffold.dart';

class AdminShell extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const AdminShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final auth = ref.read(authNotifierProvider.notifier);

    final navItems = [
      _NavItem(
        label: l10n.adminDashboard,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        route: AppRoutes.adminDashboard,
      ),
      _NavItem(
        label: l10n.employees,
        icon: Icons.people_outline,
        activeIcon: Icons.people_rounded,
        route: AppRoutes.adminEmployees,
      ),
      _NavItem(
        label: l10n.candidates,
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder_rounded,
        route: AppRoutes.adminCandidates,
      ),
      _NavItem(
        label: l10n.attendance,
        icon: Icons.access_time_outlined,
        activeIcon: Icons.access_time_filled_rounded,
        route: AppRoutes.adminAttendance,
      ),
      _NavItem(
        label: l10n.leaves,
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        route: AppRoutes.adminLeaves,
      ),
      _NavItem(
        label: l10n.salary,
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments_rounded,
        route: AppRoutes.adminSalary,
      ),
      _NavItem(
        label: l10n.reports,
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        route: AppRoutes.adminReports,
      ),
      _NavItem(
        label: l10n.settings,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        route: AppRoutes.adminSettings,
      ),
    ];

    // Keep bottom navigation short; the full list stays in the Drawer.
    const bottomBranchIndexes = <int>[0, 3, 7]; // Dashboard, Attendance, Settings
    final bottomSelectedIndex = bottomBranchIndexes.indexOf(shell.currentIndex);
    final safeBottomSelectedIndex =
        bottomSelectedIndex >= 0 ? bottomSelectedIndex : 0;

    return Scaffold(
      key: kAdminShellScaffoldKey,
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
                      child: Icon(Icons.business_center_rounded),
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
                      ListTile(
                        leading: Icon(
                          entry.$2.icon,
                          color: entry.$1 == shell.currentIndex
                              ? AppColors.primary
                              : null,
                        ),
                        title: Text(entry.$2.label),
                        selected: entry.$1 == shell.currentIndex,
                        onTap: () {
                          Navigator.of(context).pop();
                          shell.goBranch(entry.$1);
                        },
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(l10n.logout),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await auth.signOut();
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
        onDestinationSelected: (bottomIndex) {
          final branchIndex = bottomBranchIndexes[bottomIndex];
          shell.goBranch(branchIndex);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: navItems[0].label,
          ),
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            selectedIcon: const Icon(Icons.access_time_filled_rounded),
            label: navItems[3].label,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: navItems[7].label,
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
