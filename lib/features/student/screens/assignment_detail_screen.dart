import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: unused_import
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/models.dart';
import '../../../services/storage_service.dart';
import '../../../shared/widgets/app_button.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});
  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  bool _uploading = false;
  double _uploadProgress = 0;
  String? _selectedFileName;

  Future<void> _submitFile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final file = await StorageService.pickFile(
        extensions: ['pdf', 'doc', 'docx', 'zip']);
    if (file == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _selectedFileName = file.name;
    });
    try {
      final result = await StorageService.uploadFile(
          file: file,
          bucket: StorageBucket.submissions,
          userId: user.id,
          onProgress: (p) => setState(() => _uploadProgress = p));
      await ref.read(academicProvider.notifier).submitAssignment(
          assignmentId: widget.assignmentId,
          studentId: user.id,
          studentName: user.fullName,
          fileUrl: result.fileUrl,
          fileName: file.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Assignment submitted successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Upload failed: ${e.toString().split(':').last.trim()}'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);
    final user = ref.watch(currentUserProvider);
    final assignment =
        state.assignments.where((a) => a.id == widget.assignmentId).firstOrNull;

    if (assignment == null) {
      return ClayScaffold(
          backgroundColor: Colors.transparent,
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 56),
            const SizedBox(height: 12),
            const Text('Assignment not found',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => context.pop(), child: const Text('Go Back')),
          ])));
    }

    final submission = user != null
        ? state.submissions
            .where((s) =>
                s.assignmentId == assignment.id && s.studentId == user.id)
            .firstOrNull
        : null;
    final isGraded = submission?.status == SubmissionStatus.graded;

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop()),
          title: const Text('Assignment',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _Tag(assignment.subject, AppColors.primary),
                      const Spacer(),
                      _Tag('${assignment.totalMarks} Marks', AppColors.accent),
                    ]),
                    const SizedBox(height: 10),
                    Text(assignment.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.schedule,
                          size: 14,
                          color: assignment.isOverdue
                              ? AppColors.danger
                              : AppColors.warning),
                      const SizedBox(width: 5),
                      Text(
                          assignment.isOverdue
                              ? 'Overdue'
                              : 'Due in ${assignment.daysUntilDeadline} days',
                          style: TextStyle(
                              color: assignment.isOverdue
                                  ? AppColors.danger
                                  : AppColors.warning,
                              fontSize: 13)),
                    ]),
                  ])),
          const SizedBox(height: 20),

          if (assignment.description.isNotEmpty) ...[
            const Text('Description',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(assignment.description,
                style: const TextStyle(
                    color: AppColors.darkForeground,
                    fontSize: 14,
                    height: 1.6)),
            const SizedBox(height: 16),
          ],
          if (assignment.instructions.isNotEmpty) ...[
            const Text('Instructions',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(assignment.instructions,
                style: const TextStyle(
                    color: AppColors.darkForeground,
                    fontSize: 14,
                    height: 1.6)),
            const SizedBox(height: 20),
          ],

          // Grade result
          if (isGraded && submission != null) ...[
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.grade, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text('Graded',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 15))
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Text('Score: ',
                            style: TextStyle(color: AppColors.darkMuted)),
                        Text(
                            '${submission.marksObtained}/${assignment.totalMarks}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ]),
                      if (submission.feedback != null &&
                          submission.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Feedback:',
                            style: TextStyle(
                                color: AppColors.darkMuted, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(submission.feedback!,
                            style: const TextStyle(
                                color: AppColors.darkForeground,
                                fontSize: 13,
                                height: 1.5)),
                      ],
                    ])),
            const SizedBox(height: 20),
          ],

          // Upload section
          const Text('Submit Assignment',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (submission != null && !isGraded)
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Submitted',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                        Text(submission.fileName,
                            style: const TextStyle(
                                color: AppColors.darkMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ])),
                ]))
          else if (!isGraded) ...[
            const Text('Upload PDF, Word, or ZIP file from your device',
                style: TextStyle(color: AppColors.darkMuted, fontSize: 13)),
            const SizedBox(height: 12),
            if (_uploading) ...[
              LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  color: AppColors.primary,
                  backgroundColor: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6),
              const SizedBox(height: 8),
              Text(
                  'Uploading${_selectedFileName != null ? ' "$_selectedFileName"' : ''}...',
                  style: const TextStyle(
                      color: AppColors.darkMuted, fontSize: 12)),
              const SizedBox(height: 12),
            ],
            AppButton(
                label: 'Choose File & Submit',
                loading: _uploading,
                icon: Icons.attach_file,
                onTap: _submitFile),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String t;
  final Color c;
  const _Tag(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500)));
}
