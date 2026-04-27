import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../data/models/app_notification_model.dart';

const adminNotificationTarget = 'admin';

final notificationsStreamProvider =
    StreamProvider<List<AppNotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  Query<Map<String, dynamic>> query =
      firestore.collection(AppConstants.notificationsCollection);

  if (!user.role.isAdmin) {
    query = query.where('targetUserId', isEqualTo: user.uid);
  }

  if (user.role.isAdmin) {
    query = query.orderBy('createdAt', descending: true).limit(100);
  }

  return query.snapshots().map((snap) {
    final notifications =
        snap.docs.map(AppNotificationModel.fromFirestore).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications.take(100).toList();
  });
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull;
  return notifications?.where((item) => !item.isRead).length ?? 0;
});

class NotificationsService {
  final FirebaseFirestore _firestore;
  final String _actorUserId;

  const NotificationsService({
    required FirebaseFirestore firestore,
    required String actorUserId,
  })  : _firestore = firestore,
        _actorUserId = actorUserId;

  Future<void> create({
    required String title,
    required String body,
    required String type,
    required String targetUserId,
  }) async {
    if (_actorUserId.isEmpty || targetUserId.isEmpty) return;
    await _firestore.collection(AppConstants.notificationsCollection).add({
      'title': title,
      'body': body,
      'type': type,
      'targetUserId': targetUserId,
      'actorUserId': _actorUserId,
      'isRead': false,
      'readAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String id) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(id)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(List<AppNotificationModel> notifications) async {
    final unread = notifications.where((item) => !item.isRead).toList();
    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (final notification in unread) {
      batch.update(
        _firestore
            .collection(AppConstants.notificationsCollection)
            .doc(notification.id),
        {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
  }
}

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final user = ref.watch(currentUserProvider);
  return NotificationsService(
    firestore: ref.watch(firestoreProvider),
    actorUserId: user?.uid ?? '',
  );
});
