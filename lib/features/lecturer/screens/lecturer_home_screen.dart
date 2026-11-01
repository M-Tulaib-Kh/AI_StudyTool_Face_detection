import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studylock/data/models/models.dart' show SubmissionStatus;
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../shared/widgets/shimmer_loader.dart';

class LecturerHomeScreen extends ConsumerWidget {
  const LecturerHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(academicProvider);
    final myCourses =
        state.courses.where((c) => c.lecturerId == user?.id).toList();
    final myAssignments =
        state.assignments.where((a) => a.createdBy == user?.id).toList();
    final pendingGrades = state.submissions
        .where((s) => s.status == SubmissionStatus.submitted)
        .length;

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(academicProvider.notifier).loadAll(),
        color: AppColors.primary,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            elevation: 0,
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Lecturer Dashboard',
                  style: TextStyle(color: AppColors.darkMuted, fontSize: 12)),
              Text(user?.fullName.split(' ').first ?? 'Lecturer',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ]),
            actions: [
              IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 28),
                  onPressed: () =>
                      context.push('/create-content?type=lecture')),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              Row(children: [
                _StatCard('Courses', '${myCourses.length}', Icons.library_books,
                    AppColors.primary),
                const SizedBox(width: 12),
                _StatCard('Assignments', '${myAssignments.length}',
                    Icons.assignment, AppColors.accent),
                const SizedBox(width: 12),
                _StatCard('To Grade', '$pendingGrades', Icons.grading,
                    pendingGrades > 0 ? AppColors.warning : AppColors.success),
              ]),
              const SizedBox(height: 20),
              // Quick actions
              const Text('Quick Actions',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(children: [
                _ActionBtn(
                    'Upload Lecture',
                    Icons.upload_file,
                    AppColors.primary,
                    () => context.push('/create-content?type=lecture')),
                const SizedBox(width: 12),
                _ActionBtn(
                    'Create Assignment',
                    Icons.assignment_add,
                    AppColors.accent,
                    () => context.push('/create-content?type=assignment')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _ActionBtn('Create Quiz', Icons.quiz, AppColors.warning,
                    () => context.push('/create-content?type=quiz')),
                const SizedBox(width: 12),
                _ActionBtn('View Submissions', Icons.inbox, AppColors.success,
                    () => context.go('/lecturer/manage')),
                const SizedBox(width: 12),
                _ActionBtn('Attendance', Icons.event_note_outlined,
                    AppColors.accent, () => context.push('/attendance-report')),
                const SizedBox(width: 12),
                _ActionBtn('My Stats', Icons.bar_chart, AppColors.primary,
                    () => context.push('/lecturer-performance')),
              ]),
              const SizedBox(height: 20),
              const Text('My Courses',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (state.isLoading)
                const ShimmerList(count: 2)
              else if (myCourses.isEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text('No courses yet. Create your first!',
                        style: TextStyle(color: AppColors.darkMuted)))
              else
                ...myCourses.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.darkBorder)),
                    child: Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.library_books,
                              color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(c.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text(c.subject,
                                style: const TextStyle(
                                    color: AppColors.darkMuted, fontSize: 12)),
                          ])),
                      Text(
                          '${state.lectures.where((l) => l.courseId == c.id).length} lectures',
                          style: const TextStyle(
                              color: AppColors.darkMuted, fontSize: 12)),
                    ]))),
              const SizedBox(height: 80),
            ])),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(boxShadow: AppShadows.clay, 
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.darkBorder)),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.darkMuted, fontSize: 11))
          ])));
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
      child: GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)))
              ]))));
}
