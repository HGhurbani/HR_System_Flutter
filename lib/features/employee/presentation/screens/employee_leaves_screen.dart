import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../leaves/application/leaves_providers.dart';
import '../../../leaves/data/models/leave_request_model.dart';
import '../../../leaves/presentation/widgets/leave_request_form_sheet.dart';
import '../employee_shell_scaffold.dart';

class EmployeeLeavesScreen extends ConsumerWidget {
  const EmployeeLeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final leavesAsync = ref.watch(myLeaveRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openEmployeeShellDrawer,
        ),
        title: Text(l10n.myLeaves),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addLeaveRequest),
      ),
      body: leavesAsync.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 90),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (leaves) {
          if (leaves.isEmpty) {
            return EmptyState(
              message: l10n.noLeaves,
              icon: Icons.event_busy_outlined,
              actionLabel: l10n.addLeaveRequest,
              onAction: () => _showSubmitSheet(context, ref),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _LeaveRequestTile(request: leaves[i]),
          );
        },
      ),
    );
  }

  void _showSubmitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LeaveRequestFormSheet(
        title: context.l10n.addLeaveRequest,
        submitLabel: context.l10n.submit,
      ),
    );
  }
}

class _LeaveRequestTile extends StatelessWidget {
  final LeaveRequestModel request;

  const _LeaveRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM');
    final statusColor = _statusColor(request.status);
    final typeColor =
        AppColors.adaptiveForegroundColor(context, AppColors.primary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(request.type, l10n),
                    style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(request.status, l10n),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.date_range_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${dateFormat.format(request.startDate)} - ${dateFormat.format(request.endDate)}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '(${request.durationDays} ${context.l10n.date})',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                request.reason,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (request.adminNote?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.adminNote!,
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(LeaveRequestStatus s) {
    switch (s) {
      case LeaveRequestStatus.approved:
        return AppColors.leaveApproved;
      case LeaveRequestStatus.rejected:
        return AppColors.leaveRejected;
      default:
        return AppColors.leavePending;
    }
  }

  String _statusLabel(LeaveRequestStatus s, l10n) {
    switch (s) {
      case LeaveRequestStatus.approved:
        return l10n.approvedStatus;
      case LeaveRequestStatus.rejected:
        return l10n.rejectedStatus;
      default:
        return l10n.pendingStatus;
    }
  }

  String _typeLabel(LeaveType t, l10n) {
    switch (t) {
      case LeaveType.official:
        return l10n.leaveTypeAnnual;
      case LeaveType.sick:
        return l10n.leaveTypeSick;
      case LeaveType.emergency:
        return l10n.leaveTypeEmergency;
    }
  }
}
