import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/admin_dashboard_providers.dart';
import '../admin_shell_scaffold.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final l10n = context.l10n;
    final now = DateTime.now();
    final greeting = _greeting(now.hour, l10n);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.adminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text(l10n.settings),
                onTap: () => context.go(AppRoutes.adminSettings),
              ),
              PopupMenuItem(
                child: Text(l10n.logout),
                onTap: () async {
                  final confirm = await context.showConfirmDialog(
                    title: l10n.logout,
                    message: l10n.logoutConfirm,
                    isDanger: true,
                  );
                  if (confirm == true) {
                    ref.read(authNotifierProvider.notifier).signOut();
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashboardStatsProvider.future),
        child: statsAsync.when(
          loading: () => const ShimmerList(count: 6, itemHeight: 90),
          error: (e, _) => Center(child: Text('${context.l10n.error}: $e')),
          data: (stats) => _buildBody(context, user, stats, greeting, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    user,
    stats,
    String greeting,
    l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(context, user, greeting, l10n),
          const SizedBox(height: 20),

          // Stats Grid
          Text(l10n.quickStats,
              style: context.textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildStatsGrid(context, stats, l10n),
          const SizedBox(height: 20),

          // Candidate Status Summary
          Text(l10n.candidates,
              style: context.textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildCandidateStatusCards(context, stats, l10n),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, user, String greeting, l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, stats, l10n) {
    final items = [
      (
        label: l10n.totalEmployees,
        value: '${stats.totalEmployees}',
        icon: Icons.people_rounded,
        color: AppColors.primary,
      ),
      (
        label: l10n.totalSupervisors,
        value: '${stats.totalSupervisors}',
        icon: Icons.supervisor_account_rounded,
        color: AppColors.secondary,
      ),
      (
        label: l10n.totalCandidates,
        value: '${stats.totalCandidates}',
        icon: Icons.folder_special_rounded,
        color: AppColors.accent,
      ),
      (
        label: l10n.pendingLeaves,
        value: '${stats.pendingLeaves}',
        icon: Icons.event_note_rounded,
        color: AppColors.warning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isTablet ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return _MiniStatCard(
          label: item.label,
          value: item.value,
          icon: item.icon,
          color: item.color,
        );
      },
    );
  }

  Widget _buildCandidateStatusCards(BuildContext context, stats, l10n) {
    final statusItems = [
      (
        label: l10n.statusAvailable,
        key: 'available',
        color: AppColors.statusAvailable
      ),
      (
        label: l10n.statusReserved,
        key: 'reserved',
        color: AppColors.statusReserved
      ),
    ];

    final crossAxisCount = context.isTablet ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: context.isTablet ? 2.0 : 2.2,
      ),
      itemCount: statusItems.length,
      itemBuilder: (_, i) {
        final item = statusItems[i];
        final count = stats.candidateStatusCounts[item.key] ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.folder_rounded, color: item.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: item.color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _greeting(int hour, l10n) {
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
