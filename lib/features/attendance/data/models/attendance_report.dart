import '../../../auth/domain/entities/app_user.dart';
import '../../../leaves/data/models/leave_request_model.dart';
import 'attendance_model.dart';

class AttendanceDateRange {
  final DateTime start;
  final DateTime end;

  AttendanceDateRange({required DateTime start, required DateTime end})
      : start = dateOnly(start),
        end = dateOnly(end) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError('Attendance range end must not precede start');
    }
  }

  DateTime get endExclusive => end.add(const Duration(days: 1));

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  bool operator ==(Object other) =>
      other is AttendanceDateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

class AttendanceReportRow {
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final ShiftType? shiftType;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final int latenessMinutes;
  final bool isSynthetic;

  const AttendanceReportRow({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.shiftType,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.latenessMinutes = 0,
    this.isSynthetic = false,
  });

  factory AttendanceReportRow.fromAttendance(AttendanceModel attendance) {
    return AttendanceReportRow(
      employeeId: attendance.employeeId,
      employeeName: attendance.employeeName ?? attendance.employeeId,
      date: AttendanceDateRange.dateOnly(attendance.date),
      shiftType: attendance.shiftType,
      checkInTime: attendance.checkInTime,
      checkOutTime: attendance.checkOutTime,
      status: attendance.status,
      latenessMinutes: attendance.latenessMinutes,
    );
  }
}

class AttendanceReportBuilder {
  const AttendanceReportBuilder._();

  static List<AttendanceReportRow> build({
    required AttendanceDateRange range,
    required List<AppUser> employees,
    required List<AttendanceModel> attendanceLogs,
    required List<LeaveRequestModel> approvedLeaves,
    required List<int> companyWeeklyRestDays,
    required Set<String> holidayDayKeys,
  }) {
    final rows = <AttendanceReportRow>[];
    final logsByEmployeeDay = <String, AttendanceModel>{};

    for (final log in attendanceLogs) {
      final day = AttendanceDateRange.dateOnly(log.date);
      if (day.isBefore(range.start) || day.isAfter(range.end)) continue;
      logsByEmployeeDay[_employeeDayKey(log.employeeId, day)] = log;
    }

    final employeesById = {
      for (final employee in employees) employee.uid: employee
    };
    for (final log in logsByEmployeeDay.values) {
      final employee = employeesById[log.employeeId];
      rows.add(
        AttendanceReportRow(
          employeeId: log.employeeId,
          employeeName:
              log.employeeName ?? employee?.fullName ?? log.employeeId,
          date: AttendanceDateRange.dateOnly(log.date),
          shiftType: log.shiftType,
          checkInTime: log.checkInTime,
          checkOutTime: log.checkOutTime,
          status: log.status,
          latenessMinutes: log.latenessMinutes,
        ),
      );
    }

    final approvedLeaveDays = <String>{};
    for (final leave in approvedLeaves) {
      if (leave.status != LeaveRequestStatus.approved) continue;
      var day = AttendanceDateRange.dateOnly(leave.startDate);
      final leaveEnd = AttendanceDateRange.dateOnly(leave.endDate);
      while (!day.isAfter(leaveEnd)) {
        if (!day.isBefore(range.start) && !day.isAfter(range.end)) {
          approvedLeaveDays.add(_employeeDayKey(leave.employeeId, day));
        }
        day = day.add(const Duration(days: 1));
      }
    }

    for (final employee in employees.where((employee) => employee.isActive)) {
      final restDays =
          employee.effectiveWeeklyRestDays(companyWeeklyRestDays).toSet();
      var day = range.start;
      while (!day.isAfter(range.end)) {
        final key = _employeeDayKey(employee.uid, day);
        final hiredAfterDay = employee.hireDate != null &&
            AttendanceDateRange.dateOnly(employee.hireDate!).isAfter(day);
        final isNonWorkingDay = restDays.contains(day.weekday) ||
            holidayDayKeys.contains(dayKey(day));

        if (!logsByEmployeeDay.containsKey(key) &&
            !hiredAfterDay &&
            !isNonWorkingDay) {
          rows.add(
            AttendanceReportRow(
              employeeId: employee.uid,
              employeeName: employee.fullName,
              date: day,
              status: approvedLeaveDays.contains(key)
                  ? AttendanceStatus.onLeave
                  : AttendanceStatus.absent,
              isSynthetic: true,
            ),
          );
        }
        day = day.add(const Duration(days: 1));
      }
    }

    rows.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return a.employeeName.toLowerCase().compareTo(
            b.employeeName.toLowerCase(),
          );
    });
    return List.unmodifiable(rows);
  }

  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String _employeeDayKey(String employeeId, DateTime day) =>
      '$employeeId:${dayKey(day)}';
}
