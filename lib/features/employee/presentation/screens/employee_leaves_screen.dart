import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../candidates/presentation/widgets/candidate_cv_file_viewer.dart';
import '../../../leaves/application/leaves_providers.dart';
import '../../../leaves/data/models/leave_request_model.dart';
import '../../../leaves/presentation/widgets/leave_request_form_sheet.dart';
import '../../../permissions/application/permissions_providers.dart';
import '../../../permissions/data/models/permission_request_model.dart';
import '../../../permissions/presentation/widgets/permission_request_form_sheet.dart';
import '../employee_shell_scaffold.dart';

class EmployeeLeavesScreen extends ConsumerStatefulWidget {
  const EmployeeLeavesScreen({super.key});

  @override
  ConsumerState<EmployeeLeavesScreen> createState() =>
      _EmployeeLeavesScreenState();
}

class _EmployeeLeavesScreenState extends ConsumerState<EmployeeLeavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leavesAsync = ref.watch(myLeaveRequestsProvider);
    final permissionsAsync = ref.watch(myPermissionRequestsProvider);
    final showingPermissions = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openEmployeeShellDrawer,
        ),
        title: Text(l10n.myRequests),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.leaves),
            Tab(text: l10n.permissionRequest),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showingPermissions
            ? _showPermissionSheet(context)
            : _showLeaveSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          showingPermissions ? l10n.addPermissionRequest : l10n.addLeaveRequest,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          leavesAsync.when(
            loading: () => const ShimmerList(count: 5, itemHeight: 90),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (leaves) {
              if (leaves.isEmpty) {
                return EmptyState(
                  message: l10n.noLeaves,
                  icon: Icons.event_busy_outlined,
                  actionLabel: l10n.addLeaveRequest,
                  onAction: () => _showLeaveSheet(context),
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
          permissionsAsync.when(
            loading: () => const ShimmerList(count: 5, itemHeight: 90),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (permissions) {
              if (permissions.isEmpty) {
                return EmptyState(
                  message: l10n.noPermissions,
                  icon: Icons.schedule_outlined,
                  actionLabel: l10n.addPermissionRequest,
                  onAction: () => _showPermissionSheet(context),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: permissions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _PermissionRequestTile(request: permissions[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLeaveSheet(BuildContext context) {
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

  void _showPermissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PermissionRequestFormSheet(),
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusBadge(
                  label: _statusLabel(request.status, l10n),
                  color: statusColor,
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
                  '${dateFormat.format(request.startDate)} - '
                  '${dateFormat.format(request.endDate)}',
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
            if (request.medicalReportUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => _openMedicalReport(context, request),
                icon: const Icon(Icons.description_outlined),
                label: Text(
                  request.medicalReportFileName ?? l10n.medicalReport,
                ),
              ),
            ],
            if (request.adminNote?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _AdminNote(note: request.adminNote!, color: statusColor),
            ],
          ],
        ),
      ),
    );
  }

  void _openMedicalReport(BuildContext context, LeaveRequestModel request) {
    final contentType = request.medicalReportContentType ?? '';
    final url = request.medicalReportUrl ?? '';
    final isPdf =
        contentType == 'application/pdf' || url.toLowerCase().contains('.pdf');
    showCandidateCvFileViewer(
      context,
      imageUrl: !isPdf && url.isNotEmpty ? url : null,
      pdfUrl: isPdf ? url : null,
    );
  }

  Color _statusColor(LeaveRequestStatus status) {
    switch (status) {
      case LeaveRequestStatus.approved:
        return AppColors.leaveApproved;
      case LeaveRequestStatus.rejected:
        return AppColors.leaveRejected;
      default:
        return AppColors.leavePending;
    }
  }

  String _statusLabel(LeaveRequestStatus status, dynamic l10n) {
    switch (status) {
      case LeaveRequestStatus.approved:
        return l10n.approvedStatus;
      case LeaveRequestStatus.rejected:
        return l10n.rejectedStatus;
      default:
        return l10n.pendingStatus;
    }
  }

  String _typeLabel(LeaveType type, dynamic l10n) {
    switch (type) {
      case LeaveType.official:
        return l10n.leaveTypeAnnual;
      case LeaveType.sick:
        return l10n.leaveTypeSick;
      case LeaveType.emergency:
        return l10n.leaveTypeEmergency;
    }
  }
}

class _PermissionRequestTile extends StatelessWidget {
  final PermissionRequestModel request;

  const _PermissionRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final statusColor = _statusColor(request.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.permissionRequest,
                    style: context.textTheme.titleMedium),
                const Spacer(),
                _StatusBadge(
                  label: _statusLabel(request.status, l10n),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${dateFormat.format(request.date)} - '
                    '${timeFormat.format(request.startTime)} - '
                    '${timeFormat.format(request.endTime)}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.permissionHours}: '
              '${(request.durationMinutes / 60).toStringAsFixed(1)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
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
              _AdminNote(note: request.adminNote!, color: statusColor),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(PermissionRequestStatus status) {
    switch (status) {
      case PermissionRequestStatus.approved:
        return AppColors.leaveApproved;
      case PermissionRequestStatus.rejected:
        return AppColors.leaveRejected;
      case PermissionRequestStatus.pending:
        return AppColors.leavePending;
    }
  }

  String _statusLabel(PermissionRequestStatus status, dynamic l10n) {
    switch (status) {
      case PermissionRequestStatus.approved:
        return l10n.approvedStatus;
      case PermissionRequestStatus.rejected:
        return l10n.rejectedStatus;
      case PermissionRequestStatus.pending:
        return l10n.pendingStatus;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _AdminNote extends StatelessWidget {
  final String note;
  final Color color;

  const _AdminNote({required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.comment_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              style: context.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
