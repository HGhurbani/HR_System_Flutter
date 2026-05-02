import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../attendance/data/models/attendance_policy_model.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../holidays/application/company_holidays_providers.dart';
import '../../../settings/presentation/widgets/app_appearance_settings.dart';
import '../../../settings/presentation/widgets/password_settings_section.dart';
import '../../../settings/presentation/widgets/settings_section_card.dart';
import '../admin_shell_scaffold.dart';
import '../widgets/admin_work_schedule_section.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locationsAsync = ref.watch(allCompanyLocationsProvider);
    final holidaysAsync = ref.watch(companyHolidaysProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.appSettings),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allCompanyLocationsProvider);
          ref.invalidate(companyHolidaysProvider);
          ref.invalidate(attendancePolicyProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppAppearanceSettings(),
            const AdminWorkScheduleSection(),
            const _AttendancePolicySection(),
            SettingsSectionCard(
              title: context.isArabic ? 'العطلات الرسمية' : 'Company Holidays',
              children: [
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(
                    context.isArabic
                        ? 'إدارة العطلات الرسمية'
                        : 'Manage holidays',
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'تُستثنى تلقائياً من أيام العمل لجميع الموظفين'
                        : 'Automatically excluded from working days for everyone',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      holidaysAsync.when(
                        loading: () => const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (holidays) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            holidays.length.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => context.push(AppRoutes.adminHolidays),
                ),
              ],
            ),
            SettingsSectionCard(
              title: l10n.companyLocations,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: Text(l10n.addLocation),
                  subtitle: Text(
                    context.isArabic
                        ? 'أضف موقع الشركة لتفعيل التحقق الجغرافي'
                        : 'Add office locations for geofence validation',
                  ),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: () => _showLocationSheet(context, ref),
                ),
                const Divider(height: 1),
                locationsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => ListTile(title: Text('${l10n.error}: $e')),
                  data: (locations) {
                    if (locations.isEmpty) {
                      return ListTile(
                        leading: const Icon(Icons.location_off_outlined),
                        title: Text(
                          context.isArabic
                              ? 'لا توجد مواقع بعد'
                              : 'No locations yet',
                        ),
                        subtitle: Text(
                          context.isArabic
                              ? 'اضغط "إضافة موقع" للبدء'
                              : 'Tap "Add location" to get started',
                        ),
                      );
                    }

                    return Column(
                      children: locations
                          .map(
                            (location) => ListTile(
                              leading: const Icon(Icons.location_on_rounded),
                              title: Text(location.name),
                              subtitle: Text(
                                '${location.latitude}, ${location.longitude} • ${location.radius.toStringAsFixed(0)}m',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: location.isActive,
                                    onChanged: (_) =>
                                        _toggleLocation(context, ref, location),
                                  ),
                                  IconButton(
                                    tooltip:
                                        context.isArabic ? 'حذف' : 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    color: AppColors.error,
                                    onPressed: () => _deleteLocation(
                                      context,
                                      ref,
                                      location,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.edit,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showLocationSheet(
                                      context,
                                      ref,
                                      location: location,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
            SettingsSectionCard(
              title: l10n.profile,
              children: [
                const PasswordSettingsSection(),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    final confirm = await context.showConfirmDialog(
                      title: l10n.logout,
                      message: l10n.logoutConfirm,
                      isDanger: true,
                    );
                    if (confirm == true) {
                      ref.read(authNotifierProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSheet(
    BuildContext context,
    WidgetRef ref, {
    CompanyLocation? location,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LocationEditorSheet(location: location),
    );
  }

  Future<void> _toggleLocation(
    BuildContext context,
    WidgetRef ref,
    CompanyLocation location,
  ) async {
    try {
      await ref
          .read(firestoreProvider)
          .collection(AppConstants.companyLocationsCollection)
          .doc(location.id)
          .update({
        'isActive': !location.isActive,
      });
      if (context.mounted) {
        context.showSnackBar(context.l10n.updateSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }

  Future<void> _deleteLocation(
    BuildContext context,
    WidgetRef ref,
    CompanyLocation location,
  ) async {
    final confirm = await context.showConfirmDialog(
      title: context.isArabic ? 'حذف الموقع' : 'Delete location',
      message: context.isArabic
          ? 'هل أنت متأكد من حذف "${location.name}"؟'
          : 'Are you sure you want to delete "${location.name}"?',
      isDanger: true,
    );
    if (confirm != true) return;

    try {
      await ref
          .read(firestoreProvider)
          .collection(AppConstants.companyLocationsCollection)
          .doc(location.id)
          .delete();
      if (context.mounted) {
        context.showSnackBar(context.l10n.deleteSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }
}

class _AttendancePolicySection extends ConsumerWidget {
  const _AttendancePolicySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(attendancePolicyProvider);

    return SettingsSectionCard(
      title: context.isArabic
          ? 'سياسة الحضور والرواتب'
          : 'Attendance Payroll Policy',
      children: [
        policyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => ListTile(title: Text('${context.l10n.error}: $e')),
          data: (policy) => _AttendancePolicyEditor(policy: policy),
        ),
      ],
    );
  }
}

class _AttendancePolicyEditor extends ConsumerWidget {
  final AttendancePolicyModel policy;

  const _AttendancePolicyEditor({required this.policy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restDays = policy.weeklyRestDays.toSet();
    final title =
        context.isArabic ? 'أيام الراحة الأسبوعية' : 'Weekly rest days';
    final thresholdLabel = context.isArabic
        ? 'حد نسبة الحضور للخصم'
        : 'Attendance threshold for deduction';

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.percent_rounded),
          title: Text(thresholdLabel),
          subtitle:
              Text('${policy.attendanceThresholdPercent.toStringAsFixed(0)}%'),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              title,
              style: context.textTheme.titleSmall,
            ),
          ),
        ),
        ...List.generate(7, (index) {
          final day = DateTime.monday + index;
          return CheckboxListTile(
            value: restDays.contains(day),
            onChanged: (selected) =>
                _toggleRestDay(context, ref, day, selected),
            title: Text(_dayLabel(context, day)),
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
        SwitchListTile(
          value: policy.lateCountsAsPresent,
          onChanged: null,
          title: Text(
            context.isArabic
                ? 'احتساب التأخير حضوراً كاملاً'
                : 'Late attendance counts as present',
          ),
          subtitle: Text(context.isArabic ? 'ثابت حالياً' : 'Fixed for now'),
        ),
      ],
    );
  }

  Future<void> _toggleRestDay(
    BuildContext context,
    WidgetRef ref,
    int day,
    bool? selected,
  ) async {
    final days = policy.weeklyRestDays.toSet();
    if (selected == true) {
      days.add(day);
    } else {
      days.remove(day);
    }

    if (days.length >= 7) {
      context.showSnackBar(
        context.isArabic
            ? 'يجب أن يبقى يوم عمل واحد على الأقل'
            : 'At least one working day must remain',
        isError: true,
      );
      return;
    }

    final updated = policy.copyWith(weeklyRestDays: days.toList()..sort());
    try {
      await ref
          .read(firestoreProvider)
          .collection(AppConstants.companySettingsCollection)
          .doc(AppConstants.companyAttendancePolicyDocId)
          .set(updated.toMap(), SetOptions(merge: true));
      if (context.mounted) {
        context.showSnackBar(context.l10n.updateSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }

  String _dayLabel(BuildContext context, int day) {
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
    return context.isArabic ? ar[day]! : en[day]!;
  }
}

class _LocationEditorSheet extends ConsumerStatefulWidget {
  final CompanyLocation? location;

  const _LocationEditorSheet({this.location});

  @override
  ConsumerState<_LocationEditorSheet> createState() =>
      _LocationEditorSheetState();
}

class _LocationEditorSheetState extends ConsumerState<_LocationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController = TextEditingController(text: location?.name ?? '');
    _latController =
        TextEditingController(text: location?.latitude.toString() ?? '');
    _lngController =
        TextEditingController(text: location?.longitude.toString() ?? '');
    _radiusController = TextEditingController(
      text: location?.radius.toStringAsFixed(0) ?? '200',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final collection = ref
        .read(firestoreProvider)
        .collection(AppConstants.companyLocationsCollection);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        'radius': double.parse(_radiusController.text),
        'isActive': widget.location?.isActive ?? true,
        'createdAt': widget.location == null ? DateTime.now() : null,
        'updatedAt': DateTime.now(),
      }..removeWhere((key, value) => value == null);

      if (widget.location == null) {
        await collection.add(payload);
      } else {
        await collection.doc(widget.location!.id).update(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(context.l10n.saveSuccess);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.location == null ? l10n.addLocation : l10n.edit,
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.locationName,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: InputDecoration(labelText: l10n.latitude),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? l10n.required : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: InputDecoration(labelText: l10n.longitude),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? l10n.required : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _radiusController,
                decoration: InputDecoration(
                  labelText: l10n.radius,
                  suffixText: 'm',
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
      ),
    );
  }
}
