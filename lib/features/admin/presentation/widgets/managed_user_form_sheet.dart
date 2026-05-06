import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role.dart';

class ManagedUserFormData {
  final String fullName;
  final String email;
  final String phone;
  final String position;
  final String department;
  final String employeeCode;
  final DateTime? hireDate;
  final String weeklyRestDaysMode;
  final List<int> customWeeklyRestDays;
  final bool isActive;

  const ManagedUserFormData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.position,
    required this.department,
    required this.employeeCode,
    required this.hireDate,
    this.weeklyRestDaysMode = AppUser.weeklyRestDaysModeCompany,
    this.customWeeklyRestDays = const [],
    required this.isActive,
  });

  factory ManagedUserFormData.fromUser(UserModel user) {
    return ManagedUserFormData(
      fullName: user.fullName,
      email: user.email,
      phone: user.phone ?? '',
      position: user.position ?? '',
      department: user.department ?? '',
      employeeCode: user.employeeCode ?? '',
      hireDate: user.hireDate,
      weeklyRestDaysMode: user.weeklyRestDaysMode,
      customWeeklyRestDays: user.customWeeklyRestDays,
      isActive: user.isActive,
    );
  }

  UserModel toUserModel(UserRole role, String uid) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone.isEmpty ? null : phone,
      role: role,
      employeeCode: employeeCode.isEmpty ? null : employeeCode,
      department: department.isEmpty ? null : department,
      position: position.isEmpty ? null : position,
      hireDate: hireDate,
      weeklyRestDaysMode: weeklyRestDaysMode,
      customWeeklyRestDays: customWeeklyRestDays,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class ManagedUserFormSheet extends ConsumerStatefulWidget {
  final UserRole role;
  final ManagedUserFormData? initialData;
  final UserModel? editingUser;
  final String? title;
  final Future<void> Function(
    UserModel createdUser,
    ManagedUserCreationResult result,
    ManagedUserFormData formData,
  )? onCreated;

  const ManagedUserFormSheet({
    super.key,
    required this.role,
    this.initialData,
    this.editingUser,
    this.title,
    this.onCreated,
  });

  @override
  ConsumerState<ManagedUserFormSheet> createState() =>
      _ManagedUserFormSheetState();
}

