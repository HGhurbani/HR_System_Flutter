import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notifications_providers.dart';
import '../data/models/permission_request_model.dart';

final myPermissionRequestsProvider =
    StreamProvider<List<PermissionRequestModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.permissionRequestsCollection)
      .where('employeeId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(PermissionRequestModel.fromFirestore).toList());
});

final allPermissionRequestsProvider =
    StreamProvider<List<PermissionRequestModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.permissionRequestsCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(PermissionRequestModel.fromFirestore).toList());
});

typedef EmployeeDayQuery = ({String employeeId, DateTime day});

final approvedPermissionRequestsForDayProvider =
    StreamProvider.family<List<PermissionRequestModel>, EmployeeDayQuery>(
  (ref, query) {
    if (query.employeeId.isEmpty) return const Stream.empty();
    final firestore = ref.watch(firestoreProvider);
    final day = DateTime(query.day.year, query.day.month, query.day.day);
    final nextDay = day.add(const Duration(days: 1));

    return firestore
        .collection(AppConstants.permissionRequestsCollection)
        .where('employeeId', isEqualTo: query.employeeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .snapshots()
        .map((snap) => snap.docs
            .map(PermissionRequestModel.fromFirestore)
            .where(
                (request) => request.status == PermissionRequestStatus.approved)
            .toList());
  },
);

class PermissionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final String _employeeId;
  final String _employeeName;
  final NotificationsService _notifications;

  PermissionsNotifier({
    required FirebaseFirestore firestore,
    required String employeeId,
    required String employeeName,
    required NotificationsService notifications,
  })  : _firestore = firestore,
        _employeeId = employeeId,
        _employeeName = employeeName,
        _notifications = notifications,
        super(const AsyncValue.data(null));

  Future<bool> submitPermissionRequest({
    required DateTime date,
    required DateTime startTime,
    required int durationMinutes,
    required String reason,
  }) async {
    if (durationMinutes <= 0) return false;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final doc = _firestore
          .collection(AppConstants.permissionRequestsCollection)
          .doc();
      final request = PermissionRequestModel(
        id: doc.id,
        employeeId: _employeeId,
        employeeName: _employeeName,
        date: DateTime(date.year, date.month, date.day),
        startTime: startTime,
        durationMinutes: durationMinutes,
        reason: reason.trim(),
        status: PermissionRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set(request.toMap());
      await _notify(
        title: 'تم تقديم طلب إذن',
        body:
            'تم تقديم طلب إذن من ${request.employeeName ?? request.employeeId}',
        type: 'permission_created',
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
    required PermissionRequestStatus status,
    String? adminNote,
    String? adminId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(AppConstants.permissionRequestsCollection)
          .doc(requestId)
          .update({
        'status': PermissionRequestModel.statusValue(status),
        'adminNote': adminNote,
        'approvedByAdminId':
            status == PermissionRequestStatus.pending ? null : adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final targetDoc = await _firestore
          .collection(AppConstants.permissionRequestsCollection)
          .doc(requestId)
          .get();
      final targetEmployeeId =
          targetDoc.data()?['employeeId'] as String? ?? adminNotificationTarget;
      await _notify(
        title: status == PermissionRequestStatus.approved
            ? 'تم قبول طلب الإذن'
            : 'تم رفض طلب الإذن',
        body: adminNote?.isNotEmpty == true
            ? adminNote!
            : 'تم تحديث حالة طلب الإذن',
        type: 'permission_status_updated',
        targetUserId: targetEmployeeId,
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

final permissionsNotifierProvider =
    StateNotifierProvider<PermissionsNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return PermissionsNotifier(
    firestore: ref.watch(firestoreProvider),
    employeeId: user?.uid ?? '',
    employeeName: user?.fullName ?? '',
    notifications: ref.watch(notificationsServiceProvider),
  );
});
