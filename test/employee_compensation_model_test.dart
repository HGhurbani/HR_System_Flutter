import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/salary/data/models/employee_compensation_model.dart';

void main() {
  test('fixed commission rule returns fixed amount', () {
    const profile = EmployeeCompensationModel(
      employeeId: 'emp-1',
      basicSalary: 4000,
      isCommissionEligible: true,
      commissionRuleType: CommissionRuleType.fixed,
      commissionRuleValue: 500,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    expect(profile.calculateRuleCommission(), 500);
  });

  test('percentage commission rule uses basic salary', () {
    const profile = EmployeeCompensationModel(
      employeeId: 'emp-1',
      basicSalary: 4000,
      isCommissionEligible: true,
      commissionRuleType: CommissionRuleType.percentage,
      commissionRuleValue: 10,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    expect(profile.calculateRuleCommission(), 400);
  });
}
