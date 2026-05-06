import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../application/admin_user_management_providers.dart';
import '../widgets/managed_user_form_sheet.dart';

class ManagedUserDetailScreen extends ConsumerWidget {
  final String userId;

  const ManagedUserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(managedUserProvider(userId));

    return userAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('${context.l10n.error}: $e')),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.errorNotFound)),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              user.role == UserRole.supervisor
                  ? context.l10n.supervisorDetails
                  : context.l10n.employeeDetails,
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditSheet(context, user),
              ),
              IconButton(
                tooltip: context.l10n.disableAccount,
                icon: const Icon(Icons.person_off_outlined),
                onPressed: user.isActive
                    ? () => _disableUser(context, ref, user)
                    : null,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(user: user),
              const SizedBox(height: 12),
              _DetailsCard(user: user),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ManagedUserFormSheet(
        role: user.role,
        editingUser: user,
      ),
    );
  }

  Future<void> _disableUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await context.showConfirmDialog(
      title: context.l10n.disableAccount,
      message: context.l10n.disableAccountMessage,
      confirmLabel: context.l10n.disableAccount,
      isDanger: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(managedUserServiceProvider).disableManagedUser(user);
      if (context.mounted) {
        context.showSnackBar(context.l10n.updateSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final UserModel user;

  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final accentColor =
        user.role == UserRole.supervisor ? AppColors.secondary : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: accentColor.withOpacity(0.15),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Badge(
                        label: _roleLabel(context, user.role),
                        color: accentColor,
                      ),
                      _Badge(
                        label: user.isActive
                            ? context.l10n.active
                            : context.l10n.inactive,
                        color: user.isActive ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.admin:
        return context.l10n.roleAdmin;
      case UserRole.supervisor:
        return context.l10n.roleSupervisor;
      case UserRole.employee:
        return context.l10n.roleEmployee;
    }
  }
}

class _DetailsCard extends StatelessWidget {
  final UserModel user;

  const _DetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DetailRow(label: context.l10n.fullName, value: user.fullName),
            _DetailRow(label: context.l10n.email, value: user.email),
            _DetailRow(label: context.l10n.phone, value: user.phone),
            _DetailRow(
              label: context.l10n.employeeCode,
              value: user.employeeCode,
            ),
            _DetailRow(label: context.l10n.department, value: user.department),
            _DetailRow(label: context.l10n.position, value: user.position),
            _DetailRow(
              label: context.l10n.hireDate,
              value: user.hireDate == null
                  ? null
                  : dateFormat.format(user.hireDate!),
            ),
            _DetailRow(
              label: context.l10n.createdAt,
              value: dateTimeFormat.format(user.createdAt),
            ),
            _DetailRow(
              label: context.l10n.updatedAt,
              value: dateTimeFormat.format(user.updatedAt),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                value?.isNotEmpty == true ? value! : context.l10n.noData,
                textAlign: TextAlign.end,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 24),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
