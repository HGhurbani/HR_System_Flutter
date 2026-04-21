import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../admin/application/admin_user_management_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_role.dart';

class ManagedUserFormData {
  final String fullName;
  final String email;
  final String phone;
  final String position;
  final String department;
  final String employeeCode;
  final DateTime? hireDate;
  final bool isActive;

  const ManagedUserFormData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.position,
    required this.department,
    required this.employeeCode,
    required this.hireDate,
    required this.isActive,
  });

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
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class ManagedUserFormSheet extends ConsumerStatefulWidget {
  final UserRole role;
  final ManagedUserFormData? initialData;
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

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController = TextEditingController(text: data?.fullName ?? '');
    _emailController = TextEditingController(text: data?.email ?? '');
    _phoneController = TextEditingController(text: data?.phone ?? '');
    _positionController = TextEditingController(text: data?.position ?? '');
    _departmentController =
        TextEditingController(text: data?.department ?? '');
    _employeeCodeController =
        TextEditingController(text: data?.employeeCode ?? '');
    _hireDate = data?.hireDate;
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
    setState(() => _isSubmitting = true);

    final formData = ManagedUserFormData(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      position: _positionController.text.trim(),
      department: _departmentController.text.trim(),
      employeeCode: _employeeCodeController.text.trim(),
      hireDate: _hireDate,
      isActive: _isActive,
    );

    try {
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
        (widget.role == UserRole.supervisor
            ? l10n.addSupervisor
            : l10n.addEmployee);

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
