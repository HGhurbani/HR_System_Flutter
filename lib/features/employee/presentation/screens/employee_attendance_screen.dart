import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/data/models/company_work_schedule.dart';
import '../../../auth/application/auth_providers.dart';
import '../employee_shell_scaffold.dart';

class EmployeeAttendanceScreen extends ConsumerStatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  ConsumerState<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState
    extends ConsumerState<EmployeeAttendanceScreen> {
  ShiftType _selectedShift = ShiftType.morning;

  void _showLocationFailureMessage() {
    final l10n = context.l10n;
    final code =
        ref.read(attendanceNotifierProvider).errorMessage ?? '';
    final message = switch (code) {
      'location-disabled' => l10n.locationServiceDisabled,
      'permission-denied' => l10n.locationRequired,
      'permission-denied-forever' => l10n.locationRequired,
      _ => l10n.errorLocationFailed,
    };
    context.showSnackBar(message, isError: true);
  }

  Future<void> _handleCheckIn() async {
    final l10n = context.l10n;
    final notifier = ref.read(attendanceNotifierProvider.notifier);

    // Get location
    context.showSnackBar(l10n.gettingLocation);
    final gotLocation = await notifier.getLocation();
    if (!gotLocation) {
      if (mounted) {
        _showLocationFailureMessage();
      }
      return;
    }

    final position = ref.read(attendanceNotifierProvider).currentPosition!;
    List<CompanyLocation> locations;
    try {
      locations = await ref.read(companyLocationsProvider.future);
    } catch (_) {
      locations = const [];
    }

    // Strict mode: do not allow check-in until company locations exist.
    if (locations.isEmpty) {
      if (mounted) {
        context.showSnackBar(
          context.isArabic
              ? 'لا يمكن تسجيل الحضور قبل إضافة مواقع الشركة من إعدادات الأدمن'
              : 'Check-in is disabled until company locations are configured',
          isError: true,
        );
      }
      return;
    }

    final insideGeofence = notifier.checkGeofence(position, locations);

    if (!insideGeofence) {
      if (mounted) {
        context.showSnackBar(l10n.locationNotInZone, isError: true);
      }
      return;
    }

    final schedule = ref.read(workScheduleProvider).valueOrNull ??
        const CompanyWorkSchedule();

    final success = await notifier.checkIn(
      position: position,
      insideGeofence: insideGeofence,
      shiftType: _selectedShift,
      workSchedule: schedule,
    );

    if (mounted) {
      if (success) {
        context.showSnackBar(l10n.checkInSuccess);
      } else {
        final error = ref.read(attendanceNotifierProvider).errorMessage ?? '';
        if (error.contains('already-checked-in')) {
          context.showSnackBar(l10n.alreadyCheckedIn, isError: true);
        } else {
          context.showSnackBar(l10n.errorGeneral, isError: true);
        }
      }
    }
  }

  Future<void> _handleCheckOut(String attendanceId) async {
    final l10n = context.l10n;
    final notifier = ref.read(attendanceNotifierProvider.notifier);

    context.showSnackBar(l10n.gettingLocation);
    final gotLocation = await notifier.getLocation();
    if (!gotLocation) {
      if (mounted) {
        _showLocationFailureMessage();
      }
      return;
    }

    final position = ref.read(attendanceNotifierProvider).currentPosition!;
    List<CompanyLocation> locations;
    try {
      locations = await ref.read(companyLocationsProvider.future);
    } catch (_) {
      locations = const [];
    }

    // Strict mode: do not allow check-out until company locations exist.
    if (locations.isEmpty) {
      if (mounted) {
        context.showSnackBar(
          context.isArabic
              ? 'لا يمكن تسجيل الانصراف قبل إضافة مواقع الشركة من إعدادات الأدمن'
              : 'Check-out is disabled until company locations are configured',
          isError: true,
        );
      }
      return;
    }

    final insideGeofence = notifier.checkGeofence(position, locations);
    if (!insideGeofence) {
      if (mounted) {
        context.showSnackBar(l10n.locationNotInZone, isError: true);
      }
      return;
    }

    final success = await notifier.checkOut(
      attendanceId: attendanceId,
      position: position,
    );

    if (mounted) {
      if (success) {
        context.showSnackBar(l10n.checkOutSuccess);
      } else {
        context.showSnackBar(l10n.errorGeneral, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final todayAttAsync = ref.watch(todayAttendanceProvider);
    final attendanceState = ref.watch(attendanceNotifierProvider);
    final historyAsync = ref.watch(
        attendanceHistoryProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openEmployeeShellDrawer,
        ),
        title: Text(l10n.myAttendance),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Check In/Out Card
            todayAttAsync.when(
              loading: () => const ShimmerCard(height: 200),
              error: (e, _) => Text('${l10n.error}: $e'),
              data: (attendance) => _CheckInOutCard(
                attendance: attendance,
                selectedShift: _selectedShift,
                isLoading: attendanceState.isLoading,
                onShiftChanged: (s) =>
                    setState(() => _selectedShift = s),
                onCheckIn: _handleCheckIn,
                onCheckOut: attendance != null
                    ? () => _handleCheckOut(attendance.id)
                    : null,
                l10n: l10n,
              ),
            ),
            const SizedBox(height: 24),

            // History
            Text(l10n.attendanceHistory,
                style: context.textTheme.titleLarge),
            const SizedBox(height: 12),

            historyAsync.when(
              loading: () => const ShimmerList(count: 10, itemHeight: 70),
              error: (e, _) => Text('${l10n.error}: $e'),
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.history,
                              size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: 12),
                          Text(l10n.noAttendance,
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: history
                      .map((log) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8),
                            child: _AttendanceHistoryTile(
                              log: log,
                              l10n: l10n,
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInOutCard extends StatelessWidget {
  final AttendanceModel? attendance;
  final ShiftType selectedShift;
  final bool isLoading;
  final ValueChanged<ShiftType> onShiftChanged;
  final VoidCallback onCheckIn;
  final VoidCallback? onCheckOut;
  final dynamic l10n;

  const _CheckInOutCard({
    required this.attendance,
    required this.selectedShift,
    required this.isLoading,
    required this.onShiftChanged,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheckedIn = attendance?.checkInTime != null;
    final hasCheckedOut = attendance?.checkOutTime != null;
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current time
            Text(
              DateFormat('hh:mm a').format(DateTime.now()),
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w700),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Shift selector (only if not checked in)
            if (!hasCheckedIn) ...[
              SegmentedButton<ShiftType>(
                segments: [
                  ButtonSegment(
                    value: ShiftType.morning,
                    label: Text(l10n.morningShift),
                    icon: const Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment(
                    value: ShiftType.evening,
                    label: Text(l10n.eveningShift),
                    icon: const Icon(Icons.nightlight_outlined),
                  ),
                ],
                selected: {selectedShift},
                onSelectionChanged: (v) => onShiftChanged(v.first),
              ),
              const SizedBox(height: 20),
            ],

            // Check in / out times
            if (hasCheckedIn) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TimeDisplay(
                    label: l10n.checkInTime,
                    time: timeFormat.format(attendance!.checkInTime!),
                    color: AppColors.success,
                  ),
                  _TimeDisplay(
                    label: l10n.checkOutTime,
                    time: hasCheckedOut
                        ? timeFormat
                            .format(attendance!.checkOutTime!)
                        : '--:--',
                    color: hasCheckedOut
                        ? AppColors.info
                        : AppColors.textDisabled,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Action button
            if (!hasCheckedIn)
              AppButton(
                label: l10n.checkIn,
                onPressed: isLoading ? null : onCheckIn,
                isLoading: isLoading,
                icon: Icons.login_rounded,
                color: AppColors.success,
              )
            else if (!hasCheckedOut)
              AppButton(
                label: l10n.checkOut,
                onPressed: isLoading ? null : onCheckOut,
                isLoading: isLoading,
                icon: Icons.logout_rounded,
                color: AppColors.error,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      l10n.attendancePresent,
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700),
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

class _TimeDisplay extends StatelessWidget {
  final String label;
  final String time;
  final Color color;

  const _TimeDisplay({
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _AttendanceHistoryTile extends StatelessWidget {
  final AttendanceModel log;
  final dynamic l10n;

  const _AttendanceHistoryTile({required this.log, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('EEE, d MMM');
    final statusColor = _statusColor(log.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _statusIcon(log.status),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(log.date),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  log.checkInTime != null
                      ? '${l10n.checkInTime}: ${timeFormat.format(log.checkInTime!)}'
                      : l10n.noAttendance,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(log.status),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.absent:
        return AppColors.attendanceAbsent;
      case AttendanceStatus.late:
        return AppColors.attendanceLate;
      case AttendanceStatus.onLeave:
        return AppColors.attendanceLeave;
      default:
        return AppColors.attendancePresent;
    }
  }

  IconData _statusIcon(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.absent:
        return Icons.cancel_outlined;
      case AttendanceStatus.late:
        return Icons.access_time_rounded;
      case AttendanceStatus.onLeave:
        return Icons.event_busy_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.absent:
        return l10n.attendanceAbsent;
      case AttendanceStatus.late:
        return l10n.attendanceLate;
      case AttendanceStatus.onLeave:
        return l10n.attendanceLeave;
      default:
        return l10n.attendancePresent;
    }
  }
}
