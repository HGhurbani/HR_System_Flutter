import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../attendance/application/attendance_report_pdf_service.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/data/models/attendance_report.dart';
import '../admin_shell_scaffold.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  late AttendanceDateRange _range;

  @override
  void initState() {
    super.initState();
    final today = AttendanceDateRange.dateOnly(DateTime.now());
    _range = AttendanceDateRange(start: today, end: today);
  }

  Future<void> _selectRange() async {
    final today = AttendanceDateRange.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: DateTimeRange(start: _range.start, end: _range.end),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _range = AttendanceDateRange(start: picked.start, end: picked.end);
      });
    }
  }

  Future<void> _showPdfPreview(List<AttendanceReportRow> rows) {
    const service = AttendanceReportPdfService();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.printAttendanceReport),
          ),
          body: PdfPreview(
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName:
                'attendance_${DateFormat('yyyyMMdd').format(_range.start)}_'
                '${DateFormat('yyyyMMdd').format(_range.end)}.pdf',
            build: (_) => service.build(
              range: _range,
              rows: rows,
              isArabic: context.isArabic,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reportAsync = ref.watch(attendanceReportProvider(_range));
    final rows = reportAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const IconButton(
          icon: Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.attendanceManagement),
        actions: [
          IconButton(
            tooltip: l10n.printAttendanceReport,
            icon: const Icon(Icons.print_outlined),
            onPressed: rows == null || rows.isEmpty
                ? null
                : () => _showPdfPreview(rows),
          ),
        ],
      ),
      body: Column(
        children: [
          _RangeCard(range: _range, onTap: _selectRange),
          Expanded(
            child: reportAsync.when(
              loading: () => const ShimmerList(count: 8, itemHeight: 104),
              error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              data: (reportRows) {
                if (reportRows.isEmpty) {
                  return EmptyState(
                    message: l10n.noAttendanceInRange,
                    icon: Icons.access_time_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(attendanceReportProvider(_range));
                    await ref.read(attendanceReportProvider(_range).future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: reportRows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _AdminAttendanceTile(row: reportRows[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  final AttendanceDateRange range;
  final VoidCallback onTap;

  const _RangeCard({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy-MM-dd');
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.date_range_outlined),
        title: Text(context.l10n.attendanceDateRange),
        subtitle: Text(
          '${format.format(range.start)} - ${format.format(range.end)}',
        ),
        trailing: const Icon(Icons.edit_calendar_outlined),
      ),
    );
  }
}

class _AdminAttendanceTile extends StatelessWidget {
  final AttendanceReportRow row;

  const _AdminAttendanceTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('yyyy-MM-dd');
    final l10n = context.l10n;
    final statusColor = row.status == AttendanceStatus.late
        ? AppColors.attendanceLate
        : row.status == AttendanceStatus.absent
            ? AppColors.attendanceAbsent
            : row.status == AttendanceStatus.onLeave
                ? AppColors.secondary
                : AppColors.attendancePresent;

    String timeOrDash(DateTime? value) =>
        value == null ? '-' : timeFormat.format(value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Icon(Icons.person_rounded, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.employeeName, style: context.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.date}: ${dateFormat.format(row.date)}',
                    style: context.textTheme.bodySmall,
                  ),
                  Text(
                    '${l10n.checkInTime}: ${timeOrDash(row.checkInTime)}   '
                    '${l10n.checkOutTime}: ${timeOrDash(row.checkOutTime)}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (row.latenessMinutes > 0)
                    Text(
                      '${l10n.latenessMinutes}: ${row.latenessMinutes}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.attendanceLate,
                      ),
                    ),
                ],
              ),
            ),
            _StatusBadge(status: row.status, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (status) {
      AttendanceStatus.late => l10n.attendanceLate,
      AttendanceStatus.absent => l10n.attendanceAbsent,
      AttendanceStatus.onLeave => l10n.attendanceLeave,
      AttendanceStatus.holiday => l10n.attendanceHoliday,
      AttendanceStatus.present => l10n.attendancePresent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
