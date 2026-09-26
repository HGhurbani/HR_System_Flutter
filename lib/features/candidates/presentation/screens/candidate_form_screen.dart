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

enum _CvFileKind { image, pdf }

class _PendingCvFile {
  final File file;
  final String fileName;
  final _CvFileKind kind;
  final TextEditingController nameController;

  _PendingCvFile({
    required this.file,
    required this.fileName,
    required this.kind,
    required String defaultName,
  }) : nameController = TextEditingController(text: defaultName);

  void dispose() => nameController.dispose();
}

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
  File? _selectedFile;
  String? _selectedFileName;
  _CvFileKind? _selectedFileKind;
  String? _existingImageUrl;
  String? _existingPdfUrl;
  final List<_PendingCvFile> _pendingFiles = [];
  bool _isUploading = false;
  int _processedFiles = 0;
  int _totalFiles = 0;

  bool get _isEditing => widget.candidateId != null;
  CandidateModel? _existingCandidate;

  @override
  void dispose() {
    _nameController.dispose();
    for (final pending in _pendingFiles) {
      pending.dispose();
    }
    super.dispose();
  }

  void _populateForm(CandidateModel candidate) {
    if (_existingCandidate?.id == candidate.id) return;
    _existingCandidate = candidate;
    _nameController.text = candidate.fullName;
    _existingImageUrl = candidate.imageUrl;
    _existingPdfUrl = candidate.cvFileUrl;
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
      if (_isEditing) {
        await _selectFile(
          file: File(picked.path),
          fileName: picked.name,
          kind: _CvFileKind.image,
        );
      } else {
        await _selectFilesForCreate([
          (
            file: File(picked.path),
            fileName: picked.name,
            kind: _CvFileKind.image,
            size: null
          ),
        ]);
      }
    }
  }

  Future<void> _pickCvImageFromGallery() async {
    final picker = ImagePicker();
    if (_isEditing) {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 88,
      );
      if (picked == null) return;
      await _selectFile(
        file: File(picked.path),
        fileName: picked.name,
        kind: _CvFileKind.image,
      );
      return;
    }

    final picked = await picker.pickMultiImage(
      maxWidth: 2400,
      imageQuality: 88,
    );
    if (picked.isEmpty) return;
    await _selectFilesForCreate(
      picked
          .map((image) => (
                file: File(image.path),
                fileName: image.name,
                kind: _CvFileKind.image,
                size: null,
              ))
          .toList(),
    );
  }

  Future<void> _pickCvFromFiles() async {
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
      allowMultiple: !_isEditing,
      withData: false,
    );
    final pickedFiles = result?.files ?? const <PlatformFile>[];
    if (pickedFiles.isEmpty) return;

    final validSelections =
        <({File file, String fileName, _CvFileKind kind, int? size})>[];
    var unsupportedCount = 0;
    for (final picked in pickedFiles) {
      final path = picked.path;
      if (path == null || path.isEmpty) {
        unsupportedCount++;
        continue;
      }
      final kind = _kindForExtension(
        picked.extension ?? _extensionForPath(path),
      );
      if (kind == null) {
        unsupportedCount++;
        continue;
      }
      validSelections.add((
        file: File(path),
        fileName: picked.name,
        kind: kind,
        size: picked.size,
      ));
    }

    if (unsupportedCount > 0 && mounted) {
      context.showSnackBar(context.l10n.unsupportedCvFileType, isError: true);
    }
    if (validSelections.isEmpty) return;
    if (_isEditing) {
      final picked = validSelections.single;
      await _selectFile(
        file: picked.file,
        fileName: picked.fileName,
        kind: picked.kind,
        knownSize: picked.size,
      );
    } else {
      await _selectFilesForCreate(validSelections);
    }
  }

  Future<void> _selectFilesForCreate(
    List<({File file, String fileName, _CvFileKind kind, int? size})> files,
  ) async {
    final validFiles = <({File file, String fileName, _CvFileKind kind})>[];
    var oversizedCount = 0;
    for (final selection in files) {
      final size = selection.size ?? await selection.file.length();
      final maxSize = selection.kind == _CvFileKind.pdf
          ? AppConstants.maxCvSize
          : AppConstants.maxImageSize;
      if (size > maxSize) {
        oversizedCount++;
        continue;
      }
      validFiles.add((
        file: selection.file,
        fileName: selection.fileName,
        kind: selection.kind,
      ));
    }

    if (oversizedCount > 0 && mounted) {
      context.showSnackBar(context.l10n.cvFilesTooLarge(oversizedCount),
          isError: true);
    }
    if (validFiles.isEmpty || !mounted) return;

    for (final pending in _pendingFiles) {
      pending.dispose();
    }
    final useDefaultNames = files.length > 1;
    setState(() {
      _pendingFiles
        ..clear()
        ..addAll(
          validFiles.indexed.map(
            (entry) => _PendingCvFile(
              file: entry.$2.file,
              fileName: entry.$2.fileName,
              kind: entry.$2.kind,
              defaultName: useDefaultNames
                  ? context.l10n.defaultCvName(entry.$1 + 1)
                  : '',
            ),
          ),
        );
    });
  }

  Future<void> _selectFile({
    required File file,
    required String fileName,
    required _CvFileKind kind,
    int? knownSize,
  }) async {
    final size = knownSize ?? await file.length();
    final maxSize = kind == _CvFileKind.pdf
        ? AppConstants.maxCvSize
        : AppConstants.maxImageSize;
    if (size > maxSize) {
      if (mounted) {
        context.showSnackBar(context.l10n.cvFileTooLarge, isError: true);
      }
      return;
    }

    setState(() {
      _selectedFile = file;
      _selectedFileName = fileName;
      _selectedFileKind = kind;
    });
  }

  Future<void> _showFileSourceSheet() async {
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
                  await _pickCvFromFiles();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library_rounded),
                ),
                title: Text(l10n.pickCvFromGallery),
                subtitle: Text(l10n.pickCvFromGallerySubtitle),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickCvImageFromGallery();
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

  Future<String> _uploadFile({
    required String candidateId,
    required File file,
    required _CvFileKind kind,
  }) async {
    final extension = _extensionForPath(file.path);
    final isPdf = kind == _CvFileKind.pdf;
    final ref = FirebaseStorage.instance
        .ref()
        .child(isPdf
            ? AppConstants.storageCandidateCVs
            : AppConstants.storageCandidateImages)
        .child(isPdf ? '$candidateId.pdf' : '$candidateId.$extension');

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: isPdf ? 'application/pdf' : _imageContentType(extension),
      ),
    );
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    if (!_isEditing && _pendingFiles.isEmpty) {
      context.showSnackBar(l10n.cvFileRequired, isError: true);
      return;
    }
    setState(() {
      _isUploading = true;
      _processedFiles = 0;
      _totalFiles = _isEditing ? 1 : _pendingFiles.length;
    });
    final notifier = ref.read(candidatesNotifierProvider.notifier);

    try {
      if (!_isEditing) {
        await _submitNewCandidates(notifier);
        return;
      }

      final candidateId = widget.candidateId!;

      String? imageUrl = _existingImageUrl;
      String? pdfUrl = _existingPdfUrl;
      if (_selectedFile != null) {
        final uploadedUrl = await _uploadFile(
          candidateId: candidateId,
          file: _selectedFile!,
          kind: _selectedFileKind!,
        );
        if (_selectedFileKind == _CvFileKind.pdf) {
          imageUrl = null;
          pdfUrl = uploadedUrl;
        } else {
          imageUrl = uploadedUrl;
          pdfUrl = null;
        }
      }

      if (_isEditing) {
        final data = <String, dynamic>{
          'fullName': _nameController.text.trim(),
          'videoUrl': FieldValue.delete(),
        };

        if (_selectedFileKind == _CvFileKind.pdf) {
          data['imageUrl'] = FieldValue.delete();
          data['cvFileUrl'] = pdfUrl;
        } else if (_selectedFileKind == _CvFileKind.image) {
          data['imageUrl'] = imageUrl;
          data['cvFileUrl'] = FieldValue.delete();
        } else {
          data['imageUrl'] = imageUrl;
          data['cvFileUrl'] = pdfUrl;
        }

        final success = await notifier.updateCandidate(candidateId, data);

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
    } catch (e) {
      if (mounted) {
        context.showSnackBar('${l10n.error}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitNewCandidates(CandidatesNotifier notifier) async {
    final l10n = context.l10n;
    final firestore = ref.read(firestoreProvider);
    final pendingSnapshot = List<_PendingCvFile>.of(_pendingFiles);
    final candidates = <CandidateModel>[];
    final pendingById = <String, _PendingCvFile>{};
    final uploadFailures = <_PendingCvFile>{};

    for (final pending in pendingSnapshot) {
      final candidateId = firestore
          .collection(AppConstants.candidateProfilesCollection)
          .doc()
          .id;
      try {
        final url = await _uploadFile(
          candidateId: candidateId,
          file: pending.file,
          kind: pending.kind,
        );
        final now = DateTime.now();
        candidates.add(
          CandidateModel(
            id: candidateId,
            fullName: pending.nameController.text.trim(),
            nationality: CandidateNationality.philippines,
            age: 0,
            religion: 'muslim',
            maritalStatus: 'single',
            experienceYears: 0,
            spokenLanguages: const <String>[],
            jobType: null,
            notes: null,
            imageUrl: pending.kind == _CvFileKind.image ? url : null,
            videoUrl: null,
            cvFileUrl: pending.kind == _CvFileKind.pdf ? url : null,
            status: CandidateStatus.available,
            createdBySupervisorId: '',
            createdAt: now,
            updatedAt: now,
          ),
        );
        pendingById[candidateId] = pending;
      } catch (_) {
        uploadFailures.add(pending);
      } finally {
        if (mounted) setState(() => _processedFiles++);
      }
    }

    final creationResult = await notifier.createCandidates(candidates);
    final failedPending = <_PendingCvFile>{...uploadFailures};
    for (final failedId in creationResult.failedIds) {
      final pending = pendingById[failedId];
      if (pending != null) failedPending.add(pending);
      CandidateModel? failedCandidate;
      for (final candidate in candidates) {
        if (candidate.id == failedId) {
          failedCandidate = candidate;
          break;
        }
      }
      await _deleteUploadedCandidateFile(failedCandidate);
    }

    if (!mounted) return;
    final createdCount = creationResult.createdCount;
    final failedCount = failedPending.length;
    if (failedCount == 0) {
      context.showSnackBar(l10n.candidatesCreated(createdCount));
      context.pop();
      return;
    }

    setState(() {
      for (final pending in _pendingFiles.where(
        (item) => !failedPending.contains(item),
      )) {
        pending.dispose();
      }
      _pendingFiles
        ..clear()
        ..addAll(pendingSnapshot.where(failedPending.contains));
    });
    context.showSnackBar(
      l10n.candidatesCreatePartial(createdCount, failedCount),
      isError: true,
    );
  }

  Future<void> _deleteUploadedCandidateFile(CandidateModel? candidate) async {
    final url = candidate?.imageUrl ?? candidate?.cvFileUrl;
    if (url?.isNotEmpty != true) return;
    try {
      await FirebaseStorage.instance.refFromURL(url!).delete();
    } on FirebaseException catch (_) {}
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
            if (_isEditing) ...[
              Center(child: _buildCvFilePicker(context, l10n)),
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
            ] else
              _buildPendingFilesEditor(context, l10n),
            const SizedBox(height: 28),
            if (_isUploading && _totalFiles > 1) ...[
              Text(
                l10n.uploadingCvProgress(_processedFiles, _totalFiles),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _totalFiles == 0 ? null : _processedFiles / _totalFiles,
              ),
              const SizedBox(height: 16),
            ],
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

  Widget _buildPendingFilesEditor(BuildContext context, dynamic l10n) {
    if (_pendingFiles.isEmpty) {
      return GestureDetector(
        onTap: _showFileSourceSheet,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.backgroundLight,
            border: Border.all(color: AppColors.borderLight, width: 2),
          ),
          child: _buildEmptyFilePlaceholder(context, l10n),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.selectedCvFiles(_pendingFiles.length),
                style: context.textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: _isUploading ? null : _showFileSourceSheet,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(l10n.changeCvSelection),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._pendingFiles.map(
          (pending) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 76,
                      child: pending.kind == _CvFileKind.image
                          ? Image.file(pending.file, fit: BoxFit.cover)
                          : ColoredBox(
                              color: context.colorScheme.errorContainer,
                              child: Icon(
                                Icons.picture_as_pdf_outlined,
                                color: context.colorScheme.error,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: pending.nameController,
                          enabled: !_isUploading,
                          decoration: InputDecoration(
                            labelText: l10n.fullName,
                            isDense: true,
                          ),
                          validator: (value) => value?.trim().isEmpty == true
                              ? l10n.required
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pending.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    onPressed:
                        _isUploading ? null : () => _removePendingFile(pending),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _removePendingFile(_PendingCvFile pending) {
    setState(() => _pendingFiles.remove(pending));
    pending.dispose();
  }

  Widget _buildCvFilePicker(BuildContext context, dynamic l10n) {
    final hasSelectedImage = _selectedFileKind == _CvFileKind.image;
    final hasSelectedPdf = _selectedFileKind == _CvFileKind.pdf;
    final hasExistingImage =
        _selectedFile == null && _existingImageUrl?.isNotEmpty == true;
    final hasExistingPdf =
        _selectedFile == null && _existingPdfUrl?.isNotEmpty == true;
    final hasAnyFile = hasSelectedImage ||
        hasSelectedPdf ||
        hasExistingImage ||
        hasExistingPdf;

    return GestureDetector(
      onTap: _showFileSourceSheet,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.backgroundLight,
          border: Border.all(color: AppColors.borderLight, width: 2),
          image: hasSelectedImage
              ? DecorationImage(
                  image: FileImage(_selectedFile!),
                  fit: BoxFit.contain,
                )
              : hasExistingImage
                  ? DecorationImage(
                      image: NetworkImage(_existingImageUrl!),
                      fit: BoxFit.contain,
                    )
                  : null,
        ),
        child: !hasAnyFile
            ? _buildEmptyFilePlaceholder(context, l10n)
            : Stack(
                children: [
                  if (hasSelectedPdf || hasExistingPdf)
                    Center(
                      child: _buildPdfPlaceholder(context, l10n),
                    ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyFilePlaceholder(BuildContext context, dynamic l10n) {
    return Column(
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
    );
  }

  Widget _buildPdfPlaceholder(BuildContext context, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            color: context.colorScheme.error,
            size: 52,
          ),
          const SizedBox(height: 10),
          Text(
            _selectedFileName ?? l10n.cvFile,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  _CvFileKind? _kindForExtension(String extension) {
    final normalized = extension.toLowerCase().replaceFirst('.', '');
    if (normalized == 'pdf') return _CvFileKind.pdf;
    if (['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'].contains(normalized)) {
      return _CvFileKind.image;
    }
    return null;
  }

  String _extensionForPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return 'jpg';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  String _imageContentType(String extension) {
    switch (extension.toLowerCase()) {
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
      default:
        return 'image/jpeg';
    }
  }
}
