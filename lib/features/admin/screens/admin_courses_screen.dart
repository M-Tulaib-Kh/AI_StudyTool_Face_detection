import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/academic_provider.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/empty_state.dart';

class AdminCoursesScreen extends ConsumerWidget {
  const AdminCoursesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academicProvider);
    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('All Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => ref.read(academicProvider.notifier).loadAll())],
      ),
      body: state.isLoading
          ? const Padding(padding: EdgeInsets.all(16), child: ShimmerList())
          : state.courses.isEmpty
              ? const EmptyState(icon: Icons.school_outlined, title: 'No Courses', subtitle: 'No courses created yet')
              : RefreshIndicator(
                  onRefresh: () async => ref.read(academicProvider.notifier).loadAll(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = state.courses[i];
                      final lectures = state.lectures.where((l) => l.courseId == c.id).length;
                      final assignments = state.assignments.where((a) => a.courseId == c.id).length;
                      final quizzes = state.quizzes.where((q) => q.courseId == c.id).length;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.darkBorder)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.library_books, color: AppColors.primary, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('By ${c.lecturerName}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text(c.subject, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _Chip('$lectures Lectures', AppColors.accent),
                            const SizedBox(width: 8),
                            _Chip('$assignments Assignments', AppColors.warning),
                            const SizedBox(width: 8),
                            _Chip('$quizzes Quizzes', AppColors.success),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String t; final Color c;
  const _Chip(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(color: c, fontSize: 11)));
}
