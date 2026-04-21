import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../application/leaves_providers.dart';
import '../../data/models/leave_request_model.dart';

class LeaveRequestFormSheet extends ConsumerStatefulWidget {
  final String title;
  final String submitLabel;
  final List<UserModel> employeeOptions;
  final UserModel? initialEmployee;
  final bool requireEmployeeSelection;
  final bool approveImmediately;
  final String? adminId;
  final String? adminNote;

  const LeaveRequestFormSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    this.employeeOptions = const <UserModel>[],
    this.initialEmployee,
    this.requireEmployeeSelection = false,
    this.approveImmediately = false,
    this.adminId,
    this.adminNote,
  });

  @override
  ConsumerState<LeaveRequestFormSheet> createState() =>
      _LeaveRequestFormSheetState();
}

class _LeaveRequestFormSheetState
    extends ConsumerState<LeaveRequestFormSheet> {
  static const List<LeaveType> _leaveTypes = [
    LeaveType.official,
    LeaveType.sick,
    LeaveType.emergency,
  ];

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  LeaveType _leaveType = LeaveType.official;
  DateTime? _startDate;
  DateTime? _endDate;
  UserModel? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployee;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
        _clampEmergencyEndIfNeeded();
      });
    }
  }

  void _clampEmergencyEndIfNeeded() {
    if (_leaveType != LeaveType.emergency ||
        _startDate == null ||
        _endDate == null) {
      return;
    }
    final days = LeaveRequestModel.calendarDurationDays(
      _startDate!,
      _endDate!,
    );
    if (days <= LeaveRequestModel.emergencyLeaveMaxDays) return;
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    _endDate = start.add(
      Duration(days: LeaveRequestModel.emergencyLeaveMaxDays - 1),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      context.showSnackBar(context.l10n.required, isError: true);
      return;
    }
    if (widget.requireEmployeeSelection && _selectedEmployee == null) {
      context.showSnackBar(context.l10n.required, isError: true);
      return;
    }

    final l10n = context.l10n;
    if (_leaveType == LeaveType.emergency &&
        LeaveRequestModel.calendarDurationDays(_startDate!, _endDate!) >
            LeaveRequestModel.emergencyLeaveMaxDays) {
      context.showSnackBar(l10n.emergencyLeaveExceedsMax, isError: true);
      return;
    }

    final notifier = ref.read(leavesNotifierProvider.notifier);
    final success = await notifier.submitLeaveRequest(
      type: _leaveType,
      startDate: _startDate!,
      endDate: _endDate!,
      reason: _reasonController.text.trim(),
      employeeId: _selectedEmployee?.uid,
      employeeName: _selectedEmployee?.fullName,
      initialStatus: widget.approveImmediately
          ? LeaveRequestStatus.approved
          : LeaveRequestStatus.pending,
      adminId: widget.approveImmediately ? widget.adminId : null,
      adminNote: widget.approveImmediately ? widget.adminNote : null,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      context.showSnackBar(context.l10n.leaveSubmitted);
      return;
    }
    context.showSnackBar(context.l10n.errorGeneral, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM yyyy');
    final leaveState = ref.watch(leavesNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: context.textTheme.headlineSmall),
              if (widget.requireEmployeeSelection) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<UserModel>(
                  value: _selectedEmployee,
                  decoration: InputDecoration(
                    labelText: l10n.employeeName,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  items: widget.employeeOptions
                      .map(
                        (employee) => DropdownMenuItem<UserModel>(
                          value: employee,
                          child: Text(employee.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedEmployee = value),
                  validator: (value) => widget.requireEmployeeSelection &&
                          value == null
                      ? l10n.required
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              DropdownButtonFormField<LeaveType>(
                value: _leaveType,
                decoration: InputDecoration(
                  labelText: l10n.leaveType,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: _leaveTypes.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(_typeLabel(t, l10n)),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _leaveType = v ?? LeaveType.official;
                    _clampEmergencyEndIfNeeded();
                  });
                },
              ),
              if (_leaveType == LeaveType.emergency) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.emergencyLeaveMaxDaysHint,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.startDate,
                          prefixIcon:
                              const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _startDate != null
                              ? dateFormat.format(_startDate!)
                              : l10n.date,
                          style: TextStyle(
                            color: _startDate != null
                                ? null
                                : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.endDate,
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _endDate != null
                              ? dateFormat.format(_endDate!)
                              : l10n.date,
                          style: TextStyle(
                            color: _endDate != null
                                ? null
                                : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: l10n.reason,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (v) =>
                    v?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.submitLabel,
                onPressed: leaveState.isLoading ? null : _submit,
                isLoading: leaveState.isLoading,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(LeaveType t, l10n) {
    switch (t) {
      case LeaveType.official:
        return l10n.leaveTypeAnnual;
      case LeaveType.sick:
        return l10n.leaveTypeSick;
      case LeaveType.emergency:
        return l10n.leaveTypeEmergency;
    }
  }
}
