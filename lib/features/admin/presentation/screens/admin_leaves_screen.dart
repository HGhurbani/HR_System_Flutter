import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../leaves/application/leaves_providers.dart';
import '../../../leaves/data/models/leave_request_model.dart';
import '../../../leaves/presentation/widgets/leave_request_form_sheet.dart';
import '../../../candidates/presentation/widgets/candidate_cv_file_viewer.dart';
import '../admin_shell_scaffold.dart';

class AdminLeavesScreen extends ConsumerWidget {
  const AdminLeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final leavesAsync = ref.watch(allLeaveRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.leaveManagement),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLeaveSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addLeaveRequest),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(tabs: [
              Tab(text: l10n.pendingStatus),
              Tab(text: l10n.all),
            ]),
            Expanded(
              child: leavesAsync.when(
                loading: () => const ShimmerList(count: 5, itemHeight: 100),
                error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                data: (leaves) {
                  final pending = leaves
                      .where((l) => l.status == LeaveRequestStatus.pending)
                      .toList();

                  return TabBarView(
                    children: [
                      _LeaveList(leaves: pending, isAdmin: true),
                      _LeaveList(leaves: leaves, isAdmin: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddLeaveSheet(BuildContext context, WidgetRef ref) async {
    try {
      final employees = await ref.read(employeesProvider.future);
      if (employees.isEmpty) {
        context.showSnackBar(context.l10n.noEmployees, isError: true);
        return;
      }

      final adminUser = ref.read(currentUserProvider);
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => LeaveRequestFormSheet(
          title: context.l10n.addLeaveRequest,
          submitLabel: context.l10n.save,
          employeeOptions: employees,
          requireEmployeeSelection: true,
          approveImmediately: true,
          adminId: adminUser?.uid,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }
}

class _LeaveList extends ConsumerWidget {
  final List<LeaveRequestModel> leaves;
  final bool isAdmin;

  const _LeaveList({required this.leaves, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (leaves.isEmpty) {
      return EmptyState(
        message: l10n.noLeaves,
        icon: Icons.event_busy_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AdminLeaveCard(request: leaves[i]),
    );
  }
}

class _AdminLeaveCard extends ConsumerWidget {
  final LeaveRequestModel request;

  const _AdminLeaveCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM yyyy');
    final isPending = request.status == LeaveRequestStatus.pending;
    final brandColor =
        AppColors.adaptiveForegroundColor(context, AppColors.primary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: brandColor.withOpacity(0.1),
                  child: Text(
                    request.employeeName?.isNotEmpty == true
                        ? request.employeeName![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: brandColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.employeeName ?? '-',
                          style: context.textTheme.titleMedium),
                      Text(
                        '${dateFormat.format(request.startDate)} → ${dateFormat.format(request.endDate)}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(request.reason, style: context.textTheme.bodyMedium),
            if (request.medicalReportUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _openMedicalReport(context, request),
                icon: const Icon(Icons.description_outlined),
                label: Text(
                  request.medicalReportFileName ?? l10n.medicalReport,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _showEditSheet(context, ref, request),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.edit),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _handleAction(context, ref, request, approve: false),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.error),
                      label: Text(l10n.reject,
                          style: const TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handleAction(context, ref, request, approve: true),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.approve),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMedicalReport(BuildContext context, LeaveRequestModel request) {
    final contentType = request.medicalReportContentType ?? '';
    final url = request.medicalReportUrl ?? '';
    final isPdf = contentType == 'application/pdf' ||
        url.toLowerCase().contains('.pdf');
    showCandidateCvFileViewer(
      context,
      imageUrl: !isPdf && url.isNotEmpty ? url : null,
      pdfUrl: isPdf ? url : null,
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    LeaveRequestModel request,
  ) async {
    try {
      final employees = await ref.read(employeesProvider.future);
      final adminUser = ref.read(currentUserProvider);
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => LeaveRequestFormSheet(
          title: context.l10n.editLeaveRequest,
          submitLabel: context.l10n.save,
          employeeOptions: employees,
          requireEmployeeSelection: true,
          initialRequest: request,
          allowStatusEditing: true,
          adminId: adminUser?.uid,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    LeaveRequestModel request, {
    required bool approve,
  }) async {
    final l10n = context.l10n;
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? l10n.approve : l10n.reject),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(labelText: l10n.adminNote),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.error,
            ),
            child: Text(approve ? l10n.approve : l10n.reject),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminUser = ref.read(currentUserProvider);
      await ref.read(leavesNotifierProvider.notifier).updateRequestStatus(
            requestId: request.id,
            status: approve
                ? LeaveRequestStatus.approved
                : LeaveRequestStatus.rejected,
            adminNote: noteController.text.trim(),
            adminId: adminUser?.uid,
          );
      if (context.mounted) {
        context.showSnackBar(approve ? l10n.leaveApproved : l10n.leaveRejected);
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final LeaveRequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Color color;
    String label;

    switch (status) {
      case LeaveRequestStatus.approved:
        color = AppColors.leaveApproved;
        label = l10n.approvedStatus;
        break;
      case LeaveRequestStatus.rejected:
        color = AppColors.leaveRejected;
        label = l10n.rejectedStatus;
        break;
      default:
        color = AppColors.leavePending;
        label = l10n.pendingStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
