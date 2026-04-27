import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String targetUserId;
  final String actorUserId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetUserId,
    required this.actorUserId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      targetUserId: data['targetUserId'] as String? ?? '',
      actorUserId: data['actorUserId'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
