import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../application/notifications_providers.dart';
import '../../data/models/app_notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) => TextButton(
              onPressed: notifications.any((item) => !item.isRead)
                  ? () => ref
                      .read(notificationsServiceProvider)
                      .markAllAsRead(notifications)
                  : null,
              child: Text(context.l10n.markAllRead),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const ShimmerList(count: 8, itemHeight: 86),
        error: (e, _) => Center(child: Text('${context.l10n.error}: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return EmptyState(
              message: context.l10n.noNotifications,
              icon: Icons.notifications_none_rounded,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _NotificationTile(
              notification: notifications[index],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM yyyy - hh:mm a');
    final color = notification.isRead
        ? AppColors.textSecondary
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(_iconForType(notification.type), color: color),
        ),
        title: Text(
          notification.title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(notification.createdAt),
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                tooltip: context.l10n.markAllRead,
                icon: const Icon(Icons.done_rounded),
                onPressed: () => ref
                    .read(notificationsServiceProvider)
                    .markAsRead(notification.id),
              ),
      ),
    );
  }

  IconData _iconForType(String type) {
    if (type.startsWith('salary') || type.startsWith('commission')) {
      return Icons.payments_outlined;
    }
    if (type.startsWith('leave')) return Icons.event_note_outlined;
    if (type.startsWith('attendance')) return Icons.access_time_outlined;
    if (type.startsWith('candidate')) return Icons.folder_outlined;
    if (type.startsWith('user')) return Icons.person_add_alt_outlined;
    return Icons.notifications_outlined;
  }
}
