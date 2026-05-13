import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/candidate_cv_share_service.dart';
import '../../application/candidates_providers.dart';
import '../../data/models/candidate_model.dart';
import '../../domain/entities/candidate_status.dart';
import '../widgets/candidate_cv_file_viewer.dart';

class CandidateDetailScreen extends ConsumerWidget {
  final String candidateId;

  const CandidateDetailScreen({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final candidateAsync = ref.watch(candidateDetailProvider(candidateId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.candidateProfile),
        actions: [
          if (currentUser?.role.isAdmin == true)
            candidateAsync.maybeWhen(
              data: (candidate) => candidate == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: l10n.share,
                      onPressed: () => _shareCandidate(context, candidate),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          if (currentUser?.role.canManageCandidates == true)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                final basePath = currentUser!.role.isAdmin
                    ? AppRoutes.adminCandidates
                    : AppRoutes.supervisorCandidates;
                context.push('$basePath/$candidateId/edit');
              },
            ),
          if (currentUser?.role.isAdmin == true)
            candidateAsync.maybeWhen(
              data: (candidate) => candidate == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () =>
                          _deleteCandidate(context, ref, candidate),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: candidateAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (candidate) {
          if (candidate == null) {
            return Center(child: Text(l10n.errorNotFound));
          }
          return _CandidateDetailBody(
            candidate: candidate,
            user: currentUser,
          );
        },
      ),
    );
  }

  Future<void> _shareCandidate(
    BuildContext context,
    CandidateModel candidate,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Flexible(child: Text(context.l10n.preparingCvFiles)),
          ],
        ),
      ),
    );

    try {
      final result = await const CandidateCvShareService().shareCandidates(
        [candidate],
        sharePositionOrigin: _sharePositionOrigin(context),
      );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (result.sharedCount == 0) {
        context.showSnackBar(context.l10n.noCvFileToShare, isError: true);
      }
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.showSnackBar(context.l10n.shareCvFailed, isError: true);
    }
  }

  Future<void> _deleteCandidate(
    BuildContext context,
    WidgetRef ref,
    CandidateModel candidate,
  ) async {
    final confirmed = await context.showConfirmDialog(
      title: context.l10n.confirmDelete,
      message: context.l10n.confirmDeleteMessage,
      confirmLabel: context.l10n.delete,
      isDanger: true,
    );
    if (confirmed != true) return;

    final success =
        await ref.read(candidatesNotifierProvider.notifier).deleteCandidate(
              candidate.id,
              imageUrl: candidate.imageUrl,
              cvFileUrl: candidate.cvFileUrl,
            );
    if (!context.mounted) return;
    if (success) {
      context.showSnackBar(context.l10n.deleteSuccess);
      context.go(AppRoutes.adminCandidates);
    } else {
      context.showSnackBar(context.l10n.errorGeneral, isError: true);
    }
  }

  Rect? _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _CandidateDetailBody extends ConsumerWidget {
  final CandidateModel candidate;
  final dynamic user;

  const _CandidateDetailBody({
    required this.candidate,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(child: _buildFileViewer(context)),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReservationSummary(context, l10n),
                if (user?.role.canManageCandidates == true) ...[
                  const SizedBox(height: 12),
                  _buildActionsCard(context, ref, l10n),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileViewer(BuildContext context) {
    final imageUrl = candidate.imageUrl;
    final pdfUrl = candidate.cvFileUrl;
    final hasFile = imageUrl?.isNotEmpty == true || pdfUrl?.isNotEmpty == true;

    return ColoredBox(
      color: Colors.black,
      child: !hasFile
          ? const Center(
              child: Icon(
                Icons.description_outlined,
                size: 56,
                color: Colors.white,
              ),
            )
          : Center(
              child: CandidateCvFileViewer(
                imageUrl: imageUrl,
                pdfUrl: pdfUrl,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
                fit: BoxFit.contain,
                placeholder: const ColoredBox(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReservationSummary(BuildContext context, dynamic l10n) {
    final statusColor = _statusColor(candidate.status);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.fullName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  label: _statusLabel(candidate.status, l10n),
                  color: statusColor,
                  fontSize: 12,
                ),
              ],
            ),
            if (candidate.assignedEmployeeName != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.person_pin_outlined,
                label: l10n.assignedTo,
                value: candidate.assignedEmployeeName!,
                valueColor: AppColors.primary,
              ),
            ],
            if (candidate.reservedByUserName != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.lock_outline_rounded,
                label: l10n.reservedBy,
                value: candidate.reservedByUserName!,
              ),
            ],
            if (candidate.createdBySupervisorName != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.supervisor_account_outlined,
                label: l10n.createdBy,
                value: candidate.createdBySupervisorName!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, WidgetRef ref, dynamic l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.actions, style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showStatusSheet(context, ref, l10n),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(l10n.changeStatus),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAssignSheet(context, ref, l10n),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: Text(l10n.assignCandidate),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, dynamic l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.changeStatus, style: context.textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...CandidateStatus.values.map(
              (status) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                  radius: 16,
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: _statusColor(status),
                  ),
                ),
                title: Text(_statusLabel(status, l10n)),
                selected: candidate.status == status,
                selectedTileColor: _statusColor(status).withValues(alpha: 0.08),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(candidatesNotifierProvider.notifier)
                      .updateStatus(candidate.id, status);
                  if (context.mounted) {
                    context.showSnackBar(l10n.updateSuccess);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext context, WidgetRef ref, dynamic l10n) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final employeesAsync = ref.watch(employeesProvider);
          return employeesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${l10n.error}: $e'),
            ),
            data: (employees) {
              if (employees.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noEmployees),
                );
              }

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.assignCandidate,
                      style: context.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ...employees.map(
                    (employee) => ListTile(
                      leading: CircleAvatar(
                        child: Text(employee.fullName[0].toUpperCase()),
                      ),
                      title: Text(employee.fullName),
                      subtitle: Text(
                        employee.position?.isNotEmpty == true
                            ? employee.position!
                            : employee.email,
                      ),
                      onTap: () async {
                        final success = await ref
                            .read(candidatesNotifierProvider.notifier)
                            .assignToEmployee(
                              candidate.id,
                              employee.uid,
                              employee.fullName,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.showSnackBar(
                              success ? l10n.updateSuccess : l10n.errorGeneral);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(CandidateStatus status) {
    switch (status) {
      case CandidateStatus.available:
        return AppColors.statusAvailable;
      case CandidateStatus.reserved:
        return AppColors.statusReserved;
    }
  }

  String _statusLabel(CandidateStatus s, dynamic l10n) {
    switch (s) {
      case CandidateStatus.available:
        return l10n.statusAvailable;
      case CandidateStatus.reserved:
        return l10n.statusReserved;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValueColor = valueColor == null
        ? null
        : AppColors.adaptiveForegroundColor(context, valueColor!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: effectiveValueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
