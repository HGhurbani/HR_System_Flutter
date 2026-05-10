import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../candidates/application/candidates_providers.dart';
import '../../../candidates/data/models/candidate_model.dart';
import '../../../candidates/domain/entities/candidate_status.dart';
import '../../../candidates/presentation/widgets/candidate_cv_file_viewer.dart';
import '../employee_shell_scaffold.dart';

class EmployeeCandidatesScreen extends ConsumerWidget {
  const EmployeeCandidatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final availableAsync = ref.watch(employeeAvailableCandidatesProvider);
    final reservedAsync = ref.watch(myReservedCandidatesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: openEmployeeShellDrawer,
          ),
          title: Text(l10n.candidates),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.statusAvailable),
              Tab(text: l10n.myReservedCandidates),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            availableAsync.when(
              loading: () => const ShimmerList(count: 6, itemHeight: 126),
              error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              data: (candidates) => _CandidatesList(
                candidates: candidates,
                emptyMessage: l10n.noCandidates,
                showReserveButton: true,
              ),
            ),
            reservedAsync.when(
              loading: () => const ShimmerList(count: 6, itemHeight: 126),
              error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              data: (candidates) => _CandidatesList(
                candidates: candidates,
                emptyMessage: l10n.noReservedCandidates,
                showReserveButton: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidatesList extends StatelessWidget {
  final List<CandidateModel> candidates;
  final String emptyMessage;
  final bool showReserveButton;

  const _CandidatesList({
    required this.candidates,
    required this.emptyMessage,
    required this.showReserveButton,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return EmptyState(
        message: emptyMessage,
        icon: Icons.folder_open_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: candidates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _EmployeeCandidateCard(
        candidate: candidates[index],
        showReserveButton: showReserveButton,
      ),
    );
  }
}

class _EmployeeCandidateCard extends ConsumerWidget {
  final CandidateModel candidate;
  final bool showReserveButton;

  const _EmployeeCandidateCard({
    required this.candidate,
    required this.showReserveButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(candidatesNotifierProvider);
    final imageUrl = candidate.imageUrl;
    final pdfUrl = candidate.cvFileUrl;
    final hasFile = imageUrl?.isNotEmpty == true || pdfUrl?.isNotEmpty == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: hasFile ? () => _openFile(context) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasFile
                          ? CandidateCvFileViewer(
                              imageUrl: imageUrl,
                              pdfUrl: pdfUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            )
                          : const ColoredBox(
                              color: AppColors.backgroundLight,
                              child: Icon(
                                Icons.description_outlined,
                                color: AppColors.textDisabled,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.fullName,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _CandidateFacts(candidate: candidate),
                      if (candidate.assignedEmployeeName?.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.assignedTo}: ${candidate.assignedEmployeeName}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasFile ? () => _openFile(context) : null,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.view),
                  ),
                ),
                if (showReserveButton) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          state.isLoading ? null : () => _reserve(context, ref),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(l10n.reserveCandidate),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context) {
    final imageUrl = candidate.imageUrl;
    final pdfUrl = candidate.cvFileUrl;
    showCandidateCvFileViewer(
      context,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      pdfUrl: pdfUrl?.isNotEmpty == true ? pdfUrl : null,
    );
  }

  Future<void> _reserve(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(candidatesNotifierProvider.notifier)
        .reserveForCurrentEmployee(candidate.id);
    if (!context.mounted) return;
    context.showSnackBar(
      success ? context.l10n.candidateReserved : context.l10n.errorGeneral,
      isError: !success,
    );
  }
}

class _CandidateFacts extends StatelessWidget {
  final CandidateModel candidate;

  const _CandidateFacts({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (!candidate.isImageOnlyProfile) {
      parts.add(_nationalityLabel(candidate.nationality, context));
      if (candidate.age > 0) {
        parts.add('${candidate.age} ${context.l10n.year}');
      }
      if (candidate.experienceYears > 0) {
        parts.add(context.l10n.yearsExperience(candidate.experienceYears));
      }
    }

    if (parts.isEmpty) {
      return Text(
        context.l10n.cvFile,
        style: context.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Text(
      parts.join(' - '),
      style: context.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _nationalityLabel(
      CandidateNationality nationality, BuildContext context) {
    final l10n = context.l10n;
    switch (nationality) {
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
