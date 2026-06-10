import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/attendance/application/attendance_report_pdf_service.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_model.dart';
import 'package:hr_sys/features/attendance/data/models/attendance_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final isArabic in [true, false]) {
    test('builds a multi-page ${isArabic ? 'Arabic' : 'English'} PDF',
        () async {
      final start = DateTime(2026, 1, 1);
      final rows = List.generate(
        100,
        (index) => AttendanceReportRow(
          employeeId: 'employee-$index',
          employeeName: isArabic ? 'موظف $index' : 'Employee $index',
          date: start.add(Duration(days: index % 30)),
          shiftType: ShiftType.morning,
          checkInTime: start.add(const Duration(hours: 8)),
          checkOutTime: start.add(const Duration(hours: 16)),
          status:
              index.isEven ? AttendanceStatus.present : AttendanceStatus.absent,
          latenessMinutes: index % 12,
        ),
      );

      const service = AttendanceReportPdfService();
      final bytes = await service.build(
        range: AttendanceDateRange(
          start: start,
          end: DateTime(2026, 1, 30),
        ),
        rows: rows,
        isArabic: isArabic,
      );

      expect(bytes.length, greaterThan(1000));
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    });
  }
}
