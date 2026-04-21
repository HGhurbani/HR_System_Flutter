import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../salary/application/salary_providers.dart';
import '../../../salary/data/models/salary_model.dart';
import '../employee_shell_scaffold.dart';

class EmployeeSalaryScreen extends ConsumerWidget {
  const EmployeeSalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final salariesAsync = ref.watch(mySalariesProvider);
    final commissionsAsync = ref.watch(myCommissionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openEmployeeShellDrawer,
        ),
        title: Text(l10n.mySalary),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.salary),
                Tab(text: l10n.commission),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  salariesAsync.when(
                    loading: () =>
                        const ShimmerList(count: 4, itemHeight: 130),
                    error: (e, _) =>
                        Center(child: Text('${l10n.error}: $e')),
                    data: (salaries) {
                      if (salaries.isEmpty) {
                        return EmptyState(
                          message: l10n.noSalary,
                          icon: Icons.payments_outlined,
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: salaries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _SalaryCard(salary: salaries[i]),
                      );
                    },
                  ),
                  commissionsAsync.when(
                    loading: () =>
                        const ShimmerList(count: 4, itemHeight: 80),
                    error: (e, _) =>
                        Center(child: Text('${l10n.error}: $e')),
                    data: (commissions) {
                      if (commissions.isEmpty) {
                        return EmptyState(
                          message: l10n.noCommission,
                          icon: Icons.star_outline,
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: commissions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _CommissionCard(commission: commissions[i]),
                      );
                    },
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

class _SalaryCard extends StatelessWidget {
  final SalaryModel salary;

  const _SalaryCard({required this.salary});

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    salary.month,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
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
            const SizedBox(height: 12),
            _SalaryRow(
              label: l10n.basicSalary,
              amount: salary.basicSalary,
              color: AppColors.primary,
              currency: l10n.currency,
            ),
            if (salary.additions > 0)
              _SalaryRow(
                label: l10n.additions,
                amount: salary.additions,
                color: AppColors.success,
                prefix: '+',
                currency: l10n.currency,
              ),
            if (salary.commissionRuleAmount > 0)
              _SalaryRow(
                label: '${l10n.commission} (${l10n.type})',
                amount: salary.commissionRuleAmount,
                color: AppColors.accent,
                prefix: '+',
                currency: l10n.currency,
              ),
            if (salary.manualCommissionTotal > 0)
              _SalaryRow(
                label: '${l10n.commission} (${l10n.add})',
                amount: salary.manualCommissionTotal,
                color: AppColors.accent,
                prefix: '+',
                currency: l10n.currency,
              ),
            if (salary.deductions > 0)
              _SalaryRow(
                label: l10n.deductions,
                amount: salary.deductions,
                color: AppColors.error,
                prefix: '-',
                currency: l10n.currency,
              ),
            const Divider(height: 20),
            _SalaryRow(
              label: l10n.netSalary,
              amount: salary.netSalary,
              color: AppColors.secondary,
              currency: l10n.currency,
            ),
            if (salary.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                salary.notes!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String? prefix;
  final String currency;

  const _SalaryRow({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '${prefix ?? ''}${amount.toStringAsFixed(0)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  final CommissionModel commission;

  const _CommissionCard({required this.commission});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commission.month,
                    style: context.textTheme.titleMedium,
                  ),
                  if (commission.reason?.isNotEmpty == true)
                    Text(
                      commission.reason!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (commission.source?.isNotEmpty == true)
                    Text(
                      '${l10n.type}: ${commission.source}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${commission.amount.toStringAsFixed(0)} ${l10n.currency}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