class _ManagedUserFormSheetState extends ConsumerState<ManagedUserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _positionController;
  late final TextEditingController _departmentController;
  late final TextEditingController _employeeCodeController;
  bool _isActive = true;
  bool _isSubmitting = false;
  DateTime? _hireDate;
  String _weeklyRestDaysMode = AppUser.weeklyRestDaysModeCompany;
  Set<int> _customWeeklyRestDays = {DateTime.friday};
  bool get _isEditing => widget.editingUser != null;
  bool get _isEmployee => widget.role == UserRole.employee;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ??
        (widget.editingUser != null
            ? ManagedUserFormData.fromUser(widget.editingUser!)
            : null);
    _nameController = TextEditingController(text: data?.fullName ?? '');
    _emailController = TextEditingController(text: data?.email ?? '');
    _phoneController = TextEditingController(text: data?.phone ?? '');
    _positionController = TextEditingController(text: data?.position ?? '');
    _departmentController = TextEditingController(text: data?.department ?? '');
    _employeeCodeController =
        TextEditingController(text: data?.employeeCode ?? '');
    _hireDate = data?.hireDate;
    _weeklyRestDaysMode =
        AppUser.normalizeWeeklyRestDaysMode(data?.weeklyRestDaysMode);
    _customWeeklyRestDays = (data?.customWeeklyRestDays.isNotEmpty == true
            ? data!.customWeeklyRestDays
            : const [DateTime.friday])
        .toSet();
    _isActive = data?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _employeeCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isEmployee &&
        _weeklyRestDaysMode == AppUser.weeklyRestDaysModeCustom &&
        _customWeeklyRestDays.isEmpty) {
      context.showSnackBar(
        context.isArabic
            ? 'اختر يوم راحة واحد على الأقل أو استخدم إعدادات الشركة'
            : 'Select at least one rest day or use company settings',
        isError: true,
      );
      return;
    }
    if (_isEmployee &&
        _weeklyRestDaysMode == AppUser.weeklyRestDaysModeCustom &&
        _customWeeklyRestDays.length >= 7) {
      context.showSnackBar(
        context.isArabic
            ? 'يجب أن يبقى يوم عمل واحد على الأقل'
            : 'At least one working day must remain',
        isError: true,
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final formData = ManagedUserFormData(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      position: _positionController.text.trim(),
      department: _departmentController.text.trim(),
      employeeCode: _employeeCodeController.text.trim(),
      hireDate: _hireDate,
      weeklyRestDaysMode:
          _isEmployee ? _weeklyRestDaysMode : AppUser.weeklyRestDaysModeCompany,
      customWeeklyRestDays: _isEmployee
          ? (AppUser.sanitizeWeeklyRestDays(_customWeeklyRestDays))
          : const [],
      isActive: _isActive,
    );

    try {
      if (_isEditing) {
        await ref.read(managedUserServiceProvider).updateManagedUser(
              userId: widget.editingUser!.uid,
              fullName: formData.fullName,
              phone: formData.phone,
              position: formData.position,
              department: formData.department,
              employeeCode: formData.employeeCode,
              hireDate: formData.hireDate,
              weeklyRestDaysMode: formData.weeklyRestDaysMode,
              customWeeklyRestDays: formData.customWeeklyRestDays,
              isActive: formData.isActive,
            );

        if (!mounted) return;
        Navigator.of(context).pop(true);
        context.showSnackBar(context.l10n.saveSuccess);
        return;
      }

      final result =
          await ref.read(managedUserServiceProvider).createManagedUser(
                role: widget.role,
                fullName: formData.fullName,
                email: formData.email,
                phone: formData.phone,
                position: formData.position,
                department: formData.department,
                employeeCode: formData.employeeCode,
                hireDate: formData.hireDate,
                weeklyRestDaysMode: formData.weeklyRestDaysMode,
                customWeeklyRestDays: formData.customWeeklyRestDays,
                isActive: formData.isActive,
              );

      final createdUser = formData.toUserModel(widget.role, result.userId);
      if (widget.onCreated != null) {
        await widget.onCreated!(createdUser, result, formData);
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.success),
          content: Text(
            '${context.l10n.password}: ${result.temporaryPassword}\n\n'
            '${context.l10n.info}: ${context.l10n.forgotPassword}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.done),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        context.showSnackBar(context.l10n.saveSuccess);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.title ??
        (_isEditing
            ? (widget.role == UserRole.supervisor
                ? l10n.editSupervisor
                : l10n.editEmployee)
            : widget.role == UserRole.supervisor
                ? l10n.addSupervisor
                : l10n.addEmployee);

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
              Text(title, style: context.textTheme.headlineSmall),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                readOnly: _isEditing,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty == true) return l10n.required;
                  if (!value!.contains('@')) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: l10n.position,
                  prefixIcon: const Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: InputDecoration(
                  labelText: l10n.department,
                  prefixIcon: const Icon(Icons.account_tree_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeCodeController,
                decoration: InputDecoration(
                  labelText: l10n.employeeCode,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickHireDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.hireDate,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _hireDate == null
                        ? l10n.optional
                        : '${_hireDate!.year}-${_hireDate!.month.toString().padLeft(2, '0')}-${_hireDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.active),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_isEmployee) ...[
                const SizedBox(height: 12),
                _WeeklyRestDaysSection(
                  mode: _weeklyRestDaysMode,
                  customRestDays: _customWeeklyRestDays,
                  onModeChanged: (mode) {
                    setState(() => _weeklyRestDaysMode = mode);
                  },
                  onDayChanged: (day, selected) {
                    setState(() {
                      final next = Set<int>.from(_customWeeklyRestDays);
                      if (selected) {
                        next.add(day);
                      } else {
                        next.remove(day);
                      }
                      _customWeeklyRestDays = next;
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
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

class _WeeklyRestDaysSection extends StatelessWidget {
  final String mode;
  final Set<int> customRestDays;
  final ValueChanged<String> onModeChanged;
  final void Function(int day, bool selected) onDayChanged;

  const _WeeklyRestDaysSection({
    required this.mode,
    required this.customRestDays,
    required this.onModeChanged,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = mode == AppUser.weeklyRestDaysModeCustom;

    return InputDecorator(
      decoration: InputDecoration(
        labelText:
            context.isArabic ? 'أيام الراحة الأسبوعية' : 'Weekly rest days',
        prefixIcon: const Icon(Icons.event_busy_outlined),
        border: const OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: AppUser.weeklyRestDaysModeCompany,
                icon: const Icon(Icons.business_outlined),
                label: Text(
                  context.isArabic ? 'حسب إعدادات الشركة' : 'Company settings',
                ),
              ),
              ButtonSegment<String>(
                value: AppUser.weeklyRestDaysModeCustom,
                icon: const Icon(Icons.tune_outlined),
                label: Text(context.isArabic ? 'مخصص' : 'Custom'),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selected) {
              onModeChanged(selected.first);
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (isCustom) ...[
            const Divider(height: 12),
            for (final day in const [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            ])
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_dayLabel(context, day)),
                value: customRestDays.contains(day),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (selected) => onDayChanged(day, selected == true),
              ),
          ],
        ],
      ),
    );
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
