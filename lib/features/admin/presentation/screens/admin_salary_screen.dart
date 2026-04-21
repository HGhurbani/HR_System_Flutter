import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../salary/application/salary_providers.dart';
import '../../../salary/data/models/employee_compensation_model.dart';
import '../../../salary/data/models/salary_model.dart';
import '../admin_shell_scaffold.dart';

class AdminSalaryScreen extends ConsumerStatefulWidget {
  const AdminSalaryScreen({super.key});

  @override
  ConsumerState<AdminSalaryScreen> createState() => _AdminSalaryScreenState();
}

class _AdminSalaryScreenState extends ConsumerState<AdminSalaryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.salaryManagement),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(context)
              .appBarTheme
              .foregroundColor
              ?.withValues(alpha: 0.72),
          indicatorColor: Theme.of(context).appBarTheme.foregroundColor,
          tabs: [
            Tab(text: l10n.salaryDetails),
            Tab(text: l10n.salary),
            Tab(text: l10n.commission),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleFab(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(_fabLabel(l10n)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CompensationProfilesTab(),
          _PayrollTab(),
          _CommissionsTab(),
        ],
      ),
    );
  }

  String _fabLabel(dynamic l10n) {
    switch (_tabController.index) {
      case 0:
        return l10n.salaryDetails;
      case 1:
        return l10n.addSalary;
      default:
        return l10n.addCommission;
    }
  }

  void _handleFab(BuildContext context) {
    switch (_tabController.index) {
      case 0:
        _showCompensationSheet(context);
        break;
      case 1:
        _showSalarySheet(context);
        break;
      default:
        _showCommissionSheet(context);
        break;
    }
  }

  void _showCompensationSheet(
    BuildContext context, {
    EmployeeCompensationModel? initialProfile,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CompensationSheet(initialProfile: initialProfile),
    );
  }

  void _showSalarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SalarySheet(),
    );
  }

  void _showCommissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CommissionSheet(),
    );
  }
}

class _CompensationProfilesTab extends ConsumerWidget {
  const _CompensationProfilesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(employeeCompensationProfilesProvider);
    final l10n = context.l10n;

    return profilesAsync.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 110),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (profiles) {
        if (profiles.isEmpty) {
          return EmptyState(
            message: l10n.noSalary,
            icon: Icons.account_balance_wallet_outlined,
            actionLabel: l10n.salaryDetails,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final profile = profiles[index];
            return InkWell(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) =>
                    _CompensationSheet(initialProfile: profile),
              ),
              child: _CompensationTile(profile: profile),
            );
          },
        );
      },
    );
  }
}

class _PayrollTab extends ConsumerWidget {
  const _PayrollTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salariesAsync = ref.watch(allSalariesProvider);
    final l10n = context.l10n;

    return salariesAsync.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 110),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (salaries) {
        if (salaries.isEmpty) {
          return EmptyState(
            message: l10n.noSalary,
            icon: Icons.payments_outlined,
            actionLabel: l10n.addSalary,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: salaries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _SalaryTile(salary: salaries[index]),
        );
      },
    );
  }
}

class _CommissionsTab extends ConsumerWidget {
  const _CommissionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commissionsAsync = ref.watch(allCommissionsProvider);
    final l10n = context.l10n;

    return commissionsAsync.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 90),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (commissions) {
        if (commissions.isEmpty) {
          return EmptyState(
            message: l10n.noCommission,
            icon: Icons.star_outline,
            actionLabel: l10n.addCommission,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: commissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) =>
              _CommissionTile(commission: commissions[index]),
        );
      },
    );
  }
}

class _CompensationTile extends StatelessWidget {
  final EmployeeCompensationModel profile;

