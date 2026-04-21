import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../data/models/leave_request_model.dart';

// ─── Employee's Own Leave Requests ────────────────────────────────────────
final myLeaveRequestsProvider =
    StreamProvider<List<LeaveRequestModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.leaveRequestsCollection)
      .where('employeeId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(LeaveRequestModel.fromFirestore).toList());
});

// ─── All Leave Requests (Admin) ────────────────────────────────────────────
final allLeaveRequestsProvider =
    StreamProvider<List<LeaveRequestModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.leaveRequestsCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(LeaveRequestModel.fromFirestore).toList());
});

final pendingLeaveRequestsProvider =
    StreamProvider<List<LeaveRequestModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.leaveRequestsCollection)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(LeaveRequestModel.fromFirestore).toList());
});

// ─── Leave Notifier ────────────────────────────────────────────────────────
class LeavesNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final String _employeeId;
  final String _employeeName;

  LeavesNotifier({
    required FirebaseFirestore firestore,
    required String employeeId,
    required String employeeName,
  })  : _firestore = firestore,
        _employeeId = employeeId,
        _employeeName = employeeName,
        super(const AsyncValue.data(null));

  Future<bool> submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? employeeId,
    String? employeeName,
    LeaveRequestStatus initialStatus = LeaveRequestStatus.pending,
    String? adminNote,
    String? adminId,
  }) async {
    if (type == LeaveType.emergency &&
        LeaveRequestModel.calendarDurationDays(startDate, endDate) >
            LeaveRequestModel.emergencyLeaveMaxDays) {
      return false;
    }

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final doc = _firestore
          .collection(AppConstants.leaveRequestsCollection)
          .doc();

      final request = LeaveRequestModel(
        id: doc.id,
        employeeId: employeeId ?? _employeeId,
        employeeName: employeeName ?? _employeeName,
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        status: initialStatus,
        adminNote: adminNote,
        approvedByAdminId: adminId,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set(request.toMap());
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateRequestStatus({
    required String requestId,
    required LeaveRequestStatus status,
    String? adminNote,
    String? adminId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(AppConstants.leaveRequestsCollection)
          .doc(requestId)
          .update({
        'status': status == LeaveRequestStatus.approved
            ? 'approved'
            : 'rejected',
        'adminNote': adminNote,
        'approvedByAdminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final leavesNotifierProvider =
    StateNotifierProvider<LeavesNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return LeavesNotifier(
    firestore: ref.watch(firestoreProvider),
    employeeId: user?.uid ?? '',
    employeeName: user?.fullName ?? '',
  );
});
