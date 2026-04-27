import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/data/models/attendance_policy_model.dart';
import '../../../leaves/data/models/leave_request_model.dart';

class AttendanceSalarySummary {
  final int monthWorkingDays;
  final int requiredAttendanceDays;
  final int presentDays;
  final int approvedLeaveDays;
  final int absentDays;
  final double attendancePercentage;
  final double attendanceDeduction;
  final double attendanceThresholdPercent;

  const AttendanceSalarySummary({
    required this.monthWorkingDays,
    required this.requiredAttendanceDays,
    required this.presentDays,
    required this.approvedLeaveDays,
    required this.absentDays,
    required this.attendancePercentage,
    required this.attendanceDeduction,
    required this.attendanceThresholdPercent,
  });
}

class AttendanceSalaryCalculator {
  const AttendanceSalaryCalculator._();

  static AttendanceSalarySummary calculate({
    required String month,
    required double basicSalary,
    required AttendancePolicyModel policy,
    required List<AttendanceModel> attendanceLogs,
    required List<LeaveRequestModel> approvedLeaves,
    Set<String> holidayDayKeys = const <String>{},
  }) {
    final range = monthRange(month);
    final workingDays =
        _workingDaysInRange(range, policy.weeklyRestDays, holidayDayKeys);
    final workingDayKeys = workingDays.map(_dayKey).toSet();

    final leaveDayKeys = <String>{};
    for (final leave in approvedLeaves) {
      if (leave.status != LeaveRequestStatus.approved) continue;
      for (final day in _daysBetween(leave.startDate, leave.endDate)) {
        final key = _dayKey(day);
        if (workingDayKeys.contains(key)) {
          leaveDayKeys.add(key);
        }
      }
    }

    final presentDayKeys = <String>{};
    for (final log in attendanceLogs) {
      if (!_isInRange(log.date, range)) continue;
      final key = _dayKey(log.date);
      if (!workingDayKeys.contains(key) || leaveDayKeys.contains(key)) {
        continue;
      }
      if (_countsAsPresent(log.status, policy)) {
        presentDayKeys.add(key);
      }
    }

    final requiredDays = workingDayKeys.length - leaveDayKeys.length;
    final presentDays = presentDayKeys.length;
    final absentDays =
        (requiredDays - presentDays).clamp(0, requiredDays).toInt();
    final attendancePercentage =
        requiredDays == 0 ? 100 : (presentDays / requiredDays) * 100;
    final dailyRate =
        workingDayKeys.isEmpty ? 0 : basicSalary / workingDayKeys.length;
    final deduction =
        attendancePercentage < policy.attendanceThresholdPercent
            ? dailyRate * absentDays
            : 0;

    return AttendanceSalarySummary(
      monthWorkingDays: workingDayKeys.length,
      requiredAttendanceDays: requiredDays,
      presentDays: presentDays,
      approvedLeaveDays: leaveDayKeys.length,
      absentDays: absentDays,
      attendancePercentage: attendancePercentage.toDouble(),
      attendanceDeduction: deduction.toDouble(),
      attendanceThresholdPercent: policy.attendanceThresholdPercent,
    );
  }

  static ({DateTime start, DateTime end}) monthRange(String month) {
    final parts = month.split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid salary month format: $month');
    }
    final year = int.parse(parts[0]);
    final monthNumber = int.parse(parts[1]);
    if (monthNumber < 1 || monthNumber > 12) {
      throw FormatException('Invalid salary month value: $month');
    }
    final start = DateTime(year, monthNumber);
    final end = DateTime(year, monthNumber + 1);
    return (start: start, end: end);
  }

  static bool _countsAsPresent(
    AttendanceStatus status,
    AttendancePolicyModel policy,
  ) {
    return status == AttendanceStatus.present ||
        (policy.lateCountsAsPresent && status == AttendanceStatus.late);
  }

  static List<DateTime> _workingDaysInRange(
    ({DateTime start, DateTime end}) range,
    List<int> weeklyRestDays,
    Set<String> holidayDayKeys,
  ) {
    final restDays = weeklyRestDays.toSet();
    return _daysBetween(range.start, range.end.subtract(const Duration(days: 1)))
        .where((day) =>
            !restDays.contains(day.weekday) &&
            !holidayDayKeys.contains(_dayKey(day)))
        .toList();
  }

  static Iterable<DateTime> _daysBetween(DateTime start, DateTime end) sync* {
    var day = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!day.isAfter(last)) {
      yield day;
      day = day.add(const Duration(days: 1));
    }
  }

  static bool _isInRange(DateTime date, ({DateTime start, DateTime end}) range) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(range.start) && day.isBefore(range.end);
  }

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
