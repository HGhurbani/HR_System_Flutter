import '../data/models/attendance_model.dart';
import '../data/models/company_work_schedule.dart';
import '../../permissions/data/models/permission_request_model.dart';

String formatLatenessDuration(int minutes) {
  final safeMinutes = minutes < 0 ? 0 : minutes;
  final hours = safeMinutes ~/ 60;
  final remainingMinutes = safeMinutes % 60;
  return '$hours:${remainingMinutes.toString().padLeft(2, '0')}';
}

int effectiveLatenessMinutes({
  required AttendanceModel attendance,
  required CompanyWorkSchedule workSchedule,
  required Iterable<PermissionRequestModel> approvedPermissions,
}) {
  final checkInTime = attendance.checkInTime;
  if (checkInTime == null || attendance.latenessMinutes <= 0) {
    return 0;
  }

  final shiftStart = workSchedule.shiftStartOnDay(
    attendance.date,
    attendance.shiftType,
  );
  final lateStart = shiftStart;
  final lateEnd = checkInTime.isAfter(lateStart) ? checkInTime : lateStart;
  if (!lateEnd.isAfter(lateStart)) return 0;

  final coveredMinutes = _coveredMinutes(
    start: lateStart,
    end: lateEnd,
    ranges: approvedPermissions
        .where((permission) => permission.isApproved)
        .map((permission) => (
              start: permission.startTime,
              end: permission.endTime,
            )),
  );

  final effective = attendance.latenessMinutes - coveredMinutes;
  return effective < 0 ? 0 : effective;
}

int _coveredMinutes({
  required DateTime start,
  required DateTime end,
  required Iterable<({DateTime start, DateTime end})> ranges,
}) {
  final overlaps = <({DateTime start, DateTime end})>[];
  for (final range in ranges) {
    final overlapStart = range.start.isAfter(start) ? range.start : start;
    final overlapEnd = range.end.isBefore(end) ? range.end : end;
    if (overlapEnd.isAfter(overlapStart)) {
      overlaps.add((start: overlapStart, end: overlapEnd));
    }
  }
  if (overlaps.isEmpty) return 0;

  overlaps.sort((a, b) => a.start.compareTo(b.start));
  var mergedStart = overlaps.first.start;
  var mergedEnd = overlaps.first.end;
  var total = 0;

  for (final overlap in overlaps.skip(1)) {
    if (!overlap.start.isAfter(mergedEnd)) {
      if (overlap.end.isAfter(mergedEnd)) {
        mergedEnd = overlap.end;
      }
      continue;
    }
    total += mergedEnd.difference(mergedStart).inMinutes;
    mergedStart = overlap.start;
    mergedEnd = overlap.end;
  }

  total += mergedEnd.difference(mergedStart).inMinutes;
  return total;
}
