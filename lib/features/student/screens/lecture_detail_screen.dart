
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/academic_provider.dart';
import '../../../services/storage_service.dart';

class LectureDetailScreen extends ConsumerStatefulWidget {
  final String lectureId;
  const LectureDetailScreen({super.key, required this.lectureId});
  @override
  ConsumerState<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends ConsumerState<LectureDetailScreen> {
  bool _downloading = false;
  double _downloadProgress = 0;
  bool _showPdfViewer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(academicProvider.notifier).incrementLectureView(widget.lectureId);
    });
  }

  Future<void> _downloadFile(Lecture lecture) async {
    if (lecture.fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file attached to this lecture')));
      }
      return;
    }
    setState(() { _downloading = true; _downloadProgress = 0; });
    try {
      final path = await StorageService.downloadFile(
        url: lecture.fileUrl,
        fileName: lecture.fileName.isNotEmpty ? lecture.fileName : 'lecture.pdf',
        onProgress: (p) { if (mounted) setState(() => _downloadProgress = p); },
      );
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Downloaded successfully!'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(label: 'Open', onPressed: () => OpenFilex.open(path)),
      ));
      // FIX 7.3: open only once — not twice
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download failed: ${e.toString().split(':').last.trim()}'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);

    // FIX 7.1: no crash — graceful null handling
    final lecture = state.lectures.where((l) => l.id == widget.lectureId).firstOrNull;
    if (lecture == null) {
      return ClayScaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            const Text('Lecture not found', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
          ]),
        ),
      );
    }

    if (_showPdfViewer && lecture.fileUrl.isNotEmpty) {
      return _PdfViewerPage(
        url: lecture.fileUrl,
        title: lecture.title,
        onClose: () => setState(() => _showPdfViewer = false),
        onDownload: () => _downloadFile(lecture),
      );
    }

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.darkForeground, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.library_books, size: 34, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                if (lecture.subject.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(lecture.subject, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(height: 8),
                Text(lecture.title,
                    style: const TextStyle(color: AppColors.darkForeground, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 13, color: AppColors.darkMuted),
                  const SizedBox(width: 4),
                  Text(_fmtDate(lecture.createdAt), style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.visibility_outlined, size: 13, color: AppColors.darkMuted),
                  const SizedBox(width: 4),
                  Text('${lecture.views} views', style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                ]),
              ]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
            const SizedBox(height: 20),
            if (lecture.description.isNotEmpty) ...[
              const Text('Overview', style: TextStyle(color: AppColors.darkForeground, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(lecture.description, style: const TextStyle(color: AppColors.darkForeground, fontSize: 14, height: 1.65)),
              const SizedBox(height: 20),
            ],
            // File section
            if (lecture.fileName.isNotEmpty) ...[
              const Text('Lecture Material', style: TextStyle(color: AppColors.darkForeground, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lecture.fileName,
                        style: const TextStyle(color: AppColors.darkForeground, fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text('PDF Document', style: TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                  ])),
                  IconButton(
                    onPressed: () => setState(() => _showPdfViewer = true),
                    icon: const Icon(Icons.visibility, color: AppColors.accent),
                    tooltip: 'View in-app',
                  ),
                  IconButton(
                    onPressed: _downloading ? null : () => _downloadFile(lecture),
                    tooltip: 'Download',
                    icon: _downloading
                        ? SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              value: _downloadProgress > 0 ? _downloadProgress : null,
                              strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.download, color: AppColors.primary),
                  ),
                ]),
              ),
              if (_downloading && _downloadProgress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      color: AppColors.primary,
                      backgroundColor: AppColors.darkBorder,
                      minHeight: 4,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Full-screen PDF viewer ───────────────────────────────────
class _PdfViewerPage extends StatefulWidget {
  final String url, title;
  final VoidCallback onClose, onDownload;
  const _PdfViewerPage({required this.url, required this.title, required this.onClose, required this.onDownload});

  @override
  State<_PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<_PdfViewerPage> {
  final _controller = PdfViewerController();
  bool _loading = true;
  // FIX 7.2: proper error state
  String? _error;

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onClose,
        ),
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_error == null)
            IconButton(
              icon: const Icon(Icons.zoom_in, color: Colors.white),
              onPressed: () => _controller.zoomLevel = (_controller.zoomLevel + 0.25).clamp(1.0, 5.0),
            ),
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            onPressed: widget.onDownload,
            tooltip: 'Download to device',
          ),
        ],
      ),
      body: Stack(children: [
        if (_error != null)
          // FIX 7.2: error fallback UI
          Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.darkMuted),
              const SizedBox(height: 16),
              Text('Could not load PDF', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.darkMuted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onDownload,
                icon: const Icon(Icons.download),
                label: const Text('Download Instead'),
              ),
            ]),
          ))
        else
          SfPdfViewer.network(
            widget.url,
            controller: _controller,
            onDocumentLoaded: (_) => setState(() => _loading = false),
            onDocumentLoadFailed: (d) => setState(() { _loading = false; _error = d.error; }),
            canShowScrollHead: true,
            enableDoubleTapZooming: true,
          ),
        if (_loading && _error == null)
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ]),
    );
  }
}
