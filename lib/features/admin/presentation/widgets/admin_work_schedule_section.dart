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
  late Map<int, WorkDayOverride> _overrides;
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
    _overrides = Map<int, WorkDayOverride>.from(s.dayOverrides);
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
        dayOverrides: Map.unmodifiable(_overrides),
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

  String _dayLabel(int weekday) {
    const ar = {
      DateTime.monday: 'الاثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
    };
    const en = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return context.isArabic ? ar[weekday]! : en[weekday]!;
  }

  Future<void> _editOverride(int weekday) async {
    final base = CompanyWorkSchedule(
      morningHour: _morning.hour,
      morningMinute: _morning.minute,
      morningEndHour: _morningEnd.hour,
      morningEndMinute: _morningEnd.minute,
      eveningHour: _evening.hour,
      eveningMinute: _evening.minute,
      eveningEndHour: _eveningEnd.hour,
      eveningEndMinute: _eveningEnd.minute,
      morningGraceMinutes: int.tryParse(_morningGrace.text.trim()) ?? 0,
      eveningGraceMinutes: int.tryParse(_eveningGrace.text.trim()) ?? 0,
    );
    final existing = _overrides[weekday];
    final fallback = WorkDayOverride(
      morningHour: base.morningHour,
      morningMinute: base.morningMinute,
      morningEndHour: base.morningEndHour,
      morningEndMinute: base.morningEndMinute,
      eveningHour: base.eveningHour,
      eveningMinute: base.eveningMinute,
      eveningEndHour: base.eveningEndHour,
      eveningEndMinute: base.eveningEndMinute,
      morningGraceMinutes: base.morningGraceMinutes,
      eveningGraceMinutes: base.eveningGraceMinutes,
    );
    final initial = existing ?? fallback;

    final result = await showModalBottomSheet<WorkDayOverride>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayOverrideEditorSheet(
        title: _dayLabel(weekday),
        initial: initial,
      ),
    );

    if (result == null) return;
    setState(() {
      _overrides = Map<int, WorkDayOverride>.from(_overrides)..[weekday] = result;
    });
  }

  void _removeOverride(int weekday) {
    setState(() {
      final next = Map<int, WorkDayOverride>.from(_overrides);
      next.remove(weekday);
      _overrides = next;
    });
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
            const SizedBox(height: 20),
            Text(
              context.isArabic ? 'استثناءات حسب اليوم' : 'Day overrides',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.isArabic
                  ? 'فعّل يومًا لتحديد أوقات مختلفة عن الجدول الافتراضي'
                  : 'Enable a day to use different times than the default schedule',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
              child: Column(
                children: [
                  for (final weekday in const [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ]) ...[
                    ListTile(
                      title: Text(_dayLabel(weekday)),
                      subtitle: Text(
                        _overrides.containsKey(weekday)
                            ? (context.isArabic ? 'مفعّل' : 'Enabled')
                            : (context.isArabic ? 'افتراضي' : 'Default'),
                      ),
                      leading: Switch(
                        value: _overrides.containsKey(weekday),
                        onChanged: (v) async {
                          if (v) {
                            await _editOverride(weekday);
                          } else {
                            _removeOverride(weekday);
                          }
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.isArabic ? 'تعديل' : 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: _overrides.containsKey(weekday)
                                ? () => _editOverride(weekday)
                                : null,
                          ),
                          IconButton(
                            tooltip: context.isArabic ? 'إزالة' : 'Remove',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _overrides.containsKey(weekday)
                                ? () => _removeOverride(weekday)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (weekday != DateTime.sunday) const Divider(height: 1),
                  ],
                ],
              ),
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

class _DayOverrideEditorSheet extends StatefulWidget {
  final String title;
  final WorkDayOverride initial;

  const _DayOverrideEditorSheet({
    required this.title,
    required this.initial,
  });

  @override
  State<_DayOverrideEditorSheet> createState() => _DayOverrideEditorSheetState();
}

class _DayOverrideEditorSheetState extends State<_DayOverrideEditorSheet> {
  late TimeOfDay _morning;
  late TimeOfDay _morningEnd;
  late TimeOfDay _evening;
  late TimeOfDay _eveningEnd;
  late final TextEditingController _morningGrace;
  late final TextEditingController _eveningGrace;

  @override
  void initState() {
    super.initState();
    final o = widget.initial;
    _morning = TimeOfDay(hour: o.morningHour, minute: o.morningMinute);
    _morningEnd = TimeOfDay(hour: o.morningEndHour, minute: o.morningEndMinute);
    _evening = TimeOfDay(hour: o.eveningHour, minute: o.eveningMinute);
    _eveningEnd = TimeOfDay(hour: o.eveningEndHour, minute: o.eveningEndMinute);
    _morningGrace = TextEditingController(text: '${o.morningGraceMinutes}');
    _eveningGrace = TextEditingController(text: '${o.eveningGraceMinutes}');
  }

  @override
  void dispose() {
    _morningGrace.dispose();
    _eveningGrace.dispose();
    super.dispose();
  }

  Future<void> _pickMorning() async {
    final t = await showTimePicker(context: context, initialTime: _morning);
    if (t != null) setState(() => _morning = t);
  }

  Future<void> _pickMorningEnd() async {
    final t = await showTimePicker(context: context, initialTime: _morningEnd);
    if (t != null) setState(() => _morningEnd = t);
  }

  Future<void> _pickEvening() async {
    final t = await showTimePicker(context: context, initialTime: _evening);
    if (t != null) setState(() => _evening = t);
  }

  Future<void> _pickEveningEnd() async {
    final t = await showTimePicker(context: context, initialTime: _eveningEnd);
    if (t != null) setState(() => _eveningEnd = t);
  }

  void _save() {
    final mg = int.tryParse(_morningGrace.text.trim());
    final eg = int.tryParse(_eveningGrace.text.trim());
    if (mg == null || mg < 0 || eg == null || eg < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'الرجاء إدخال دقائق سماح صحيحة'
                : 'Please enter valid grace minutes',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      WorkDayOverride(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              context.isArabic
                  ? 'اضبط أوقات هذا اليوم فقط'
                  : 'Configure this day only',
              style: TextStyle(color: Theme.of(context).hintColor),
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
              decoration: InputDecoration(labelText: l10n.graceMinutesLabel),
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
              decoration: InputDecoration(labelText: l10n.graceMinutesLabel),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
