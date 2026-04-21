import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../../candidates/domain/entities/candidate_status.dart';

class AdminDashboardStats {
  final int totalEmployees;
  final int totalSupervisors;
  final int totalCandidates;
  final int todayPresent;
  final int pendingLeaves;
  final int hiredCandidates;
  final double monthlyPayrollTotal;
  final double monthlyCommissionTotal;
  final Map<String, int> candidateStatusCounts;

  const AdminDashboardStats({
    this.totalEmployees = 0,
    this.totalSupervisors = 0,
    this.totalCandidates = 0,
    this.todayPresent = 0,
    this.pendingLeaves = 0,
    this.hiredCandidates = 0,
    this.monthlyPayrollTotal = 0,
    this.monthlyCommissionTotal = 0,
    this.candidateStatusCounts = const {},
  });
}

final adminDashboardStatsProvider =
    FutureProvider<AdminDashboardStats>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final now = DateTime.now();
  final currentMonth =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final results = await Future.wait([
    firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'employee')
        .where('isActive', isEqualTo: true)
        .count()
        .get(),
    firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'supervisor')
        .where('isActive', isEqualTo: true)
        .count()
        .get(),
    firestore
        .collection(AppConstants.candidateProfilesCollection)
        .count()
        .get(),
    firestore
        .collection(AppConstants.leaveRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .count()
        .get(),
    firestore
        .collection(AppConstants.salariesCollection)
        .where('month', isEqualTo: currentMonth)
        .get(),
    firestore
        .collection(AppConstants.commissionsCollection)
        .where('month', isEqualTo: currentMonth)
        .get(),
    firestore
        .collection(AppConstants.candidateProfilesCollection)
        .get(),
  ]);

  final employeeCount =
      (results[0] as AggregateQuerySnapshot).count ?? 0;
  final supervisorCount =
      (results[1] as AggregateQuerySnapshot).count ?? 0;
  final candidateCount =
      (results[2] as AggregateQuerySnapshot).count ?? 0;
  final pendingLeaves =
      (results[3] as AggregateQuerySnapshot).count ?? 0;
  final payrollDocs =
      (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
  final commissionDocs =
      (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;

  final candidatesDocs =
      (results[6] as QuerySnapshot<Map<String, dynamic>>).docs;
  var hiredCandidates = 0;
  final statusCounts = <String, int>{};
  for (final doc in candidatesDocs) {
    final data = doc.data();
    if (data['convertedEmployeeId'] != null) {
      hiredCandidates++;
    }
    final assignedEmployeeId = data['assignedEmployeeId'] as String?;
    final raw = data['status'] as String? ?? 'available';
    final normalized = assignedEmployeeId != null
        ? CandidateStatus.reserved
        : CandidateStatus.fromString(raw);
    final key = normalized.value;
    statusCounts[key] = (statusCounts[key] ?? 0) + 1;
  }

  final monthlyPayrollTotal = payrollDocs.fold<double>(
    0,
    (sum, doc) => sum + ((doc.data()['netSalary'] as num?)?.toDouble() ?? 0),
  );
  final monthlyCommissionTotal = commissionDocs.fold<double>(
    0,
    (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
  );

  return AdminDashboardStats(
    totalEmployees: employeeCount,
    totalSupervisors: supervisorCount,
    totalCandidates: candidateCount,
    pendingLeaves: pendingLeaves,
    hiredCandidates: hiredCandidates,
    monthlyPayrollTotal: monthlyPayrollTotal,
    monthlyCommissionTotal: monthlyCommissionTotal,
    candidateStatusCounts: statusCounts,
  );
});
