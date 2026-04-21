import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/models/user_model.dart';
import '../data/models/employee_compensation_model.dart';
import '../data/models/salary_model.dart';

final mySalariesProvider = StreamProvider<List<SalaryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.salariesCollection)
      .where('employeeId', isEqualTo: user.uid)
      .orderBy('month', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(SalaryModel.fromFirestore).toList());
});

final myCommissionsProvider = StreamProvider<List<CommissionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.commissionsCollection)
      .where('employeeId', isEqualTo: user.uid)
      .orderBy('month', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(CommissionModel.fromFirestore).toList());
});

final allSalariesProvider = StreamProvider<List<SalaryModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.salariesCollection)
      .orderBy('month', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(SalaryModel.fromFirestore).toList());
});

final allCommissionsProvider = StreamProvider<List<CommissionModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.commissionsCollection)
      .orderBy('month', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(CommissionModel.fromFirestore).toList());
});

final employeeCompensationProfilesProvider =
    StreamProvider<List<EmployeeCompensationModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.employeeCompensationCollection)
      .orderBy('employeeName')
      .snapshots()
      .map((snap) =>
          snap.docs.map(EmployeeCompensationModel.fromFirestore).toList());
});

final employeeCompensationProvider =
    StreamProvider.family<EmployeeCompensationModel?, String>((ref, employeeId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.employeeCompensationCollection)
      .doc(employeeId)
      .snapshots()
      .map((doc) =>
          doc.exists ? EmployeeCompensationModel.fromFirestore(doc) : null);
});

class SalaryAdminNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final String _adminId;

  SalaryAdminNotifier({
    required FirebaseFirestore firestore,
    required String adminId,
  })  : _firestore = firestore,
        _adminId = adminId,
        super(const AsyncValue.data(null));

  Future<bool> saveCompensationProfile(
    EmployeeCompensationModel profile,
  ) async {
    state = const AsyncValue.loading();
    try {
      final existing = await _firestore
          .collection(AppConstants.employeeCompensationCollection)
          .doc(profile.employeeId)
          .get();

      final createdAt = existing.data()?['createdAt'] != null
          ? (existing.data()!['createdAt'] as Timestamp).toDate()
          : profile.createdAt;

      await _firestore
          .collection(AppConstants.employeeCompensationCollection)
          .doc(profile.employeeId)
          .set(
        profile.copyWith(
          createdAt: createdAt,
          updatedAt: DateTime.now(),
        ).toMap(),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addCommission({
    required UserModel employee,
    required String month,
    required double amount,
    required String reason,
    required String source,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final doc = _firestore
          .collection(AppConstants.commissionsCollection)
          .doc();
      final now = DateTime.now();
      final commission = CommissionModel(
        id: doc.id,
        employeeId: employee.uid,
        employeeName: employee.fullName,
        employeeCode: employee.employeeCode,
        month: month,
        amount: amount,
        reason: reason.trim(),
        source: source,
        notes: notes?.trim(),
        createdByAdminId: _adminId,
        createdAt: now,
        updatedAt: now,
      );
      await doc.set(commission.toMap());
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> generateSalary({
    required UserModel employee,
    required String month,
    required double additions,
    required double deductions,
    String? notes,
    bool approve = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final compensationDoc = await _firestore
          .collection(AppConstants.employeeCompensationCollection)
          .doc(employee.uid)
          .get();

      if (!compensationDoc.exists || compensationDoc.data() == null) {
        throw const AppException(
          message: 'Compensation profile not found for employee',
          code: 'compensation-profile-not-found',
        );
      }

      final profile =
          EmployeeCompensationModel.fromFirestore(compensationDoc);

      final commissionsSnap = await _firestore
          .collection(AppConstants.commissionsCollection)
          .where('employeeId', isEqualTo: employee.uid)
          .where('month', isEqualTo: month)
          .get();

      final manualCommissionTotal = commissionsSnap.docs.fold<double>(
        0,
        (sum, doc) =>
            sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
      );

      final ruleAmount = profile.calculateRuleCommission();
      final commissionTotal = manualCommissionTotal + ruleAmount;
      final netSalary =
          profile.basicSalary + additions + commissionTotal - deductions;

      final now = DateTime.now();
      final docId = '${employee.uid}_$month';
      final salary = SalaryModel(
        id: docId,
        employeeId: employee.uid,
        employeeName: employee.fullName,
        employeeCode: employee.employeeCode,
        month: month,
        basicSalary: profile.basicSalary,
        additions: additions,
        deductions: deductions,
        commissionRuleAmount: ruleAmount,
        manualCommissionTotal: manualCommissionTotal,
        commissionTotal: commissionTotal,
        netSalary: netSalary,
        isApproved: approve,
        approvedAt: approve ? now : null,
        approvedByAdminId: approve ? _adminId : null,
        notes: notes?.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(AppConstants.salariesCollection)
          .doc(docId)
          .set(salary.toMap(), SetOptions(merge: true));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final salaryAdminNotifierProvider =
    StateNotifierProvider<SalaryAdminNotifier, AsyncValue<void>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return SalaryAdminNotifier(
    firestore: ref.watch(firestoreProvider),
    adminId: currentUser?.uid ?? '',
  );
});

extension on EmployeeCompensationModel {
  EmployeeCompensationModel copyWith({
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? position,
    double? basicSalary,
    bool? isCommissionEligible,
    CommissionRuleType? commissionRuleType,
    double? commissionRuleValue,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeCompensationModel(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      position: position ?? this.position,
      basicSalary: basicSalary ?? this.basicSalary,
      isCommissionEligible:
          isCommissionEligible ?? this.isCommissionEligible,
      commissionRuleType: commissionRuleType ?? this.commissionRuleType,
      commissionRuleValue: commissionRuleValue ?? this.commissionRuleValue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
