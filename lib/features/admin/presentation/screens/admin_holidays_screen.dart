import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../holidays/application/company_holidays_providers.dart';
import '../../../holidays/data/models/company_holiday_model.dart';
import '../admin_shell_scaffold.dart';

class AdminHolidaysScreen extends ConsumerWidget {
  const AdminHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final holidaysAsync = ref.watch(companyHolidaysProvider);
    final dateFormat =
        DateFormat(context.isArabic ? 'd MMM yyyy' : 'MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.isArabic ? 'العطلات الرسمية' : 'Company Holidays'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHolidayEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.isArabic ? 'إضافة عطلة' : 'Add holiday'),
      ),
      body: holidaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (holidays) {
          if (holidays.isEmpty) {
            return Center(
              child: Text(context.isArabic ? 'لا توجد عطلات' : 'No holidays'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: holidays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final h = holidays[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(h.name.isNotEmpty ? h.name : '-'),
                  subtitle: Text(dateFormat.format(h.date)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: l10n.edit,
                        onPressed: () =>
                            _showHolidayEditor(context, ref, holiday: h),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        onPressed: () => _deleteHoliday(context, ref, h),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showHolidayEditor(
    BuildContext context,
    WidgetRef ref, {
    CompanyHolidayModel? holiday,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HolidayEditorSheet(holiday: holiday),
    );
  }

  Future<void> _deleteHoliday(
    BuildContext context,
    WidgetRef ref,
    CompanyHolidayModel holiday,
  ) async {
    final confirm = await context.showConfirmDialog(
      title: context.isArabic ? 'حذف عطلة' : 'Delete holiday',
      message: context.isArabic
          ? 'هل تريد حذف "${holiday.name}"؟'
          : 'Delete "${holiday.name}"?',
      isDanger: true,
    );
    if (confirm != true) return;

    try {
      await ref
          .read(firestoreProvider)
          .collection(AppConstants.companyHolidaysCollection)
          .doc(holiday.id)
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

class _HolidayEditorSheet extends ConsumerStatefulWidget {
  final CompanyHolidayModel? holiday;
  const _HolidayEditorSheet({this.holiday});

  @override
  ConsumerState<_HolidayEditorSheet> createState() => _HolidayEditorSheetState();
}

class _HolidayEditorSheetState extends ConsumerState<_HolidayEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  DateTime? _date;
  bool _isPaid = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.holiday?.name ?? '');
    _date = widget.holiday?.date;
    _isPaid = widget.holiday?.isPaid ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      context.showSnackBar(context.l10n.required, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final date = DateTime(_date!.year, _date!.month, _date!.day);
      final payload = <String, dynamic>{
        'date': Timestamp.fromDate(date),
        'name': _nameController.text.trim(),
        'isPaid': _isPaid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final col = ref
          .read(firestoreProvider)
          .collection(AppConstants.companyHolidaysCollection);

      if (widget.holiday == null) {
        await col.add({
          ...payload,
          'createdAt': Timestamp.fromDate(now),
        });
      } else {
        await col.doc(widget.holiday!.id).update(payload);
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
    final dateLabel = _date == null
        ? (context.isArabic ? 'اختر التاريخ' : 'Pick date')
        : DateFormat('yyyy-MM-dd').format(_date!);

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
              Text(
                widget.holiday == null
                    ? (context.isArabic ? 'إضافة عطلة' : 'Add holiday')
                    : (context.isArabic ? 'تعديل عطلة' : 'Edit holiday'),
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.isArabic ? 'الاسم' : 'Name',
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) => v?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dateLabel),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isPaid,
                onChanged: (v) => setState(() => _isPaid = v),
                title: Text(context.isArabic ? 'مدفوعة' : 'Paid'),
              ),
              const SizedBox(height: 16),
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

