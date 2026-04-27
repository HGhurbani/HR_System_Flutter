import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String month; // Format: yyyy-MM
  final double basicSalary;
  final double additions;
  final double deductions;
  final double attendanceDeduction;
  final double totalDeductions;
  final double commissionRuleAmount;
  final double manualCommissionTotal;
  final double commissionTotal;
  final double netSalary;
  final int monthWorkingDays;
  final int requiredAttendanceDays;
  final int presentDays;
  final int approvedLeaveDays;
  final int absentDays;
  final double attendancePercentage;
  final double attendanceThresholdPercent;
  final bool isApproved;
  final DateTime? approvedAt;
  final String? approvedByAdminId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalaryModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.month,
    required this.basicSalary,
    this.additions = 0,
    this.deductions = 0,
    this.attendanceDeduction = 0,
    double? totalDeductions,
    this.commissionRuleAmount = 0,
    this.manualCommissionTotal = 0,
    this.commissionTotal = 0,
    required this.netSalary,
    this.monthWorkingDays = 0,
    this.requiredAttendanceDays = 0,
    this.presentDays = 0,
    this.approvedLeaveDays = 0,
    this.absentDays = 0,
    this.attendancePercentage = 100,
    this.attendanceThresholdPercent = 98,
    this.isApproved = false,
    this.approvedAt,
    this.approvedByAdminId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  }) : totalDeductions = totalDeductions ?? deductions + attendanceDeduction;

  factory SalaryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SalaryModel(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      employeeCode: data['employeeCode'] as String?,
      month: data['month'] as String? ?? '',
      basicSalary:
          (data['basicSalary'] as num?)?.toDouble() ?? 0,
      additions: (data['additions'] as num?)?.toDouble() ?? 0,
      deductions: (data['deductions'] as num?)?.toDouble() ?? 0,
      attendanceDeduction:
          (data['attendanceDeduction'] as num?)?.toDouble() ?? 0,
      totalDeductions: (data['totalDeductions'] as num?)?.toDouble(),
      commissionRuleAmount:
          (data['commissionRuleAmount'] as num?)?.toDouble() ?? 0,
      manualCommissionTotal:
          (data['manualCommissionTotal'] as num?)?.toDouble() ?? 0,
      commissionTotal:
          (data['commissionTotal'] as num?)?.toDouble() ?? 0,
      netSalary:
          (data['netSalary'] as num?)?.toDouble() ?? 0,
      monthWorkingDays:
          (data['monthWorkingDays'] as num?)?.toInt() ?? 0,
      requiredAttendanceDays:
          (data['requiredAttendanceDays'] as num?)?.toInt() ?? 0,
      presentDays: (data['presentDays'] as num?)?.toInt() ?? 0,
      approvedLeaveDays:
          (data['approvedLeaveDays'] as num?)?.toInt() ?? 0,
      absentDays: (data['absentDays'] as num?)?.toInt() ?? 0,
      attendancePercentage:
          (data['attendancePercentage'] as num?)?.toDouble() ?? 100,
      attendanceThresholdPercent:
          (data['attendanceThresholdPercent'] as num?)?.toDouble() ?? 98,
      isApproved: data['isApproved'] as bool? ?? false,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedByAdminId: data['approvedByAdminId'] as String?,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'month': month,
      'basicSalary': basicSalary,
      'additions': additions,
      'deductions': deductions,
      'attendanceDeduction': attendanceDeduction,
      'totalDeductions': totalDeductions,
      'commissionRuleAmount': commissionRuleAmount,
      'manualCommissionTotal': manualCommissionTotal,
      'commissionTotal': commissionTotal,
      'netSalary': netSalary,
      'monthWorkingDays': monthWorkingDays,
      'requiredAttendanceDays': requiredAttendanceDays,
      'presentDays': presentDays,
      'approvedLeaveDays': approvedLeaveDays,
      'absentDays': absentDays,
      'attendancePercentage': attendancePercentage,
      'attendanceThresholdPercent': attendanceThresholdPercent,
      'isApproved': isApproved,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedByAdminId': approvedByAdminId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class CommissionModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String month;
  final double amount;
  final String? reason;
  final String? source;
  final String? notes;
  final String? createdByAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommissionModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.month,
    required this.amount,
    this.reason,
    this.source,
    this.notes,
    this.createdByAdminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CommissionModel(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      employeeCode: data['employeeCode'] as String?,
      month: data['month'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      reason: data['reason'] as String?,
      source: data['source'] as String?,
      notes: data['notes'] as String?,
      createdByAdminId: data['createdByAdminId'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'month': month,
      'amount': amount,
      'reason': reason,
      'source': source,
      'notes': notes,
      'createdByAdminId': createdByAdminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
