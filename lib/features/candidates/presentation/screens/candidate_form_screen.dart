import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/candidates_providers.dart';
import '../../data/models/candidate_model.dart';
import '../../domain/entities/candidate_status.dart';

/// CV entry is **name + CV image** only; other model fields use defaults.
class CandidateFormScreen extends ConsumerStatefulWidget {
  final String? candidateId;

  const CandidateFormScreen({super.key, this.candidateId});

  @override
  ConsumerState<CandidateFormScreen> createState() =>
      _CandidateFormScreenState();
}

class _CandidateFormScreenState extends ConsumerState<CandidateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _imageFile;
  String? _existingImageUrl;
  bool _isUploading = false;

  bool get _isEditing => widget.candidateId != null;
  CandidateModel? _existingCandidate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _populateForm(CandidateModel candidate) {
    if (_existingCandidate?.id == candidate.id) return;
    _existingCandidate = candidate;
    _nameController.text = candidate.fullName;
    _existingImageUrl = candidate.imageUrl;
    setState(() {});
  }

  Future<void> _pickCvImageFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      imageQuality: 88,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickCvImageFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null && path.isNotEmpty) {
      setState(() => _imageFile = File(path));
    }
  }

  Future<void> _showImageSourceSheet() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cvImageSourceTitle,
                style: context.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.folder_open_rounded),
                ),
                title: Text(l10n.pickCvFromFiles),
                subtitle: Text(l10n.pickCvFromFilesSubtitle),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickCvImageFromFiles();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_camera_rounded),
                ),
                title: Text(l10n.captureCvWithCamera),
                subtitle: Text(l10n.captureCvWithCameraSubtitle),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickCvImageFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(String candidateId) async {
    if (_imageFile == null) return _existingImageUrl;
    final ref = FirebaseStorage.instance
        .ref()
        .child(AppConstants.storageCandidateImages)
        .child('$candidateId.jpg');
    await ref.putFile(_imageFile!);
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final needsImage = !_isEditing &&
        _imageFile == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty);
    if (needsImage) {
      context.showSnackBar(l10n.cvImageRequired, isError: true);
      return;
    }

    setState(() => _isUploading = true);
    final notifier = ref.read(candidatesNotifierProvider.notifier);

    try {
      final candidateId = _isEditing
          ? widget.candidateId!
          : ref
              .read(firestoreProvider)
              .collection(AppConstants.candidateProfilesCollection)
              .doc()
              .id;

      final imageUrl = await _uploadImage(candidateId);

      if (_isEditing) {
        final success = await notifier.updateCandidate(candidateId, {
          'fullName': _nameController.text.trim(),
          'imageUrl': imageUrl,
          'cvFileUrl': FieldValue.delete(),
          'videoUrl': FieldValue.delete(),
        });

        if (mounted) {
          if (success) {
            context.showSnackBar(l10n.updateSuccess);
            context.pop();
          } else {
            context.showSnackBar(l10n.errorGeneral, isError: true);
          }
        }
        return;
      }

      final candidate = CandidateModel(
        id: candidateId,
        fullName: _nameController.text.trim(),
        nationality: CandidateNationality.philippines,
        age: 0,
        religion: 'muslim',
        maritalStatus: 'single',
        experienceYears: 0,
        spokenLanguages: const <String>[],
        jobType: null,
        notes: null,
        imageUrl: imageUrl,
        videoUrl: null,
        cvFileUrl: null,
        status: CandidateStatus.available,
        createdBySupervisorId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newId = await notifier.createCandidate(candidate);
      if (mounted) {
        if (newId != null) {
          context.showSnackBar(l10n.saveSuccess);
          context.pop();
        } else {
          context.showSnackBar(l10n.errorGeneral, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('${l10n.error}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final operationState = ref.watch(candidatesNotifierProvider);

    if (_isEditing) {
      final candidate =
          ref.watch(candidateDetailProvider(widget.candidateId!)).valueOrNull;
      if (candidate != null) {
        _populateForm(candidate);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editCandidate : l10n.addCandidate),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.cvImageSectionTitle,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cvImageSectionSubtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Center(child: _buildCvImagePicker(context, l10n)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  value?.trim().isEmpty == true ? l10n.required : null,
            ),
            const SizedBox(height: 28),
            AppButton(
              label: _isEditing ? l10n.save : l10n.addCandidate,
              onPressed:
                  (operationState.isLoading || _isUploading) ? null : _submit,
              isLoading: operationState.isLoading || _isUploading,
              icon: Icons.save_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCvImagePicker(BuildContext context, dynamic l10n) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.backgroundLight,
          border: Border.all(color: AppColors.borderLight, width: 2),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.contain,
                )
              : _existingImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_existingImageUrl!),
                      fit: BoxFit.contain,
                    )
                  : null,
        ),
        child: (_imageFile == null && _existingImageUrl == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.textDisabled,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.cvImagePlaceholder,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.edit_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}
