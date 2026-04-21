import 'package:cloud_firestore/cloud_firestore.dart';

/// ثلاثة أنواع: رسمية، مرضية، اضطرارية (الأخيرة بحد أقصى [emergencyLeaveMaxDays] أيام).
enum LeaveType { official, sick, emergency }

enum LeaveRequestStatus { pending, approved, rejected }

class LeaveRequestModel {
  /// Max duration in days for [LeaveType.emergency].
  static const int emergencyLeaveMaxDays = 3;

  final String id;
  final String employeeId;
  final String? employeeName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveRequestStatus status;
  final String? adminNote;
  final String? approvedByAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveRequestModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.adminNote,
    this.approvedByAdminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return LeaveRequestModel(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      type: _parseType(data['type'] as String? ?? 'official'),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] as String? ?? '',
      status: _parseStatus(data['status'] as String? ?? 'pending'),
      adminNote: data['adminNote'] as String?,
      approvedByAdminId: data['approvedByAdminId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': _typeString(type),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': _statusString(status),
      'adminNote': adminNote,
      'approvedByAdminId': approvedByAdminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static LeaveType _parseType(String value) {
    switch (value) {
      case 'official':
        return LeaveType.official;
      case 'sick':
        return LeaveType.sick;
      case 'emergency':
        return LeaveType.emergency;
      case 'annual':
      case 'unpaid':
      case 'permission':
        return LeaveType.official;
      default:
        return LeaveType.official;
    }
  }

  static LeaveRequestStatus _parseStatus(String value) {
    switch (value) {
      case 'approved':
        return LeaveRequestStatus.approved;
      case 'rejected':
        return LeaveRequestStatus.rejected;
      default:
        return LeaveRequestStatus.pending;
    }
  }

  static String _typeString(LeaveType t) {
    switch (t) {
      case LeaveType.official:
        return 'official';
      case LeaveType.sick:
        return 'sick';
      case LeaveType.emergency:
        return 'emergency';
    }
  }

  static String _statusString(LeaveRequestStatus s) {
    switch (s) {
      case LeaveRequestStatus.approved:
        return 'approved';
      case LeaveRequestStatus.rejected:
        return 'rejected';
      default:
        return 'pending';
    }
  }

  /// Inclusive calendar days from start date through end date.
  int get durationDays => calendarDurationDays(startDate, endDate);

  static int calendarDurationDays(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    if (e.isBefore(s)) return 0;
    return e.difference(s).inDays + 1;
  }

  /// Whether this request exceeds the emergency leave day cap.
  bool get exceedsEmergencyLimit =>
      type == LeaveType.emergency &&
      durationDays > emergencyLeaveMaxDays;
}

