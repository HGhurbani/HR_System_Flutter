import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../notifications/presentation/widgets/notifications_icon_button.dart';
import '../employee_shell_scaffold.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayAttAsync = ref.watch(todayAttendanceProvider);
    final l10n = context.l10n;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openEmployeeShellDrawer,
        ),
        title: Text(l10n.employeeDashboard),
        actions: [
          const NotificationsIconButton(),
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'E',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
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
                  if (user?.position != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.position!,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today Attendance Card
            Text(l10n.todayAttendance,
                style: context.textTheme.titleLarge),
            const SizedBox(height: 12),

            todayAttAsync.when(
              loading: () => const ShimmerCard(height: 100),
              error: (e, _) =>
                  Text('${l10n.error}: $e'),
              data: (attendance) => _AttendanceCard(
                attendance: attendance,
                l10n: l10n,
              ),
            ),
            const SizedBox(height: 20),

            // Quick Links
            Text(l10n.quickStats,
                style: context.textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildQuickLinks(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context, l10n) {
    final links = [
      (
        icon: Icons.access_time_rounded,
        label: l10n.myAttendance,
        color: AppColors.primary
      ),
      (
        icon: Icons.payments_rounded,
        label: l10n.mySalary,
        color: AppColors.secondary
      ),
      (
        icon: Icons.event_note_rounded,
        label: l10n.myLeaves,
        color: AppColors.warning
      ),
      (
        icon: Icons.person_rounded,
        label: l10n.myProfile,
        color: AppColors.info
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2,
      children: links
          .map((link) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: link.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: link.color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(link.icon, color: link.color, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        link.label,
                        style: TextStyle(
                          color: link.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceModel? attendance;
  final dynamic l10n;

  const _AttendanceCard({required this.attendance, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (attendance == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.absentToday,
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  Text(
                    l10n.notCheckedIn,
                    style: TextStyle(
                        color: AppColors.warning.withOpacity(0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final timeFormat = DateFormat('hh:mm a');
    final statusColor = attendance!.status == AttendanceStatus.late
        ? AppColors.attendanceLate
        : AppColors.attendancePresent;
    final statusLabel = attendance!.status == AttendanceStatus.late
        ? l10n.attendanceLate
        : l10n.attendancePresent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: statusColor, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    if (attendance!.latenessMinutes > 0)
                      Text(
                        '${l10n.latenessMinutes}: ${attendance!.latenessMinutes}',
                        style: TextStyle(
                            color: statusColor.withOpacity(0.7),
                            fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TimeChip(
                icon: Icons.login_rounded,
                label: l10n.checkInTime,
                time: attendance!.checkInTime != null
                    ? timeFormat.format(attendance!.checkInTime!)
                    : '--:--',
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _TimeChip(
                icon: Icons.logout_rounded,
                label: l10n.checkOutTime,
                time: attendance!.checkOutTime != null
                    ? timeFormat.format(attendance!.checkOutTime!)
                    : '--:--',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary),
                ),
                Text(
                  time,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
