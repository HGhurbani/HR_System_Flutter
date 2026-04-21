import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/candidates_providers.dart';
import '../../data/models/candidate_model.dart';
import '../../domain/entities/candidate_status.dart';
import '../widgets/candidate_cv_image_viewer.dart';

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

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, l10n),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!candidate.isImageOnlyProfile) ...[
                  _buildInfoCard(context, l10n),
                  const SizedBox(height: 12),
                ],
                _buildPersonalCard(context, l10n),
                const SizedBox(height: 12),
                if (candidate.cvFileUrl?.isNotEmpty == true)
                  _buildMediaCard(context, l10n),
                if (candidate.cvFileUrl?.isNotEmpty == true)
                  const SizedBox(height: 12),
                if (candidate.notes?.isNotEmpty == true)
                  _buildNotesCard(context, l10n),
                if (candidate.notes?.isNotEmpty == true)
                  const SizedBox(height: 12),
                if (user?.role.canManageCandidates == true)
                  _buildActionsCard(context, ref, l10n),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic l10n) {
    final statusColor = _statusColor(candidate.status);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          GestureDetector(
            onTap: candidate.imageUrl == null
                ? null
                : () =>
                    showCandidateCvImageViewer(context, candidate.imageUrl!),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 320),
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: candidate.imageUrl != null
                  ? Image.network(
                      candidate.imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_rounded,
                      size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            candidate.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          StatusBadge(
            label: _statusLabel(candidate.status, l10n),
            color: statusColor,
            fontSize: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, dynamic l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.candidateDetails, style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: l10n.nationality,
              value: _nationalityLabel(candidate.nationality, l10n),
            ),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: l10n.age,
              value: '${candidate.age} ${l10n.year}',
            ),
            _InfoRow(
              icon: Icons.work_outline,
              label: l10n.experience,
              value: '${candidate.experienceYears} ${l10n.year}',
            ),
            if (candidate.jobType?.isNotEmpty == true)
              _InfoRow(
                icon: Icons.business_center_outlined,
                label: l10n.jobType,
                value: candidate.jobType!,
              ),
            if (candidate.spokenLanguages.isNotEmpty)
              _InfoRow(
                icon: Icons.translate_outlined,
                label: l10n.spokenLanguages,
                value: candidate.spokenLanguages.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard(BuildContext context, dynamic l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.maritalStatus, style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!candidate.isImageOnlyProfile) ...[
              if (candidate.religion != null)
                _InfoRow(
                  icon: Icons.church_outlined,
                  label: l10n.religion,
                  value: candidate.religion!,
                ),
              if (candidate.maritalStatus != null)
                _InfoRow(
                  icon: Icons.favorite_outline,
                  label: l10n.maritalStatus,
                  value: candidate.maritalStatus!,
                ),
            ],
            if (candidate.assignedEmployeeName != null)
              _InfoRow(
                icon: Icons.person_pin_outlined,
                label: l10n.assignedTo,
                value: candidate.assignedEmployeeName!,
                valueColor: AppColors.primary,
              ),
            if (candidate.convertedEmployeeId != null)
              _InfoRow(
                icon: Icons.badge_outlined,
                label: l10n.employeeCode,
                value: candidate.convertedEmployeeId!,
                valueColor: AppColors.statusCompleted,
              ),
            if (candidate.createdBySupervisorName != null)
              _InfoRow(
                icon: Icons.supervisor_account_outlined,
                label: l10n.createdBy,
                value: candidate.createdBySupervisorName!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, dynamic l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.details, style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (candidate.cvFileUrl?.isNotEmpty == true)
              OutlinedButton.icon(
                onPressed: () => launchUrlString(candidate.cvFileUrl!),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l10n.cvFile),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, dynamic l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.notes, style: context.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(candidate.notes!, style: context.textTheme.bodyMedium),
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
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                  radius: 16,
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: _statusColor(status),
                  ),
                ),
                title: Text(_statusLabel(status, l10n)),
                selected: candidate.status == status,
                selectedTileColor: _statusColor(status).withOpacity(0.08),
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
                          context.showSnackBar(success
                              ? l10n.updateSuccess
                              : l10n.errorGeneral);
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

  String _nationalityLabel(CandidateNationality n, dynamic l10n) {
    switch (n) {
      case CandidateNationality.philippines:
        return l10n.nationalityPhilippines;
      case CandidateNationality.kenya:
        return l10n.nationalityKenya;
      case CandidateNationality.uganda:
        return l10n.nationalityUganda;
      case CandidateNationality.ethiopia:
        return l10n.nationalityEthiopia;
      case CandidateNationality.bangladesh:
        return l10n.nationalityBangladesh;
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
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
