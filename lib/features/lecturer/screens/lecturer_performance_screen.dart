// ============================================================
// StudyLock — Lecturer Performance Dashboard
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/models.dart';

class LecturerPerformanceScreen extends ConsumerWidget {
  const LecturerPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(academicProvider);
    if (user == null) return const SizedBox.shrink();

    final myCourses = state.courses.where((c) => c.lecturerId == user.id).toList();
    final myAssignments = state.assignments.where((a) => myCourses.any((c) => c.id == a.courseId)).toList();
    final myQuizzes = state.quizzes.where((q) => myCourses.any((c) => c.id == q.courseId)).toList();

    // Submission stats
    final totalLectures = state.lectures.where((l) => myCourses.any((c) => c.id == l.courseId)).length;
    final pendingGrades = state.submissions.where((s) => s.status == SubmissionStatus.submitted).length;

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Performance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Summary cards
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
            children: [
              _Card('Courses', '${myCourses.length}', Icons.book_outlined, AppColors.primary),
              _Card('Lectures', '$totalLectures', Icons.video_library_outlined, AppColors.accent),
              _Card('Assignments', '${myAssignments.length}', Icons.assignment_outlined, AppColors.success),
              _Card('Quizzes', '${myQuizzes.length}', Icons.quiz_outlined, AppColors.warning),
              _Card('Pending Grades', '$pendingGrades', Icons.pending_actions, AppColors.danger),
              _Card('Active Courses', '${myCourses.length}', Icons.school_outlined, AppColors.primary),
            ],
          ),
          const SizedBox(height: 24),

          // Course breakdown
          if (myCourses.isNotEmpty) ...[
            const Align(alignment: Alignment.centerLeft, child: Text('Course Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
            const SizedBox(height: 12),
            ...myCourses.map((c) {
              final courseLectures = state.lectures.where((l) => l.courseId == c.id).length;
              final courseAssignments = myAssignments.where((a) => a.courseId == c.id).length;
              final courseQuizzes = myQuizzes.where((q) => q.courseId == c.id).length;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                  color: AppColors.darkCard, borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(c.subject, style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Chip('$courseLectures Lectures', AppColors.accent),
                    const SizedBox(width: 8),
                    _Chip('$courseAssignments Assignments', AppColors.success),
                    const SizedBox(width: 8),
                    _Chip('$courseQuizzes Quizzes', AppColors.warning),
                  ]),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _Card(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
      ]),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
