import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../admin_shell_scaffold.dart';

class AdminAttendanceScreen extends ConsumerWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attendanceAsync = ref.watch(allAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.attendanceManagement),
      ),
      body: attendanceAsync.when(
        loading: () => const ShimmerList(count: 8, itemHeight: 80),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              message: l10n.noAttendance,
              icon: Icons.access_time_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _AdminAttendanceTile(log: logs[i]),
          );
        },
      ),
    );
  }
}

class _AdminAttendanceTile extends StatelessWidget {
  final AttendanceModel log;

  const _AdminAttendanceTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final l10n = context.l10n;
    final statusColor = log.status == AttendanceStatus.late
        ? AppColors.attendanceLate
        : log.status == AttendanceStatus.absent
            ? AppColors.attendanceAbsent
            : AppColors.attendancePresent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.12),
              child: Icon(Icons.person_rounded,
                  color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.employeeName ?? log.employeeId,
                      style: context.textTheme.titleMedium),
                  Text(
                    log.checkInTime != null
                        ? '${l10n.checkInTime}: ${timeFormat.format(log.checkInTime!)}'
                        : l10n.notCheckedIn,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.status == AttendanceStatus.late
                        ? l10n.attendanceLate
                        : log.status == AttendanceStatus.absent
                            ? l10n.attendanceAbsent
                            : l10n.attendancePresent,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
                if (!log.insideGeofence) ...[
                  const SizedBox(height: 4),
                  const Icon(Icons.location_off_outlined,
                      size: 14, color: AppColors.error),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
