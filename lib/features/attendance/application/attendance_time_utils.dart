import '../data/models/attendance_model.dart';
import '../data/models/company_work_schedule.dart';

({int latenessMinutes, AttendanceStatus status}) attendanceForShift({
  required DateTime checkInTime,
  required ShiftType shiftType,
  required CompanyWorkSchedule workSchedule,
}) {
  final start = workSchedule.shiftStartOnDay(checkInTime, shiftType);
  final minutes =
      checkInTime.isAfter(start) ? checkInTime.difference(start).inMinutes : 0;
  final grace = workSchedule.graceMinutesFor(shiftType, day: checkInTime);
  return (
    latenessMinutes: minutes,
    status: minutes > grace ? AttendanceStatus.late : AttendanceStatus.present,
  );
}

int earlyDepartureMinutes({
  required DateTime checkOutTime,
  required DateTime attendanceDate,
  required ShiftType shiftType,
  required CompanyWorkSchedule workSchedule,
}) {
  final end = workSchedule.shiftEndOnDay(attendanceDate, shiftType);
  if (!checkOutTime.isBefore(end)) return 0;
  return (end.difference(checkOutTime).inSeconds + 59) ~/ 60;
}

bool canCorrectShift(AttendanceModel attendance, DateTime now) =>
    attendance.checkInTime != null &&
    attendance.checkOutTime == null &&
    attendance.date.year == now.year &&
    attendance.date.month == now.month &&
    attendance.date.day == now.day;
