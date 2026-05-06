import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_model.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_policy_model.dart';
import 'package:hr_sys/features/leaves/data/models/leave_request_model.dart';
import 'package:hr_sys/features/salary/data/models/attendance_salary_summary.dart';

void main() {
  const policy = AttendancePolicyModel(
    weeklyRestDays: [DateTime.friday],
    attendanceThresholdPercent: 98,
    lateCountsAsPresent: true,
  );

  test('100 percent attendance has no attendance deduction', () {
    final logs = _workingDays('2026-04')
        .map((day) => _attendance(day, AttendanceStatus.present))
        .toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2600,
      policy: policy,
      attendanceLogs: logs,
      approvedLeaves: const [],
    );

    expect(summary.monthWorkingDays, 26);
    expect(summary.presentDays, 26);
    expect(summary.attendancePercentage, 100);
    expect(summary.attendanceDeduction, 0);
  });

  test('attendance below threshold deducts absent working days', () {
    final logs = _workingDays('2026-04')
        .take(25)
        .map((day) => _attendance(day, AttendanceStatus.present))
        .toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2600,
      policy: policy,
      attendanceLogs: logs,
      approvedLeaves: const [],
    );

    expect(summary.presentDays, 25);
    expect(summary.absentDays, 1);
    expect(summary.attendancePercentage, closeTo(96.153, 0.01));
    expect(summary.attendanceDeduction, 100);
  });

  test('late attendance counts as present', () {
    final logs = _workingDays('2026-04')
        .map((day) => _attendance(day, AttendanceStatus.late))
        .toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2600,
      policy: policy,
      attendanceLogs: logs,
      approvedLeaves: const [],
    );

    expect(summary.presentDays, 26);
    expect(summary.attendanceDeduction, 0);
  });

  test('approved leave reduces required attendance days', () {
    final workingDays = _workingDays('2026-04');
    final leaveDay = workingDays.first;
    final logs = workingDays
        .skip(1)
        .map((day) => _attendance(day, AttendanceStatus.present))
        .toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2600,
      policy: policy,
      attendanceLogs: logs,
      approvedLeaves: [
        LeaveRequestModel(
          id: 'leave-1',
          employeeId: 'emp-1',
          type: LeaveType.official,
          startDate: leaveDay,
          endDate: leaveDay,
          reason: 'annual',
          status: LeaveRequestStatus.approved,
          createdAt: leaveDay,
          updatedAt: leaveDay,
        ),
      ],
    );

    expect(summary.approvedLeaveDays, 1);
    expect(summary.requiredAttendanceDays, 25);
    expect(summary.presentDays, 25);
    expect(summary.attendancePercentage, 100);
    expect(summary.attendanceDeduction, 0);
  });

  test('default policy uses Friday rest and 98 percent threshold', () {
    const defaultPolicy = AttendancePolicyModel();
    final logs = _workingDays('2026-04')
        .take(25)
        .map((day) => _attendance(day, AttendanceStatus.present))
        .toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2600,
      policy: defaultPolicy,
      attendanceLogs: logs,
      approvedLeaves: const [],
    );

    expect(defaultPolicy.weeklyRestDays, [DateTime.friday]);
    expect(defaultPolicy.attendanceThresholdPercent, 98);
    expect(summary.attendanceDeduction, 100);
  });

  test('custom Friday and Saturday rest days reduce required working days', () {
    const customPolicy = AttendancePolicyModel(
      weeklyRestDays: [DateTime.friday, DateTime.saturday],
      attendanceThresholdPercent: 98,
      lateCountsAsPresent: true,
    );
    final logs = _workingDays(
      '2026-04',
      restDays: customPolicy.weeklyRestDays,
    ).map((day) => _attendance(day, AttendanceStatus.present)).toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2200,
      policy: customPolicy,
      attendanceLogs: logs,
      approvedLeaves: const [],
    );

    expect(summary.monthWorkingDays, 22);
    expect(summary.requiredAttendanceDays, 22);
    expect(summary.presentDays, 22);
    expect(summary.attendancePercentage, 100);
    expect(summary.attendanceDeduction, 0);
  });

  test('holidays and approved leave reduce only required working days', () {
    const customPolicy = AttendancePolicyModel(
      weeklyRestDays: [DateTime.friday, DateTime.saturday],
      attendanceThresholdPercent: 98,
      lateCountsAsPresent: true,
    );
    final workingDays = _workingDays(
      '2026-04',
      restDays: customPolicy.weeklyRestDays,
    );
    final holidayDay = workingDays[0];
    final leaveDay = workingDays[1];
    final logs = workingDays
        .skip(2)
        .map((day) => _attendance(day, AttendanceStatus.present))
        .toList();

    final summary = AttendanceSalaryCalculator.calculate(
      month: '2026-04',
      basicSalary: 2200,
      policy: customPolicy,
      attendanceLogs: logs,
      approvedLeaves: [
        LeaveRequestModel(
          id: 'leave-1',
          employeeId: 'emp-1',
          type: LeaveType.official,
          startDate: leaveDay,
          endDate: leaveDay,
          reason: 'annual',
          status: LeaveRequestStatus.approved,
          createdAt: leaveDay,
          updatedAt: leaveDay,
        ),
      ],
      holidayDayKeys: {_dayKey(holidayDay)},
    );

    expect(summary.monthWorkingDays, 21);
    expect(summary.approvedLeaveDays, 1);
    expect(summary.requiredAttendanceDays, 20);
    expect(summary.presentDays, 20);
    expect(summary.attendancePercentage, 100);
    expect(summary.attendanceDeduction, 0);
  });
}

AttendanceModel _attendance(DateTime day, AttendanceStatus status) {
  return AttendanceModel(
    id: day.toIso8601String(),
    employeeId: 'emp-1',
    date: day,
    shiftType: ShiftType.morning,
    checkInTime: day.add(const Duration(hours: 9)),
    status: status,
    createdAt: day,
  );
}

List<DateTime> _workingDays(
  String month, {
  List<int> restDays = const [DateTime.friday],
}) {
  final range = AttendanceSalaryCalculator.monthRange(month);
  final days = <DateTime>[];
  final restDaySet = restDays.toSet();
  var day = range.start;
  while (day.isBefore(range.end)) {
    if (!restDaySet.contains(day.weekday)) {
      days.add(day);
    }
    day = day.add(const Duration(days: 1));
  }
  return days;
}

String _dayKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
