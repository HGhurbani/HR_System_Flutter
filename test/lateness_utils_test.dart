import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/attendance/application/lateness_utils.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_model.dart';
import 'package:hr_sys/features/attendance/data/models/company_work_schedule.dart';
import 'package:hr_sys/features/permissions/data/models/permission_request_model.dart';

void main() {
  test('formats lateness minutes as hours and minutes', () {
    expect(formatLatenessDuration(0), '0:00');
    expect(formatLatenessDuration(5), '0:05');
    expect(formatLatenessDuration(122), '2:02');
  });

  test('approved permission overlapping lateness reduces displayed minutes',
      () {
    final attendance = _attendance(checkInHour: 10, checkInMinute: 2);
    final permission = _permission(
      start: DateTime(2026, 5, 10, 8),
      durationMinutes: 120,
    );

    final effective = effectiveLatenessMinutes(
      attendance: attendance,
      workSchedule: const CompanyWorkSchedule(morningHour: 8),
      approvedPermissions: [permission],
    );

    expect(effective, 2);
  });

  test('non-overlapping permission does not reduce lateness', () {
    final attendance = _attendance(checkInHour: 10, checkInMinute: 2);
    final permission = _permission(
      start: DateTime(2026, 5, 10, 12),
      durationMinutes: 60,
    );

    final effective = effectiveLatenessMinutes(
      attendance: attendance,
      workSchedule: const CompanyWorkSchedule(morningHour: 8),
      approvedPermissions: [permission],
    );

    expect(effective, 122);
  });

  test('overlapping permissions are not double counted', () {
    final attendance = _attendance(checkInHour: 10, checkInMinute: 2);
    final permissions = [
      _permission(
        start: DateTime(2026, 5, 10, 8),
        durationMinutes: 90,
      ),
      _permission(
        start: DateTime(2026, 5, 10, 9),
        durationMinutes: 60,
      ),
    ];

    final effective = effectiveLatenessMinutes(
      attendance: attendance,
      workSchedule: const CompanyWorkSchedule(morningHour: 8),
      approvedPermissions: permissions,
    );

    expect(effective, 2);
  });
}

AttendanceModel _attendance({
  required int checkInHour,
  required int checkInMinute,
}) {
  final date = DateTime(2026, 5, 10);
  return AttendanceModel(
    id: 'attendance-1',
    employeeId: 'emp-1',
    date: date,
    shiftType: ShiftType.morning,
    checkInTime: DateTime(2026, 5, 10, checkInHour, checkInMinute),
    status: AttendanceStatus.late,
    latenessMinutes: 122,
    createdAt: date,
  );
}

PermissionRequestModel _permission({
  required DateTime start,
  required int durationMinutes,
}) {
  return PermissionRequestModel(
    id: 'permission-1',
    employeeId: 'emp-1',
    date: DateTime(start.year, start.month, start.day),
    startTime: start,
    durationMinutes: durationMinutes,
    reason: 'Permission',
    status: PermissionRequestStatus.approved,
    createdAt: start,
    updatedAt: start,
  );
}
