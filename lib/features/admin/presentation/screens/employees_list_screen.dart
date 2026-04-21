import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../widgets/managed_user_form_sheet.dart';
import '../admin_shell_scaffold.dart';

class EmployeesListScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const EmployeesListScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final employeesAsync = ref.watch(employeesProvider);
    final supervisorsAsync = ref.watch(supervisorsProvider);
    final currentRole =
        _tabController.index == 0 ? UserRole.employee : UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.employeeManagement),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(context)
              .appBarTheme
              .foregroundColor
              ?.withValues(alpha: 0.72),
          indicatorColor: Theme.of(context).appBarTheme.foregroundColor,
          tabs: [
            Tab(text: l10n.employees),
            Tab(text: l10n.supervisors),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(context, currentRole),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          currentRole == UserRole.employee
              ? l10n.addEmployee
              : l10n.addSupervisor,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: '${l10n.search}...',
              leading: const Icon(Icons.search),
              trailing: _searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ]
                  : null,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UsersTab(
                  usersAsync: employeesAsync,
                  searchQuery: _searchQuery,
                  emptyMessage: l10n.noEmployees,
                  emptyAction: l10n.addEmployee,
                  emptyIcon: Icons.people_outline,
                  onAction: () => _showAddUserSheet(context, UserRole.employee),
                ),
                _UsersTab(
                  usersAsync: supervisorsAsync,
                  searchQuery: _searchQuery,
                  emptyMessage: l10n.noSupervisors,
                  emptyAction: l10n.addSupervisor,
                  emptyIcon: Icons.supervisor_account_outlined,
                  onAction: () =>
                      _showAddUserSheet(context, UserRole.supervisor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserSheet(BuildContext context, UserRole role) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ManagedUserFormSheet(role: role),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final AsyncValue<List<UserModel>> usersAsync;
  final String searchQuery;
  final String emptyMessage;
  final String emptyAction;
  final IconData emptyIcon;
  final VoidCallback onAction;

  const _UsersTab({
    required this.usersAsync,
    required this.searchQuery,
    required this.emptyMessage,
    required this.emptyAction,
    required this.emptyIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return usersAsync.when(
      loading: () => const ShimmerList(count: 8),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (users) {
        final filtered = searchQuery.isEmpty
            ? users
            : users.where((user) {
                return user.fullName.toLowerCase().contains(searchQuery) ||
                    (user.employeeCode ?? '')
                        .toLowerCase()
                        .contains(searchQuery) ||
                    user.email.toLowerCase().contains(searchQuery);
              }).toList();

        if (filtered.isEmpty) {
          return EmptyState(
            message: emptyMessage,
            icon: emptyIcon,
            actionLabel: emptyAction,
            onAction: onAction,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _UserTile(user: filtered[index]),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        user.role == UserRole.supervisor ? AppColors.secondary : AppColors.primary;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: accentColor.withOpacity(0.15),
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                )
              : null,
        ),
        title: Text(user.fullName, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (user.position != null && user.position!.isNotEmpty)
              Text(
                user.position!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (user.employeeCode != null && user.employeeCode!.isNotEmpty)
              Text(
                '#${user.employeeCode}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.isActive
                ? AppColors.success.withOpacity(0.12)
                : AppColors.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user.isActive ? context.l10n.active : context.l10n.inactive,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: user.isActive ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}
