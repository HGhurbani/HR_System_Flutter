import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../attendance/data/models/company_work_schedule.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../settings/presentation/widgets/settings_section_card.dart';

class AdminWorkScheduleSection extends ConsumerWidget {
  const AdminWorkScheduleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(workScheduleProvider);

    return SettingsSectionCard(
      title: l10n.workScheduleSettings,
      children: [
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => ListTile(title: Text('${l10n.error}: $e')),
          data: (schedule) => ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: Text(l10n.workShifts),
            subtitle: Text(
              _subtitle(context, schedule, l10n),
              style: const TextStyle(height: 1.35),
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditor(context, schedule),
            ),
          ),
        ),
      ],
    );
  }

  String _subtitle(
    BuildContext context,
    CompanyWorkSchedule s,
    AppLocalizations l10n,
  ) {
    final morningStart =
        TimeOfDay(hour: s.morningHour, minute: s.morningMinute).format(context);
    final morningEnd = TimeOfDay(hour: s.morningEndHour, minute: s.morningEndMinute)
        .format(context);
    final eveningStart =
        TimeOfDay(hour: s.eveningHour, minute: s.eveningMinute).format(context);
    final eveningEnd =
        TimeOfDay(hour: s.eveningEndHour, minute: s.eveningEndMinute).format(context);
    return '${l10n.morningShift}: $morningStart → $morningEnd — ${s.morningGraceMinutes} min\n'
        '${l10n.eveningShift}: $eveningStart → $eveningEnd — ${s.eveningGraceMinutes} min';
  }

  void _openEditor(BuildContext context, CompanyWorkSchedule schedule) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WorkScheduleEditorSheet(initial: schedule),
    );
  }
}

class _WorkScheduleEditorSheet extends ConsumerStatefulWidget {
  final CompanyWorkSchedule initial;

  const _WorkScheduleEditorSheet({required this.initial});

  @override
  ConsumerState<_WorkScheduleEditorSheet> createState() =>
      _WorkScheduleEditorSheetState();
}

class _WorkScheduleEditorSheetState
    extends ConsumerState<_WorkScheduleEditorSheet> {
  late TimeOfDay _morning;
  late TimeOfDay _morningEnd;
  late TimeOfDay _evening;
  late TimeOfDay _eveningEnd;
  late final TextEditingController _morningGrace;
  late final TextEditingController _eveningGrace;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _morning = TimeOfDay(hour: s.morningHour, minute: s.morningMinute);
    _morningEnd =
        TimeOfDay(hour: s.morningEndHour, minute: s.morningEndMinute);
    _evening = TimeOfDay(hour: s.eveningHour, minute: s.eveningMinute);
    _eveningEnd =
        TimeOfDay(hour: s.eveningEndHour, minute: s.eveningEndMinute);
    _morningGrace =
        TextEditingController(text: '${s.morningGraceMinutes}');
    _eveningGrace = TextEditingController(text: '${s.eveningGraceMinutes}');
  }

  @override
  void dispose() {
    _morningGrace.dispose();
    _eveningGrace.dispose();
    super.dispose();
  }

  Future<void> _pickMorning() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _morning,
    );
    if (t != null) setState(() => _morning = t);
  }

  Future<void> _pickMorningEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _morningEnd,
    );
    if (t != null) setState(() => _morningEnd = t);
  }

  Future<void> _pickEvening() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _evening,
    );
    if (t != null) setState(() => _evening = t);
  }

  Future<void> _pickEveningEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _eveningEnd,
    );
    if (t != null) setState(() => _eveningEnd = t);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final mg = int.tryParse(_morningGrace.text.trim());
    final eg = int.tryParse(_eveningGrace.text.trim());
    if (mg == null || mg < 0) {
      context.showSnackBar(l10n.required, isError: true);
      return;
    }
    if (eg == null || eg < 0) {
      context.showSnackBar(l10n.required, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final schedule = CompanyWorkSchedule(
        morningHour: _morning.hour,
        morningMinute: _morning.minute,
        morningEndHour: _morningEnd.hour,
        morningEndMinute: _morningEnd.minute,
        eveningHour: _evening.hour,
        eveningMinute: _evening.minute,
        eveningEndHour: _eveningEnd.hour,
        eveningEndMinute: _eveningEnd.minute,
        morningGraceMinutes: mg,
        eveningGraceMinutes: eg,
      );

      await ref
          .read(firestoreProvider)
          .collection(AppConstants.companySettingsCollection)
          .doc(AppConstants.companyWorkHoursDocId)
          .set(
            {
              ...schedule.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(l10n.saveSuccess);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('${l10n.error}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.workScheduleSettings,
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.morningShift,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shiftStart),
              trailing: TextButton(
                onPressed: _pickMorning,
                child: Text(_morning.format(context)),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shiftEnd),
              trailing: TextButton(
                onPressed: _pickMorningEnd,
                child: Text(_morningEnd.format(context)),
              ),
            ),
            TextFormField(
              controller: _morningGrace,
              decoration: InputDecoration(
                labelText: l10n.graceMinutesLabel,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.eveningShift,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shiftStart),
              trailing: TextButton(
                onPressed: _pickEvening,
                child: Text(_evening.format(context)),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shiftEnd),
              trailing: TextButton(
                onPressed: _pickEveningEnd,
                child: Text(_eveningEnd.format(context)),
              ),
            ),
            TextFormField(
              controller: _eveningGrace,
              decoration: InputDecoration(
                labelText: l10n.graceMinutesLabel,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
