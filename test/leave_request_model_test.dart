import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/leaves/data/models/leave_request_model.dart';

void main() {
  test('medical report fields round trip through Firestore data', () {
    final request = LeaveRequestModel(
      id: 'leave-1',
      employeeId: 'emp-1',
      employeeName: 'Employee One',
      type: LeaveType.sick,
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 2),
      reason: 'Sick leave',
      status: LeaveRequestStatus.pending,
      medicalReportUrl: 'https://example.com/report.pdf',
      medicalReportFileName: 'report.pdf',
      medicalReportContentType: 'application/pdf',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    final map = request.toMap();

    expect(map['medicalReportUrl'], 'https://example.com/report.pdf');
    expect(map['medicalReportFileName'], 'report.pdf');
    expect(map['medicalReportContentType'], 'application/pdf');
    expect(request.hasMedicalReport, isTrue);
  });

  test('duration remains inclusive when medical report fields are present', () {
    final request = LeaveRequestModel(
      id: 'leave-1',
      employeeId: 'emp-1',
      type: LeaveType.sick,
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 3),
      reason: 'Sick leave',
      status: LeaveRequestStatus.pending,
      medicalReportUrl: 'https://example.com/report.jpg',
      medicalReportFileName: 'report.jpg',
      medicalReportContentType: 'image/jpeg',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    expect(request.durationDays, 3);
    expect(request.hasMedicalReport, isTrue);
  });
  test('missing medical report url is treated as no report', () {
    final request = LeaveRequestModel(
      id: 'leave-1',
      employeeId: 'emp-1',
      type: LeaveType.official,
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 1),
      reason: 'Official leave',
      status: LeaveRequestStatus.approved,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    expect(request.medicalReportUrl, isNull);
    expect(request.hasMedicalReport, isFalse);
  });
}
