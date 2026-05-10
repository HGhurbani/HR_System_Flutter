import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/permissions_providers.dart';

class PermissionRequestFormSheet extends ConsumerStatefulWidget {
  const PermissionRequestFormSheet({super.key});

  @override
  ConsumerState<PermissionRequestFormSheet> createState() =>
      _PermissionRequestFormSheetState();
}

class _PermissionRequestFormSheetState
    extends ConsumerState<PermissionRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _startTime;

  @override
  void dispose() {
    _hoursController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null) {
      context.showSnackBar(context.l10n.required, isError: true);
      return;
    }

    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0 || hours > 24) {
      context.showSnackBar(context.l10n.invalidPermissionHours, isError: true);
      return;
    }

    final date = DateTime(_date!.year, _date!.month, _date!.day);
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final success = await ref
        .read(permissionsNotifierProvider.notifier)
        .submitPermissionRequest(
          date: date,
          startTime: startTime,
          durationMinutes: (hours * 60).round(),
          reason: _reasonController.text.trim(),
        );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      context.showSnackBar(context.l10n.permissionSubmitted);
    } else {
      context.showSnackBar(context.l10n.errorGeneral, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM yyyy');
    final state = ref.watch(permissionsNotifierProvider);

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
              Text(l10n.addPermissionRequest,
                  style: context.textTheme.headlineSmall),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.date,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _date == null ? l10n.date : dateFormat.format(_date!),
                    style: TextStyle(
                      color: _date == null ? AppColors.textDisabled : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.startTime,
                    prefixIcon: const Icon(Icons.schedule_outlined),
                  ),
                  child: Text(
                    _startTime == null
                        ? l10n.time
                        : _startTime!.format(context),
                    style: TextStyle(
                      color: _startTime == null ? AppColors.textDisabled : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hoursController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.permissionHours,
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
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
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.submit,
                onPressed: state.isLoading ? null : _submit,
                isLoading: state.isLoading,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
