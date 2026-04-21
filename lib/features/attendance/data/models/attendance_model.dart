import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late, onLeave, holiday }

enum ShiftType { morning, evening }

class AttendanceModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime date;
  final ShiftType shiftType;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final bool insideGeofence;
  final AttendanceStatus status;
  final int latenessMinutes;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.date,
    required this.shiftType,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.insideGeofence = true,
    required this.status,
    this.latenessMinutes = 0,
    required this.createdAt,
  });

  factory AttendanceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AttendanceModel(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      shiftType: data['shiftType'] == 'evening'
          ? ShiftType.evening
          : ShiftType.morning,
      checkInTime: data['checkInTime'] != null
          ? (data['checkInTime'] as Timestamp).toDate()
          : null,
      checkOutTime: data['checkOutTime'] != null
          ? (data['checkOutTime'] as Timestamp).toDate()
          : null,
      checkInLat: (data['checkInLat'] as num?)?.toDouble(),
      checkInLng: (data['checkInLng'] as num?)?.toDouble(),
      checkOutLat: (data['checkOutLat'] as num?)?.toDouble(),
      checkOutLng: (data['checkOutLng'] as num?)?.toDouble(),
      insideGeofence: data['insideGeofence'] as bool? ?? true,
      status: _parseStatus(data['status'] as String? ?? 'present'),
      latenessMinutes:
          (data['latenessMinutes'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static AttendanceStatus _parseStatus(String value) {
    switch (value) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'on_leave':
        return AttendanceStatus.onLeave;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.present;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
      'shiftType': shiftType == ShiftType.morning ? 'morning' : 'evening',
      'checkInTime':
          checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime':
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkInLat': checkInLat,
      'checkInLng': checkInLng,
      'checkOutLat': checkOutLat,
      'checkOutLng': checkOutLng,
      'insideGeofence': insideGeofence,
      'status': _statusString(status),
      'latenessMinutes': latenessMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static String _statusString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.onLeave:
        return 'on_leave';
      case AttendanceStatus.holiday:
        return 'holiday';
      default:
        return 'present';
    }
  }
}
