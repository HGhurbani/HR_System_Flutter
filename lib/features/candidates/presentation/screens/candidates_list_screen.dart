import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../application/candidates_providers.dart';
import '../../data/models/candidate_model.dart';
import '../../domain/entities/candidate_status.dart';
import '../widgets/candidate_cv_file_viewer.dart';
import '../../../admin/presentation/admin_shell_scaffold.dart';

class CandidatesListScreen extends ConsumerStatefulWidget {
  final bool isAdminView;

  const CandidatesListScreen({super.key, required this.isAdminView});

  @override
  ConsumerState<CandidatesListScreen> createState() =>
      _CandidatesListScreenState();
}

class _CandidatesListScreenState extends ConsumerState<CandidatesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(candidateFilterProvider);
    final candidatesAsync = widget.isAdminView
        ? ref.watch(candidatesStreamProvider(filter))
        : ref.watch(supervisorCandidatesProvider(filter));

    return Scaffold(
      appBar: AppBar(
        leading: widget.isAdminView
            ? const IconButton(
                icon: Icon(Icons.menu_rounded),
                onPressed: openAdminShellDrawer,
              )
            : null,
        title: Text(l10n.candidateManagement),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded),
                if (filter.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterSheet(context, filter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.isAdminView) {
            context.push('${AppRoutes.adminCandidates}/add');
          } else {
            context.push('${AppRoutes.supervisorCandidates}/add');
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addCandidate),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: l10n.searchCandidates,
              leading: const Icon(Icons.search),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(candidateFilterProvider.notifier)
                              .update((s) => s.copyWith(searchQuery: ''));
                        },
                      )
                    ]
                  : null,
              onChanged: (v) => ref
                  .read(candidateFilterProvider.notifier)
                  .update((s) => s.copyWith(searchQuery: v.toLowerCase())),
            ),
          ),
          if (filter.hasActiveFilters)
            _ActiveFiltersBar(
              filter: filter,
              onClear: () => ref.read(candidateFilterProvider.notifier).state =
                  const CandidateFilter(),
            ),
          Expanded(
            child: candidatesAsync.when(
              loading: () => const ShimmerList(count: 8, itemHeight: 100),
              error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              data: (candidates) {
                final searchQuery = filter.searchQuery;
                final filtered = searchQuery.isEmpty
                    ? candidates
                    : candidates
                        .where((c) =>
                            c.fullName.toLowerCase().contains(searchQuery) ||
                            c.nationality.value
                                .toLowerCase()
                                .contains(searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    message: l10n.noCandidates,
                    icon: Icons.folder_open_outlined,
                    actionLabel: l10n.addCandidate,
                    onAction: () {
                      if (widget.isAdminView) {
                        context.push('${AppRoutes.adminCandidates}/add');
                      } else {
                        context.push('${AppRoutes.supervisorCandidates}/add');
                      }
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CandidateCard(
                    candidate: filtered[i],
                    isAdminView: widget.isAdminView,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, CandidateFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(currentFilter: filter),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final CandidateFilter filter;
  final VoidCallback onClear;

  const _ActiveFiltersBar({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (filter.status != null)
                  Chip(
                    label: Text(filter.status!.value),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {},
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(context.l10n.clear),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  final CandidateModel candidate;
  final bool isAdminView;

  const _CandidateCard({
    required this.candidate,
    required this.isAdminView,
  });

  Color _statusColor(CandidateStatus status) {
    switch (status) {
      case CandidateStatus.available:
        return AppColors.statusAvailable;
      case CandidateStatus.reserved:
        return AppColors.statusReserved;
    }
  }

  String _statusLabel(CandidateStatus status, l10n) {
    switch (status) {
      case CandidateStatus.available:
        return l10n.statusAvailable;
      case CandidateStatus.reserved:
        return l10n.statusReserved;
    }
  }

  String _nationalityLabel(CandidateNationality n, l10n) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusColor = _statusColor(candidate.status);
    final assignedColor =
        AppColors.adaptiveForegroundColor(context, AppColors.primary);

    return Card(
      child: InkWell(
        onTap: () {
          final basePath = isAdminView
              ? AppRoutes.adminCandidates
              : AppRoutes.supervisorCandidates;
          context.push('$basePath/${candidate.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.backgroundLight,
                ),
                child: candidate.imageUrl == null && candidate.cvFileUrl == null
                    ? const Icon(
                        Icons.description_outlined,
                        color: AppColors.textDisabled,
                        size: 28,
                      )
                    : CandidateCvFileViewer(
                        imageUrl: candidate.imageUrl,
                        pdfUrl: candidate.cvFileUrl,
                        width: 60,
                        height: 60,
                        borderRadius: BorderRadius.circular(12),
                        fit: BoxFit.cover,
                        placeholder: const ColoredBox(
                          color: AppColors.backgroundLight,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textDisabled,
                            size: 24,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.fullName,
                            style: context.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          label: _statusLabel(candidate.status, l10n),
                          color: statusColor,
                        ),
                      ],
                    ),
                    if (!candidate.isImageOnlyProfile) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _nationalityLabel(candidate.nationality, l10n),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.cake_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${candidate.age} ${l10n.year}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (candidate.assignedEmployeeName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_pin_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${l10n.assignedTo}: ${candidate.assignedEmployeeName}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: assignedColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                    if (isAdminView &&
                        candidate.reservedByUserName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${l10n.reservedBy}: ${candidate.reservedByUserName}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final CandidateFilter currentFilter;

  const _FilterSheet({required this.currentFilter});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  CandidateStatus? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.currentFilter.status;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.filter, style: context.textTheme.headlineSmall),
          const SizedBox(height: 20),
          Text(l10n.status, style: context.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: CandidateStatus.values.map((s) {
              final label = _statusLabel(s, l10n);
              return FilterChip(
                label: Text(label),
                selected: _status == s,
                onSelected: (v) => setState(() => _status = v ? s : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(candidateFilterProvider.notifier).state =
                        const CandidateFilter();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.clear),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(candidateFilterProvider.notifier)
                        .update((s) => s.copyWith(
                              status: _status,
                            ));
                    Navigator.pop(context);
                  },
                  child: Text(l10n.filter),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(CandidateStatus s, l10n) {
    switch (s) {
      case CandidateStatus.available:
        return l10n.statusAvailable;
      case CandidateStatus.reserved:
        return l10n.statusReserved;
    }
  }
}
