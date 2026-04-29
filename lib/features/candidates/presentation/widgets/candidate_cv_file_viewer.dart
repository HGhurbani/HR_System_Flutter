import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

class CandidateCvFileViewer extends StatelessWidget {
  final String? imageUrl;
  final String? pdfUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CandidateCvFileViewer({
    super.key,
    this.imageUrl,
    this.pdfUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  bool get _hasPdf => pdfUrl?.isNotEmpty == true;
  bool get _hasImage => imageUrl?.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    return GestureDetector(
      onTap: !_hasPdf && !_hasImage
          ? null
          : () => showCandidateCvFileViewer(
                context,
                imageUrl: imageUrl,
                pdfUrl: pdfUrl,
              ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: width,
          height: height,
          child: _hasPdf
              ? const _PdfThumbnail()
              : _hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: fit,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return placeholder ??
                            const ColoredBox(
                              color: Colors.black12,
                              child: Center(child: CircularProgressIndicator()),
                            );
                      },
                      errorBuilder: (_, __, ___) =>
                          errorWidget ??
                          const ColoredBox(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                    )
                  : errorWidget ??
                      const ColoredBox(
                        color: AppColors.backgroundLight,
                        child: Center(child: Icon(Icons.description_outlined)),
                      ),
        ),
      ),
    );
  }
}

class _PdfThumbnail extends StatelessWidget {
  const _PdfThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundLight,
      child: Center(
        child: Icon(
          Icons.picture_as_pdf_outlined,
          color: Theme.of(context).colorScheme.error,
          size: 30,
        ),
      ),
    );
  }
}

Future<void> showCandidateCvFileViewer(
  BuildContext context, {
  String? imageUrl,
  String? pdfUrl,
}) async {
  if (pdfUrl?.isNotEmpty == true) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CandidateCvPdfScreen(pdfUrl: pdfUrl!),
      ),
    );
    return;
  }

  if (imageUrl?.isNotEmpty == true) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CandidateCvImageScreen(imageUrl: imageUrl!),
      ),
    );
  }
}

class _CandidateCvImageScreen extends StatelessWidget {
  final String imageUrl;

  const _CandidateCvImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.l10n.cvFile),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateCvPdfScreen extends StatelessWidget {
  final String pdfUrl;

  const _CandidateCvPdfScreen({required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cvFile)),
      body: PdfViewer.uri(Uri.parse(pdfUrl)),
    );
  }
}
