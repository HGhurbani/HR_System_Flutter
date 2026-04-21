import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/application/auth_providers.dart';
import '../employee_shell_scaffold.dart';

class EmployeeProfileScreen extends ConsumerWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openEmployeeShellDrawer,
        ),
        title: Text(l10n.myProfile),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  if (user?.position != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.position!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                  if (user?.employeeCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '#${user!.employeeCode}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileCard(
                    title: l10n.profile,
                    items: [
                      _ProfileItem(
                        icon: Icons.email_outlined,
                        label: l10n.email,
                        value: user?.email ?? '-',
                      ),
                      if (user?.phone != null)
                        _ProfileItem(
                          icon: Icons.phone_outlined,
                          label: l10n.phone,
                          value: user!.phone!,
                        ),
                      if (user?.department != null)
                        _ProfileItem(
                          icon: Icons.business_outlined,
                          label: l10n.department,
                          value: user!.department!,
                        ),
                      if (user?.hireDate != null)
                        _ProfileItem(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.hireDate,
                          value: DateFormat('d MMMM yyyy')
                              .format(user!.hireDate!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      title: Text(l10n.logout,
                          style: const TextStyle(
                              color: AppColors.error)),
                      onTap: () async {
                        final confirm =
                            await context.showConfirmDialog(
                          title: l10n.logout,
                          message: l10n.logoutConfirm,
                          isDanger: true,
                        );
                        if (confirm == true) {
                          ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ProfileCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(title,
                  style: context.textTheme.titleMedium),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: context.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      subtitle: Text(value, style: context.textTheme.bodyMedium),
    );
  }
}
