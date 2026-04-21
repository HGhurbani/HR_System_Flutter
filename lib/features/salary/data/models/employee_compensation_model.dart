import 'package:cloud_firestore/cloud_firestore.dart';

enum CommissionRuleType {
  none,
  fixed,
  percentage;

  static CommissionRuleType fromString(String? value) {
    switch (value) {
      case 'fixed':
        return CommissionRuleType.fixed;
      case 'percentage':
        return CommissionRuleType.percentage;
      default:
        return CommissionRuleType.none;
    }
  }

  String get value {
    switch (this) {
      case CommissionRuleType.fixed:
        return 'fixed';
      case CommissionRuleType.percentage:
        return 'percentage';
      case CommissionRuleType.none:
        return 'none';
    }
  }
}

class EmployeeCompensationModel {
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? position;
  final double basicSalary;
  final bool isCommissionEligible;
  final CommissionRuleType commissionRuleType;
  final double commissionRuleValue;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmployeeCompensationModel({
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.position,
    required this.basicSalary,
    this.isCommissionEligible = false,
    this.commissionRuleType = CommissionRuleType.none,
    this.commissionRuleValue = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeCompensationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return EmployeeCompensationModel(
      employeeId: doc.id,
      employeeName: data['employeeName'] as String?,
      employeeCode: data['employeeCode'] as String?,
      position: data['position'] as String?,
      basicSalary: (data['basicSalary'] as num?)?.toDouble() ?? 0,
      isCommissionEligible: data['isCommissionEligible'] as bool? ?? false,
      commissionRuleType:
          CommissionRuleType.fromString(data['commissionRuleType'] as String?),
      commissionRuleValue:
          (data['commissionRuleValue'] as num?)?.toDouble() ?? 0,
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
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'position': position,
      'basicSalary': basicSalary,
      'isCommissionEligible': isCommissionEligible,
      'commissionRuleType': commissionRuleType.value,
      'commissionRuleValue': commissionRuleValue,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  double calculateRuleCommission() {
    if (!isCommissionEligible) return 0;
    switch (commissionRuleType) {
      case CommissionRuleType.fixed:
        return commissionRuleValue;
      case CommissionRuleType.percentage:
        return basicSalary * (commissionRuleValue / 100);
      case CommissionRuleType.none:
        return 0;
    }
  }
}
