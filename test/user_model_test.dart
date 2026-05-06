import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/auth/data/models/user_model.dart';
import 'package:hr_sys/features/auth/domain/entities/app_user.dart';
import 'package:hr_sys/features/auth/domain/entities/user_role.dart';

void main() {
  test('legacy user documents default to company rest days', () {
    final user = UserModel.fromMap({
      'fullName': 'Employee One',
      'email': 'employee@example.com',
      'role': 'employee',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
      'updatedAt': Timestamp.fromDate(DateTime(2026)),
    }, 'emp-1');

    expect(user.weeklyRestDaysMode, AppUser.weeklyRestDaysModeCompany);
    expect(user.customWeeklyRestDays, isEmpty);
    expect(user.effectiveWeeklyRestDays([DateTime.friday]), [DateTime.friday]);
  });

  test('custom weekly rest days round-trip through user map', () {
    final user = UserModel(
      uid: 'emp-1',
      fullName: 'Employee One',
      email: 'employee@example.com',
      role: UserRole.employee,
      weeklyRestDaysMode: AppUser.weeklyRestDaysModeCustom,
      customWeeklyRestDays: const [DateTime.saturday, DateTime.friday],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final map = user.toMap();
    final restored = UserModel.fromMap(map, user.uid);

    expect(map['weeklyRestDaysMode'], AppUser.weeklyRestDaysModeCustom);
    expect(map['customWeeklyRestDays'], [DateTime.saturday, DateTime.friday]);
    expect(restored.weeklyRestDaysMode, AppUser.weeklyRestDaysModeCustom);
    expect(restored.customWeeklyRestDays, [DateTime.friday, DateTime.saturday]);
    expect(restored.effectiveWeeklyRestDays([DateTime.friday]),
        [DateTime.friday, DateTime.saturday]);
  });

  test('empty or invalid custom rest days fall back to company rest days', () {
    final emptyCustom = UserModel.fromMap({
      'fullName': 'Employee One',
      'email': 'employee@example.com',
      'role': 'employee',
      'weeklyRestDaysMode': 'custom',
      'customWeeklyRestDays': const [],
      'createdAt': Timestamp.fromDate(DateTime(2026)),
      'updatedAt': Timestamp.fromDate(DateTime(2026)),
    }, 'emp-1');

    final invalidCustom = UserModel.fromMap({
      'fullName': 'Employee Two',
      'email': 'employee2@example.com',
      'role': 'employee',
      'weeklyRestDaysMode': 'custom',
      'customWeeklyRestDays': const [1, 2, 3, 4, 5, 6, 7],
      'createdAt': Timestamp.fromDate(DateTime(2026)),
      'updatedAt': Timestamp.fromDate(DateTime(2026)),
    }, 'emp-2');

    expect(emptyCustom.effectiveWeeklyRestDays([DateTime.friday]),
        [DateTime.friday]);
    expect(invalidCustom.customWeeklyRestDays, isEmpty);
    expect(invalidCustom.effectiveWeeklyRestDays([DateTime.saturday]),
        [DateTime.saturday]);
  });
}
