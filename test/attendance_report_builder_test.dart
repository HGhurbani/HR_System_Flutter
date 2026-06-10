import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_model.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_report.dart';
import 'package:hr_sys/features/auth/domain/entities/app_user.dart';
import 'package:hr_sys/features/auth/domain/entities/user_role.dart';
import 'package:hr_sys/features/leaves/data/models/leave_request_model.dart';

void main() {
  test('range includes its first and last calendar day', () {
    final range = AttendanceDateRange(
      start: DateTime(2026, 6, 1, 12),
      end: DateTime(2026, 6, 3, 22),
    );

    expect(range.start, DateTime(2026, 6, 1));
    expect(range.end, DateTime(2026, 6, 3));
    expect(range.endExclusive, DateTime(2026, 6, 4));
  });

  test('invalid range is rejected', () {
    expect(
      () => AttendanceDateRange(
        start: DateTime(2026, 6, 2),
        end: DateTime(2026, 6, 1),
      ),
      throwsArgumentError,
    );
  });

  test('creates absence while excluding rest, holiday, leave and pre-hire days',
      () {
    final employee = _employee(
      hireDate: DateTime(2026, 6, 2),
      customRestDays: const [DateTime.friday],
    );
    final range = AttendanceDateRange(
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 7),
    );
    final leaveDay = DateTime(2026, 6, 3);
    final holidayDay = DateTime(2026, 6, 4);

    final rows = AttendanceReportBuilder.build(
      range: range,
      employees: [employee],
      attendanceLogs: [
        _attendance(DateTime(2026, 6, 7)),
      ],
      approvedLeaves: [
        _leave(leaveDay),
      ],
      companyWeeklyRestDays: const [DateTime.saturday],
      holidayDayKeys: {AttendanceReportBuilder.dayKey(holidayDay)},
    );

    expect(
      rows.map((row) => '${row.date.day}:${row.status.name}'),
      containsAll([
        '2:absent',
        '3:onLeave',
        '6:absent',
        '7:present',
      ]),
    );
    expect(rows.any((row) => row.date.day == 1), isFalse);
    expect(rows.any((row) => row.date.day == 4), isFalse);
    expect(rows.any((row) => row.date.day == 5), isFalse);
  });

  test('actual record wins over computed leave or absence', () {
    final day = DateTime(2026, 6, 2);
    final rows = AttendanceReportBuilder.build(
      range: AttendanceDateRange(start: day, end: day),
      employees: [_employee()],
      attendanceLogs: [
        _attendance(
          day,
          status: AttendanceStatus.late,
          checkOutTime: null,
        ),
      ],
      approvedLeaves: [_leave(day)],
      companyWeeklyRestDays: const [DateTime.friday],
      holidayDayKeys: const {},
    );

    expect(rows, hasLength(1));
    expect(rows.single.status, AttendanceStatus.late);
    expect(rows.single.checkOutTime, isNull);
    expect(rows.single.isSynthetic, isFalse);
  });

  test('inactive employee keeps actual logs but receives no synthetic absences',
      () {
    final firstDay = DateTime(2026, 6, 1);
    final secondDay = DateTime(2026, 6, 2);
    final rows = AttendanceReportBuilder.build(
      range: AttendanceDateRange(start: firstDay, end: secondDay),
      employees: [_employee(isActive: false)],
      attendanceLogs: [_attendance(firstDay)],
      approvedLeaves: const [],
      companyWeeklyRestDays: const [DateTime.friday],
      holidayDayKeys: const {},
    );

    expect(rows, hasLength(1));
    expect(rows.single.date, firstDay);
  });
}

AppUser _employee({
  DateTime? hireDate,
  List<int> customRestDays = const [],
  bool isActive = true,
}) {
  return AppUser(
    uid: 'emp-1',
    fullName: 'Employee One',
    email: 'employee@example.com',
    role: UserRole.employee,
    isActive: isActive,
    hireDate: hireDate,
    weeklyRestDaysMode: customRestDays.isEmpty
        ? AppUser.weeklyRestDaysModeCompany
        : AppUser.weeklyRestDaysModeCustom,
    customWeeklyRestDays: customRestDays,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

AttendanceModel _attendance(
  DateTime day, {
  AttendanceStatus status = AttendanceStatus.present,
  DateTime? checkOutTime,
}) {
  return AttendanceModel(
    id: 'attendance-${day.toIso8601String()}',
    employeeId: 'emp-1',
    employeeName: 'Employee One',
    date: day,
    shiftType: ShiftType.morning,
    checkInTime: day.add(const Duration(hours: 8)),
    checkOutTime: checkOutTime,
    status: status,
    latenessMinutes: status == AttendanceStatus.late ? 10 : 0,
    createdAt: day,
  );
}

LeaveRequestModel _leave(DateTime day) {
  return LeaveRequestModel(
    id: 'leave-${day.toIso8601String()}',
    employeeId: 'emp-1',
    employeeName: 'Employee One',
    type: LeaveType.official,
    startDate: day,
    endDate: day,
    reason: 'Approved leave',
    status: LeaveRequestStatus.approved,
    createdAt: day,
    updatedAt: day,
  );
}
