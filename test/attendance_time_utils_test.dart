import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/attendance/application/attendance_time_utils.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_model.dart';
import 'package:hr_sys/features/attendance/data/models/company_work_schedule.dart';

void main() {
  const schedule = CompanyWorkSchedule();

  test('shift correction recalculates lateness with the selected shift', () {
    final checkIn = DateTime(2026, 10, 22, 16, 20);
    final morning = attendanceForShift(
      checkInTime: checkIn,
      shiftType: ShiftType.morning,
      workSchedule: schedule,
    );
    final evening = attendanceForShift(
      checkInTime: checkIn,
      shiftType: ShiftType.evening,
      workSchedule: schedule,
    );
    expect(morning.latenessMinutes, 500);
    expect(morning.status, AttendanceStatus.late);
    expect(evening.latenessMinutes, 20);
    expect(evening.status, AttendanceStatus.late);
  });

  test('early departure stops at the scheduled end', () {
    final day = DateTime(2026, 10, 22);
    expect(
      earlyDepartureMinutes(
        checkOutTime: DateTime(2026, 10, 22, 15, 30),
        attendanceDate: day,
        shiftType: ShiftType.morning,
        workSchedule: schedule,
      ),
      30,
    );
    expect(
      earlyDepartureMinutes(
        checkOutTime: DateTime(2026, 10, 22, 16),
        attendanceDate: day,
        shiftType: ShiftType.morning,
        workSchedule: schedule,
      ),
      0,
    );
  });

  test('correction closes after checkout or on the next day', () {
    final day = DateTime(2026, 10, 22);
    AttendanceModel attendance(DateTime? checkout) => AttendanceModel(
          id: '1',
          employeeId: 'employee',
          date: day,
          shiftType: ShiftType.morning,
          checkInTime: day.add(const Duration(hours: 8)),
          checkOutTime: checkout,
          status: AttendanceStatus.present,
          createdAt: day,
        );
    expect(canCorrectShift(attendance(null), day.add(const Duration(hours: 9))),
        isTrue);
    expect(
        canCorrectShift(attendance(day.add(const Duration(hours: 16))),
            day.add(const Duration(hours: 17))),
        isFalse);
    expect(canCorrectShift(attendance(null), day.add(const Duration(days: 1))),
        isFalse);
  });
}
