import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/permissions/data/models/permission_request_model.dart';

void main() {
  test('permission request maps fields and calculates end time', () {
    final start = DateTime(2026, 5, 10, 9, 30);
    final request = PermissionRequestModel(
      id: 'permission-1',
      employeeId: 'emp-1',
      employeeName: 'Employee One',
      date: DateTime(2026, 5, 10),
      startTime: start,
      durationMinutes: 90,
      reason: 'Personal appointment',
      status: PermissionRequestStatus.pending,
      createdAt: DateTime(2026, 5, 9),
      updatedAt: DateTime(2026, 5, 9),
    );

    final map = request.toMap();

    expect(request.endTime, DateTime(2026, 5, 10, 11));
    expect(map['employeeId'], 'emp-1');
    expect(map['employeeName'], 'Employee One');
    expect(map['durationMinutes'], 90);
    expect(map['status'], 'pending');
    expect((map['startTime'] as Timestamp).toDate(), start);
    expect(
      (map['endTime'] as Timestamp).toDate(),
      DateTime(2026, 5, 10, 11),
    );
  });

  test('status values are stable', () {
    expect(
      PermissionRequestModel.statusValue(PermissionRequestStatus.pending),
      'pending',
    );
    expect(
      PermissionRequestModel.statusValue(PermissionRequestStatus.approved),
      'approved',
    );
    expect(
      PermissionRequestModel.statusValue(PermissionRequestStatus.rejected),
      'rejected',
    );
  });
}
