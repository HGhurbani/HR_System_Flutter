import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notifications_providers.dart';
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
  final NotificationsService _notifications;

  LeavesNotifier({
    required FirebaseFirestore firestore,
    required String employeeId,
    required String employeeName,
    required NotificationsService notifications,
  })  : _firestore = firestore,
        _employeeId = employeeId,
        _employeeName = employeeName,
        _notifications = notifications,
        super(const AsyncValue.data(null));

  Future<bool> submitLeaveRequest({
    String? requestId,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? employeeId,
    String? employeeName,
    LeaveRequestStatus initialStatus = LeaveRequestStatus.pending,
    String? adminNote,
    String? adminId,
    String? medicalReportUrl,
    String? medicalReportFileName,
    String? medicalReportContentType,
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
          .doc(requestId);

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
        medicalReportUrl: medicalReportUrl,
        medicalReportFileName: medicalReportFileName,
        medicalReportContentType: medicalReportContentType,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set(request.toMap());
      await _notify(
        title: 'تم تقديم طلب إجازة',
        body: 'تم تقديم طلب إجازة من ${request.employeeName ?? request.employeeId}',
        type: 'leave_created',
        targetUserId: adminNotificationTarget,
      );
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
      final targetDoc = await _firestore
          .collection(AppConstants.leaveRequestsCollection)
          .doc(requestId)
          .get();
      final targetEmployeeId =
          targetDoc.data()?['employeeId'] as String? ?? adminNotificationTarget;
      await _notify(
        title: status == LeaveRequestStatus.approved
            ? 'تم قبول طلب الإجازة'
            : 'تم رفض طلب الإجازة',
        body: adminNote?.isNotEmpty == true
            ? adminNote!
            : 'تم تحديث حالة طلب الإجازة',
        type: 'leave_status_updated',
        targetUserId: targetEmployeeId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateLeaveRequest({
    required String requestId,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required LeaveRequestStatus status,
    required String employeeId,
    String? employeeName,
    String? adminNote,
    String? adminId,
    String? medicalReportUrl,
    String? medicalReportFileName,
    String? medicalReportContentType,
  }) async {
    if (type == LeaveType.emergency &&
        LeaveRequestModel.calendarDurationDays(startDate, endDate) >
            LeaveRequestModel.emergencyLeaveMaxDays) {
      return false;
    }

    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(AppConstants.leaveRequestsCollection)
          .doc(requestId)
          .update({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'type': _typeValue(type),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason.trim(),
        'status': _statusValue(status),
        'adminNote': adminNote,
        'approvedByAdminId':
            status == LeaveRequestStatus.pending ? null : adminId,
        'medicalReportUrl': medicalReportUrl,
        'medicalReportFileName': medicalReportFileName,
        'medicalReportContentType': medicalReportContentType,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _notify(
        title: 'تم تحديث طلب إجازة',
        body: 'تم تحديث بيانات طلب الإجازة',
        type: 'leave_updated',
        targetUserId: employeeId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> _notify({
    required String title,
    required String body,
    required String type,
    required String targetUserId,
  }) async {
    try {
      await _notifications.create(
        title: title,
        body: body,
        type: type,
        targetUserId: targetUserId,
      );
    } catch (_) {}
  }
}

String _typeValue(LeaveType type) {
  switch (type) {
    case LeaveType.official:
      return 'official';
    case LeaveType.sick:
      return 'sick';
    case LeaveType.emergency:
      return 'emergency';
  }
}

String _statusValue(LeaveRequestStatus status) {
  switch (status) {
    case LeaveRequestStatus.approved:
      return 'approved';
    case LeaveRequestStatus.rejected:
      return 'rejected';
    case LeaveRequestStatus.pending:
      return 'pending';
  }
}

final leavesNotifierProvider =
    StateNotifierProvider<LeavesNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return LeavesNotifier(
    firestore: ref.watch(firestoreProvider),
    employeeId: user?.uid ?? '',
    employeeName: user?.fullName ?? '',
    notifications: ref.watch(notificationsServiceProvider),
  );
});
