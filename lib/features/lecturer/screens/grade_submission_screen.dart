import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/app_button.dart';

class GradeSubmissionScreen extends ConsumerStatefulWidget {
  final String submissionId;
  const GradeSubmissionScreen({super.key, required this.submissionId});
  @override
  ConsumerState<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends ConsumerState<GradeSubmissionScreen> {
  final _marksCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  bool _saving = false, _viewingPdf = false;

  @override
  void dispose() { _marksCtrl.dispose(); _feedbackCtrl.dispose(); super.dispose(); }

  Future<void> _save(Submission sub, Assignment? assign) async {
    final marks = int.tryParse(_marksCtrl.text);
    final maxMarks = assign?.totalMarks ?? 100;
    if (marks == null || marks < 0 || marks > maxMarks) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid marks (0–$maxMarks)'), backgroundColor: AppColors.warning));
      return;
    }
    if (_feedbackCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add feedback'), backgroundColor: AppColors.warning));
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(academicProvider.notifier).gradeSubmission(
        submissionId: sub.id, marks: marks, feedback: _feedbackCtrl.text.trim(), gradedById: user.id);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graded successfully!'), backgroundColor: AppColors.success)); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);
    final sub = state.submissions.where((s) => s.id == widget.submissionId).firstOrNull;
    if (sub == null) {
      return const ClayScaffold(backgroundColor: Colors.transparent,
      body: Center(child: Text('Submission not found', style: TextStyle(color: Colors.white))));
    }
    final assign = state.assignments.where((a) => a.id == sub.assignmentId).firstOrNull;
    final isGraded = sub.status == SubmissionStatus.graded;
    if (isGraded && _marksCtrl.text.isEmpty) { _marksCtrl.text = '${sub.marksObtained ?? 0}'; _feedbackCtrl.text = sub.feedback ?? ''; }

    if (_viewingPdf && sub.fileUrl.isNotEmpty) {
      return ClayScaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.darkCard,
          title: Text(sub.fileName, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _viewingPdf = false)),
        ),
        body: SfPdfViewer.network(sub.fileUrl),
      );
    }

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: const Text('Grade Submission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Submission info
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(radius: 20, backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sub.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(assign?.title ?? 'Assignment', style: const TextStyle(color: AppColors.darkMuted, fontSize: 13)),
                ])),
                if (isGraded) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Graded', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12))),
              ]),
              const SizedBox(height: 12),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 8),
              if (sub.fileUrl.isNotEmpty) GestureDetector(
                onTap: () => setState(() => _viewingPdf = true),
                child: Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.darkSecondary, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.picture_as_pdf, color: AppColors.accent, size: 28),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sub.fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Text('Tap to view PDF', style: TextStyle(color: AppColors.darkMuted, fontSize: 11)),
                    ])),
                    const Icon(Icons.open_in_new, color: AppColors.accent, size: 18),
                  ])),
              )
              else const Text('No file submitted', style: TextStyle(color: AppColors.darkMuted)),
            ])),
          const SizedBox(height: 20),
          const SizedBox(height: 20),

          // Marks input
          if (assign != null) ...[
            Row(children: [
              const Text('Marks', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Max: ${assign.totalMarks}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _marksCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              decoration: InputDecoration(hintText: '0', suffix: Text('/ ${assign.totalMarks}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 16))),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Feedback', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackCtrl, maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Write detailed feedback for the student...'),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Save Grade', loading: _saving, onTap: () => _save(sub, assign)),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
