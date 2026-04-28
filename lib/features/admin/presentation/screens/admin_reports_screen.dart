import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../application/admin_dashboard_providers.dart';
import '../admin_shell_scaffold.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.reportsAnalytics),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.quickStats, style: context.textTheme.titleLarge),
              const SizedBox(height: 16),
              _ReportCard(
                title: l10n.candidateReport,
                icon: Icons.folder_special_rounded,
                color: AppColors.accent,
                items: [
                  _ReportItem(l10n.totalCandidates, '${stats.totalCandidates}'),
                  _ReportItem(l10n.statusAvailable,
                      '${stats.candidateStatusCounts['available'] ?? 0}'),
                  _ReportItem(l10n.statusReserved,
                      '${stats.candidateStatusCounts['reserved'] ?? 0}'),
                  _ReportItem(l10n.statusHired, '${stats.hiredCandidates}'),
                ],
              ),
              const SizedBox(height: 16),
              _ReportCard(
                title: l10n.employees,
                icon: Icons.people_rounded,
                color: AppColors.primary,
                items: [
                  _ReportItem(l10n.totalEmployees, '${stats.totalEmployees}'),
                  _ReportItem(
                      l10n.totalSupervisors, '${stats.totalSupervisors}'),
                ],
              ),
              const SizedBox(height: 16),
              _ReportCard(
                title: l10n.leaveReport,
                icon: Icons.event_note_rounded,
                color: AppColors.warning,
                items: [
                  _ReportItem(l10n.pendingLeaves, '${stats.pendingLeaves}'),
                ],
              ),
              const SizedBox(height: 16),
              _ReportCard(
                title: l10n.salaryReport,
                icon: Icons.payments_rounded,
                color: AppColors.secondary,
                items: [
                  _ReportItem(
                    l10n.netSalary,
                    '${stats.monthlyPayrollTotal.toStringAsFixed(0)} ${l10n.currency}',
                  ),
                  _ReportItem(
                    l10n.commission,
                    '${stats.monthlyCommissionTotal.toStringAsFixed(0)} ${l10n.currency}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ReportItem> items;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = AppColors.adaptiveForegroundColor(context, color);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: effectiveColor, size: 22),
                const SizedBox(width: 8),
                Text(title, style: context.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 20),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.label,
                            style: context.textTheme.bodyMedium),
                      ),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: effectiveColor,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ReportItem {
  final String label;
  final String value;

  const _ReportItem(this.label, this.value);
}
