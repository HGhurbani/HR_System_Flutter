import 'dart:io';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/candidate_model.dart';

class CandidateCvShareResult {
  final int sharedCount;
  final int missingCount;

  const CandidateCvShareResult({
    required this.sharedCount,
    required this.missingCount,
  });
}

class CandidateCvShareService {
  const CandidateCvShareService();

  Future<CandidateCvShareResult> shareCandidates(
      List<CandidateModel> candidates,
      {Rect? sharePositionOrigin}) async {
    final files = <XFile>[];
    final fileNames = <String>[];
    var missingCount = 0;

    for (final candidate in candidates) {
      final fileSpec = _CandidateCvFileSpec.fromCandidate(candidate);
      if (fileSpec == null) {
        missingCount++;
        continue;
      }

      final fileName = fileSpec.fileNameFor(candidate);
      final file = await _downloadToTemporaryFile(fileName, fileSpec);
      fileNames.add(fileName);
      files.add(
        XFile(
          file.path,
          mimeType: fileSpec.mimeType,
          name: fileName,
        ),
      );
    }

    if (files.isEmpty) {
      return CandidateCvShareResult(
        sharedCount: 0,
        missingCount: missingCount,
      );
    }

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        fileNameOverrides: fileNames,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return CandidateCvShareResult(
      sharedCount: files.length,
      missingCount: missingCount,
    );
  }

  Future<File> _downloadToTemporaryFile(
    String fileName,
    _CandidateCvFileSpec fileSpec,
  ) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}${Platform.pathSeparator}$fileName';
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await FirebaseStorage.instance.refFromURL(fileSpec.url).writeToFile(file);
    return file;
  }
}

class _CandidateCvFileSpec {
  final String url;
  final String extension;
  final String mimeType;

  const _CandidateCvFileSpec({
    required this.url,
    required this.extension,
    required this.mimeType,
  });

  factory _CandidateCvFileSpec.pdf(String url) {
    return _CandidateCvFileSpec(
      url: url,
      extension: 'pdf',
      mimeType: 'application/pdf',
    );
  }

  factory _CandidateCvFileSpec.image(String url) {
    final extension = _imageExtensionFromUrl(url);
    return _CandidateCvFileSpec(
      url: url,
      extension: extension,
      mimeType: _imageMimeType(extension),
    );
  }

  static _CandidateCvFileSpec? fromCandidate(CandidateModel candidate) {
    final pdfUrl = candidate.cvFileUrl;
    if (pdfUrl?.isNotEmpty == true) {
      return _CandidateCvFileSpec.pdf(pdfUrl!);
    }

    final imageUrl = candidate.imageUrl;
    if (imageUrl?.isNotEmpty == true) {
      return _CandidateCvFileSpec.image(imageUrl!);
    }

    return null;
  }

  String fileNameFor(CandidateModel candidate) {
    final baseName = _safeFileName(candidate.fullName);
    final fallback = candidate.id.isEmpty ? 'candidate-cv' : candidate.id;
    final name = baseName.isEmpty ? fallback : baseName;
    final suffix = candidate.id.isEmpty ? '' : '-${candidate.id}';
    return '$name$suffix.$extension';
  }

  static String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    return cleaned.replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  }

  static String _imageExtensionFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.heic')) return 'heic';
    if (path.endsWith('.heif')) return 'heif';
    if (path.endsWith('.jpeg')) return 'jpeg';
    return 'jpg';
  }

  static String _imageMimeType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpeg':
        return 'image/jpeg';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
