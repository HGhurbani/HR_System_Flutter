import 'package:cloud_firestore/cloud_firestore.dart';

enum PermissionRequestStatus { pending, approved, rejected }

class PermissionRequestModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime date;
  final DateTime startTime;
  final int durationMinutes;
  final DateTime endTime;
  final String reason;
  final PermissionRequestStatus status;
  final String? adminNote;
  final String? approvedByAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PermissionRequestModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    DateTime? endTime,
    required this.reason,
    required this.status,
    this.adminNote,
    this.approvedByAdminId,
    required this.createdAt,
    required this.updatedAt,
  }) : endTime = endTime ?? startTime.add(Duration(minutes: durationMinutes));

  factory PermissionRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final durationMinutes = (data['durationMinutes'] as num?)?.toInt() ?? 0;
    return PermissionRequestModel(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ??
          DateTime(startTime.year, startTime.month, startTime.day),
      startTime: startTime,
      durationMinutes: durationMinutes,
      endTime: (data['endTime'] as Timestamp?)?.toDate() ??
          startTime.add(Duration(minutes: durationMinutes)),
      reason: data['reason'] as String? ?? '',
      status: _parseStatus(data['status'] as String? ?? 'pending'),
      adminNote: data['adminNote'] as String?,
      approvedByAdminId: data['approvedByAdminId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'endTime': Timestamp.fromDate(endTime),
      'reason': reason,
      'status': statusValue(status),
      'adminNote': adminNote,
      'approvedByAdminId': approvedByAdminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static PermissionRequestStatus _parseStatus(String value) {
    switch (value) {
      case 'approved':
        return PermissionRequestStatus.approved;
      case 'rejected':
        return PermissionRequestStatus.rejected;
      default:
        return PermissionRequestStatus.pending;
    }
  }

  static String statusValue(PermissionRequestStatus status) {
    switch (status) {
      case PermissionRequestStatus.approved:
        return 'approved';
      case PermissionRequestStatus.rejected:
        return 'rejected';
      case PermissionRequestStatus.pending:
        return 'pending';
    }
  }

  bool get isApproved => status == PermissionRequestStatus.approved;
}
