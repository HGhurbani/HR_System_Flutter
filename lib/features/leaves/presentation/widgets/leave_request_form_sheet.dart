import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/application/auth_providers.dart';
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
  final LeaveRequestModel? initialRequest;
  final bool allowStatusEditing;

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
    this.initialRequest,
    this.allowStatusEditing = false,
  });

  @override
  ConsumerState<LeaveRequestFormSheet> createState() =>
      _LeaveRequestFormSheetState();
}

class _LeaveRequestFormSheetState extends ConsumerState<LeaveRequestFormSheet> {
  static const List<LeaveType> _leaveTypes = [
    LeaveType.official,
    LeaveType.sick,
    LeaveType.emergency,
  ];

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _adminNoteController = TextEditingController();

  LeaveType _leaveType = LeaveType.official;
  LeaveRequestStatus _status = LeaveRequestStatus.pending;
  DateTime? _startDate;
  DateTime? _endDate;
  UserModel? _selectedEmployee;
  File? _medicalReportFile;
  String? _medicalReportFileName;
  String? _medicalReportContentType;
  String? _existingMedicalReportUrl;
  String? _existingMedicalReportFileName;
  String? _existingMedicalReportContentType;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployee;
    final request = widget.initialRequest;
    if (request != null) {
      _leaveType = request.type;
      _status = request.status;
      _startDate = request.startDate;
      _endDate = request.endDate;
      _reasonController.text = request.reason;
      _adminNoteController.text = request.adminNote ?? '';
      _existingMedicalReportUrl = request.medicalReportUrl;
      _existingMedicalReportFileName = request.medicalReportFileName;
      _existingMedicalReportContentType = request.medicalReportContentType;
    } else if (widget.approveImmediately) {
      _status = LeaveRequestStatus.approved;
      _adminNoteController.text = widget.adminNote ?? '';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _adminNoteController.dispose();
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

    final hasMedicalReport = _medicalReportFile != null ||
        _existingMedicalReportUrl?.isNotEmpty == true;
    if (_leaveType == LeaveType.sick && !hasMedicalReport) {
      context.showSnackBar(l10n.medicalReportRequired, isError: true);
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    final employeeId = _selectedEmployee?.uid ?? currentUser?.uid;
    final employeeName = _selectedEmployee?.fullName ?? currentUser?.fullName;
    if (employeeId == null || employeeId.isEmpty) {
      context.showSnackBar(l10n.errorGeneral, isError: true);
      return;
    }

    try {
      final requestId = widget.initialRequest?.id ??
          ref
              .read(firestoreProvider)
              .collection(AppConstants.leaveRequestsCollection)
              .doc()
              .id;
      var medicalReportUrl = _existingMedicalReportUrl;
      var medicalReportFileName = _existingMedicalReportFileName;
      var medicalReportContentType = _existingMedicalReportContentType;

      if (_medicalReportFile != null) {
        final uploadedUrl = await _uploadMedicalReport(
          requestId: requestId,
          employeeId: employeeId,
        );
        await _deleteExistingMedicalReport();
        medicalReportUrl = uploadedUrl;
        medicalReportFileName = _medicalReportFileName;
        medicalReportContentType = _medicalReportContentType;
      }

      final notifier = ref.read(leavesNotifierProvider.notifier);
      final success = widget.initialRequest == null
          ? await notifier.submitLeaveRequest(
              requestId: requestId,
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
              adminNote: widget.approveImmediately
                  ? _adminNoteController.text.trim()
                  : null,
              medicalReportUrl: medicalReportUrl,
              medicalReportFileName: medicalReportFileName,
              medicalReportContentType: medicalReportContentType,
            )
          : await notifier.updateLeaveRequest(
              requestId: requestId,
              type: _leaveType,
              startDate: _startDate!,
              endDate: _endDate!,
              reason: _reasonController.text.trim(),
              employeeId: employeeId,
              employeeName: employeeName,
              status: _status,
              adminNote: _adminNoteController.text.trim(),
              adminId: widget.adminId,
              medicalReportUrl: medicalReportUrl,
              medicalReportFileName: medicalReportFileName,
              medicalReportContentType: medicalReportContentType,
            );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        context.showSnackBar(
          widget.initialRequest == null
              ? context.l10n.leaveSubmitted
              : context.l10n.updateSuccess,
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
      return;
    }
    context.showSnackBar(context.l10n.errorGeneral, isError: true);
  }

  Future<void> _pickMedicalReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'heic',
        'heif',
        'webp',
      ],
      allowMultiple: false,
      withData: false,
    );
    final picked = result?.files.single;
    final path = picked?.path;
    if (picked == null || path == null || path.isEmpty) return;

