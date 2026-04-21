import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../candidates/application/candidates_providers.dart';
import '../../../candidates/domain/entities/candidate_status.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final now = DateTime.now();

    final candidatesAsync = ref.watch(
        supervisorCandidatesProvider(const CandidateFilter()));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supervisorDashboard),
        actions: [
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text(l10n.logout),
                onTap: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: candidatesAsync.when(
        loading: () => const ShimmerList(count: 4, itemHeight: 90),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (candidates) {
          final counts = <CandidateStatus, int>{};
          for (final c in candidates) {
            counts[c.status] = (counts[c.status] ?? 0) + 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.welcome}, ${user?.fullName ?? ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(now),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(l10n.quickStats,
                    style: context.textTheme.titleLarge),
                const SizedBox(height: 12),

                _StatRow(
                  label: l10n.totalCandidates,
                  value: '${candidates.length}',
                  icon: Icons.folder_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: l10n.statusAvailable,
                  value: '${counts[CandidateStatus.available] ?? 0}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.statusAvailable,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: l10n.statusReserved,
                  value: '${counts[CandidateStatus.reserved] ?? 0}',
                  icon: Icons.bookmark_outline,
                  color: AppColors.statusReserved,
                ),

                if (candidates.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(l10n.recentActivity,
                      style: context.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...candidates.take(5).map((c) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          tileColor: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: CircleAvatar(
                            backgroundImage: c.imageUrl != null
                                ? NetworkImage(c.imageUrl!)
                                : null,
                            child: c.imageUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(c.fullName),
                          subtitle:
                              Text(c.nationality.value),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(c.status)
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              _cvStatusLabel(c.status, l10n),
                              style: TextStyle(
                                fontSize: 11,
                                color: _statusColor(c.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(CandidateStatus s) {
    switch (s) {
      case CandidateStatus.available:
        return AppColors.statusAvailable;
      case CandidateStatus.reserved:
        return AppColors.statusReserved;
    }
  }
}

String _cvStatusLabel(CandidateStatus s, dynamic l10n) {
  switch (s) {
    case CandidateStatus.available:
      return l10n.statusAvailable;
    case CandidateStatus.reserved:
      return l10n.statusReserved;
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