  const _CompensationTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.employeeName ?? profile.employeeId,
                    style: context.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: profile.isCommissionEligible
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    profile.isCommissionEligible
                        ? context.l10n.commission
                        : context.l10n.inactive,
                    style: TextStyle(
                      color: profile.isCommissionEligible
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${context.l10n.basicSalary}: ${profile.basicSalary.toStringAsFixed(0)} ${context.l10n.currency}',
            ),
            const SizedBox(height: 4),
            Text(
              '${context.l10n.commission}: ${profile.commissionRuleType.value} ${profile.commissionRuleValue.toStringAsFixed(0)}',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SalaryTile extends StatelessWidget {
  final SalaryModel salary;

  const _SalaryTile({required this.salary});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    salary.employeeName ?? salary.employeeId,
                    style: context.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: salary.isApproved
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    salary.isApproved ? l10n.approvedStatus : l10n.pendingStatus,
                    style: TextStyle(
                      color:
                          salary.isApproved ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(salary.month, style: context.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  '${l10n.basicSalary}: ${salary.basicSalary.toStringAsFixed(0)} ${l10n.currency}',
                ),
                Text(
                  '${l10n.commission}: ${salary.commissionTotal.toStringAsFixed(0)} ${l10n.currency}',
                ),
                Text(
                  '${l10n.netSalary}: ${salary.netSalary.toStringAsFixed(0)} ${l10n.currency}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionTile extends StatelessWidget {
  final CommissionModel commission;

  const _CommissionTile({required this.commission});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.star_rounded, color: AppColors.accent),
        ),
        title: Text(commission.employeeName ?? commission.employeeId),
        subtitle: Text(
          '${commission.month} • ${commission.reason ?? commission.source ?? ''}',
        ),
        trailing: Text(
          '${commission.amount.toStringAsFixed(0)} ${context.l10n.currency}',
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CompensationSheet extends ConsumerStatefulWidget {
  final EmployeeCompensationModel? initialProfile;

  const _CompensationSheet({this.initialProfile});

  @override
  ConsumerState<_CompensationSheet> createState() => _CompensationSheetState();
}

class _CompensationSheetState extends ConsumerState<_CompensationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _basicController = TextEditingController();
  final _ruleValueController = TextEditingController();
  final _notesController = TextEditingController();
  UserModel? _selectedEmployee;
  bool _isCommissionEligible = false;
  CommissionRuleType _ruleType = CommissionRuleType.none;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile != null) {
      _basicController.text = profile.basicSalary.toStringAsFixed(0);
      _ruleValueController.text = profile.commissionRuleValue.toStringAsFixed(0);
      _notesController.text = profile.notes ?? '';
      _isCommissionEligible = profile.isCommissionEligible;
      _ruleType = profile.commissionRuleType;
    }
  }

  @override
  void dispose() {
    _basicController.dispose();
    _ruleValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) return;

    final success = await ref.read(salaryAdminNotifierProvider.notifier).saveCompensationProfile(
          EmployeeCompensationModel(
            employeeId: _selectedEmployee!.uid,
            employeeName: _selectedEmployee!.fullName,
            employeeCode: _selectedEmployee!.employeeCode,
            position: _selectedEmployee!.position,
            basicSalary: double.tryParse(_basicController.text) ?? 0,
            isCommissionEligible: _isCommissionEligible,
            commissionRuleType: _ruleType,
            commissionRuleValue: double.tryParse(_ruleValueController.text) ?? 0,
            notes: _notesController.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        context.showSnackBar(context.l10n.saveSuccess);
      } else {
        context.showSnackBar(context.l10n.errorGeneral, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.salaryDetails, style: context.textTheme.headlineSmall),
              const SizedBox(height: 20),
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('${l10n.error}: $e'),
                data: (employees) {
                  _selectedEmployee ??= employees.cast<UserModel?>().firstWhere(
                        (employee) =>
                            employee?.uid == widget.initialProfile?.employeeId,
                        orElse: () => null,
                      );

                  return DropdownButtonFormField<UserModel>(
                    value: _selectedEmployee,
                    items: employees
                        .map(
                          (employee) => DropdownMenuItem(
                            value: employee,
                            child: Text(employee.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedEmployee = value),
                    decoration: InputDecoration(
                      labelText: l10n.employees,
                      prefixIcon: const Icon(Icons.people_outline),
                    ),
                    validator: (value) => value == null ? l10n.required : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _basicController,
                decoration: InputDecoration(
                  labelText: l10n.basicSalary,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.commission),
                value: _isCommissionEligible,
                onChanged: (value) =>
                    setState(() => _isCommissionEligible = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CommissionRuleType>(
                value: _ruleType,
                items: CommissionRuleType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _ruleType = value ?? CommissionRuleType.none),
                decoration: InputDecoration(
                  labelText: l10n.commissionDetails,
                  prefixIcon: const Icon(Icons.tune_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ruleValueController,
                decoration: InputDecoration(
                  labelText: l10n.commissionAmount,
                  prefixIcon: const Icon(Icons.percent_rounded),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommissionSheet extends ConsumerStatefulWidget {
  const _CommissionSheet();

  @override
  ConsumerState<_CommissionSheet> createState() => _CommissionSheetState();
}

class _CommissionSheetState extends ConsumerState<_CommissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _monthController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  UserModel? _selectedEmployee;
  String _source = 'manual_adjustment';

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) return;

    final success = await ref.read(salaryAdminNotifierProvider.notifier).addCommission(
          employee: _selectedEmployee!,
          month: _monthController.text.trim(),
          amount: double.tryParse(_amountController.text) ?? 0,
          reason: _reasonController.text.trim(),
          source: _source,
          notes: _notesController.text.trim(),
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        context.showSnackBar(context.l10n.saveSuccess);
      } else {
        context.showSnackBar(context.l10n.errorGeneral, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addCommission, style: context.textTheme.headlineSmall),
              const SizedBox(height: 20),
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('${l10n.error}: $e'),
                data: (employees) => DropdownButtonFormField<UserModel>(
                  items: employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee,
                          child: Text(employee.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedEmployee = value),
                  decoration: InputDecoration(
                    labelText: l10n.employees,
                    prefixIcon: const Icon(Icons.people_outline),
                  ),
                  validator: (value) => value == null ? l10n.required : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthController,
                decoration: InputDecoration(
                  labelText: l10n.commissionMonth,
                  hintText: 'yyyy-MM',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.commissionAmount,
                  prefixIcon: const Icon(Icons.star_border_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _source,
                items: const [
                  DropdownMenuItem(
                    value: 'manual_adjustment',
                    child: Text('manual_adjustment'),
                  ),
                  DropdownMenuItem(
                    value: 'performance',
                    child: Text('performance'),
                  ),
                  DropdownMenuItem(
                    value: 'candidate_conversion',
                    child: Text('candidate_conversion'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _source = value ?? 'manual_adjustment'),
                decoration: InputDecoration(
                  labelText: l10n.type,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: l10n.reason,
                  prefixIcon: const Icon(Icons.comment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalarySheet extends ConsumerStatefulWidget {
  const _SalarySheet();

  @override
  ConsumerState<_SalarySheet> createState() => _SalarySheetState();
}

class _SalarySheetState extends ConsumerState<_SalarySheet> {
  final _formKey = GlobalKey<FormState>();
  final _monthController = TextEditingController();
  final _additionsController = TextEditingController();
  final _deductionsController = TextEditingController();
  final _notesController = TextEditingController();
  UserModel? _selectedEmployee;
  bool _approveNow = true;

  @override
  void dispose() {
    _monthController.dispose();
    _additionsController.dispose();
    _deductionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) return;

    final success = await ref.read(salaryAdminNotifierProvider.notifier).generateSalary(
          employee: _selectedEmployee!,
          month: _monthController.text.trim(),
          additions: double.tryParse(_additionsController.text) ?? 0,
          deductions: double.tryParse(_deductionsController.text) ?? 0,
          notes: _notesController.text.trim(),
          approve: _approveNow,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        context.showSnackBar(context.l10n.saveSuccess);
      } else {
        context.showSnackBar(context.l10n.errorGeneral, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addSalary, style: context.textTheme.headlineSmall),
              const SizedBox(height: 20),
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('${l10n.error}: $e'),
                data: (employees) => DropdownButtonFormField<UserModel>(
                  items: employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee,
                          child: Text(employee.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedEmployee = value),
                  decoration: InputDecoration(
                    labelText: l10n.employees,
                    prefixIcon: const Icon(Icons.people_outline),
                  ),
                  validator: (value) => value == null ? l10n.required : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthController,
                decoration: InputDecoration(
                  labelText: l10n.salaryMonth,
                  hintText: 'yyyy-MM',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionsController,
                decoration: InputDecoration(
                  labelText: l10n.additions,
                  prefixIcon: const Icon(Icons.add_circle_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deductionsController,
                decoration: InputDecoration(
                  labelText: l10n.deductions,
                  prefixIcon: const Icon(Icons.remove_circle_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.approvedStatus),
                value: _approveNow,
                onChanged: (value) => setState(() => _approveNow = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