    final extension = (picked.extension ?? _extensionForPath(path))
        .toLowerCase()
        .replaceFirst('.', '');
    final contentType = _contentTypeForExtension(extension);
    if (contentType == null) {
      if (mounted) {
        context.showSnackBar(context.l10n.unsupportedCvFileType, isError: true);
      }
      return;
    }
    if (picked.size > AppConstants.maxMedicalReportSize) {
      if (mounted) {
        context.showSnackBar(context.l10n.cvFileTooLarge, isError: true);
      }
      return;
    }

    setState(() {
      _medicalReportFile = File(path);
      _medicalReportFileName = picked.name;
      _medicalReportContentType = contentType;
    });
  }

  Future<String> _uploadMedicalReport({
    required String requestId,
    required String employeeId,
  }) async {
    final file = _medicalReportFile;
    final fileName = _medicalReportFileName;
    final contentType = _medicalReportContentType;
    if (file == null || fileName == null || contentType == null) {
      throw StateError('No medical report selected');
    }

    final extension = _extensionForPath(fileName);
    final ref = FirebaseStorage.instance
        .ref()
        .child(AppConstants.storageLeaveMedicalReports)
        .child(employeeId)
        .child('$requestId-${DateTime.now().millisecondsSinceEpoch}.$extension');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> _deleteExistingMedicalReport() async {
    final url = _existingMedicalReportUrl;
    if (url?.isNotEmpty != true) return;
    try {
      await FirebaseStorage.instance.refFromURL(url!).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found' &&
          e.code != 'unauthorized' &&
          e.code != 'permission-denied') {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM yyyy');
    final leaveState = ref.watch(leavesNotifierProvider);
    final isEditing = widget.initialRequest != null;

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
                  value: _resolveSelectedEmployee(),
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
                  validator: (value) =>
                      widget.requireEmployeeSelection && value == null
                          ? l10n.required
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adminNoteController,
                  decoration: InputDecoration(
                    labelText: l10n.adminNote,
                    prefixIcon: const Icon(Icons.comment_outlined),
                  ),
                  maxLines: 2,
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
              if (_leaveType == LeaveType.sick) ...[
                const SizedBox(height: 12),
                _buildMedicalReportPicker(context, l10n),
              ],
              if (widget.allowStatusEditing) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<LeaveRequestStatus>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: l10n.leaveStatus,
                    prefixIcon: const Icon(Icons.fact_check_outlined),
                  ),
                  items: LeaveRequestStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status, l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _status = value ?? LeaveRequestStatus.pending,
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
                icon: isEditing ? Icons.save_rounded : Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  UserModel? _resolveSelectedEmployee() {
    _selectedEmployee ??= widget.employeeOptions.cast<UserModel?>().firstWhere(
          (employee) => employee?.uid == widget.initialRequest?.employeeId,
          orElse: () => null,
        );
    return _selectedEmployee;
  }

  Widget _buildMedicalReportPicker(BuildContext context, dynamic l10n) {
    final fileName = _medicalReportFileName ??
        _existingMedicalReportFileName ??
        l10n.medicalReportRequiredHint;
    final hasFile = _medicalReportFile != null ||
        _existingMedicalReportUrl?.isNotEmpty == true;

    return OutlinedButton.icon(
      onPressed: _pickMedicalReport,
      icon: Icon(hasFile ? Icons.description_outlined : Icons.upload_file),
      label: Text(
        hasFile ? fileName : l10n.medicalReport,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _typeLabel(LeaveType t, dynamic l10n) {
    switch (t) {
      case LeaveType.official:
        return l10n.leaveTypeAnnual;
      case LeaveType.sick:
        return l10n.leaveTypeSick;
      case LeaveType.emergency:
        return l10n.leaveTypeEmergency;
    }
  }

  String _statusLabel(LeaveRequestStatus s, dynamic l10n) {
    switch (s) {
      case LeaveRequestStatus.approved:
        return l10n.approvedStatus;
      case LeaveRequestStatus.rejected:
        return l10n.rejectedStatus;
      case LeaveRequestStatus.pending:
        return l10n.pendingStatus;
    }
  }

  String _extensionForPath(String path) {
    final normalized = path.replaceAll('\\', '/').split('/').last;
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) return 'pdf';
    return normalized.substring(dotIndex + 1).toLowerCase();
  }

  String? _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return null;
    }
  }
}
