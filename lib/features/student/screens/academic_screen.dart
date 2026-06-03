import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../data/models/models.dart';

class AcademicScreen extends ConsumerStatefulWidget {
  const AcademicScreen({super.key});
  @override
  ConsumerState<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends ConsumerState<AcademicScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _search = '';
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground, elevation: 0,
        title: const Text('Academic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkMuted,
          tabs: const [Tab(text: 'Lectures'), Tab(text: 'Assignments'), Tab(text: 'Quizzes')],
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16,12,16,0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: AppColors.darkMuted, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: TabBarView(
          controller: _tabs,
          children: [
            _LecturesTab(state: state, search: _search),
            _AssignmentsTab(state: state, search: _search, userId: user?.id ?? ''),
            _QuizzesTab(state: state, search: _search, userId: user?.id ?? ''),
          ],
        )),
      ]),
    );
  }
}

class _LecturesTab extends StatelessWidget {
  final AcademicState state; final String search;
  const _LecturesTab({required this.state, required this.search});
  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const Padding(padding: EdgeInsets.all(16), child: ShimmerList());
    final items = state.lectures.where((l) => search.isEmpty || l.title.toLowerCase().contains(search) || l.subject.toLowerCase().contains(search)).toList();
    if (items.isEmpty) return const EmptyState(icon: Icons.library_books_outlined, title: 'No Lectures', subtitle: 'Lectures will appear here once your lecturer uploads them.');
    return RefreshIndicator(
      onRefresh: () async {}, color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final l = items[i];
          return GestureDetector(
            onTap: () => context.push('/lecture/${l.id}'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.library_books, color: AppColors.primary, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Tag(l.subject, AppColors.primary),
                    const SizedBox(width: 6),
                    Text('${l.views} views', style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
                  ]),
                ])),
                if (l.fileUrl.isNotEmpty) const Icon(Icons.picture_as_pdf, color: AppColors.accent, size: 18),
                const Icon(Icons.chevron_right, color: AppColors.darkMuted, size: 18),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  final AcademicState state; final String search, userId;
  const _AssignmentsTab({required this.state, required this.search, required this.userId});
  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const Padding(padding: EdgeInsets.all(16), child: ShimmerList());
    final submitted = state.submissions.map((s) => s.assignmentId).toSet();
    final items = state.assignments.where((a) => search.isEmpty || a.title.toLowerCase().contains(search)).toList();
    if (items.isEmpty) return const EmptyState(icon: Icons.assignment_outlined, title: 'No Assignments', subtitle: 'Assignments will appear here.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = items[i];
        final done = submitted.contains(a.id);
        final graded = state.submissions.where((s) => s.assignmentId == a.id).firstOrNull?.status == SubmissionStatus.graded;
        final days = a.daysUntilDeadline;
        return GestureDetector(
          onTap: () => context.push('/assignment/${a.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: done ? AppColors.success.withValues(alpha: 0.3) : a.isOverdue ? AppColors.danger.withValues(alpha: 0.3) : AppColors.darkBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                if (graded) _Badge('Graded', AppColors.success)
                else if (done) _Badge('Submitted', AppColors.accent)
                else if (a.isOverdue) _Badge('Overdue', AppColors.danger)
                else if (days <= 2) _Badge('Due soon', AppColors.warning)
                else _Badge('Pending', AppColors.darkMuted),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _Tag(a.subject, AppColors.primary),
                const Spacer(),
                Icon(Icons.schedule, size: 13, color: a.isOverdue ? AppColors.danger : AppColors.darkMuted),
                const SizedBox(width: 3),
                Text(a.isOverdue ? 'Overdue' : '$days days left',
                  style: TextStyle(color: a.isOverdue ? AppColors.danger : AppColors.darkMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Text('Total Marks: ${a.totalMarks}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
            ]),
          ),
        );
      },
    );
  }
}

class _QuizzesTab extends StatelessWidget {
  final AcademicState state; final String search, userId;
  const _QuizzesTab({required this.state, required this.search, required this.userId});
  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const Padding(padding: EdgeInsets.all(16), child: ShimmerList());
    final attempted = state.attempts.map((a) => a.quizId).toSet();
    final items = state.quizzes.where((q) => search.isEmpty || q.title.toLowerCase().contains(search)).toList();
    if (items.isEmpty) return const EmptyState(icon: Icons.quiz_outlined, title: 'No Quizzes', subtitle: 'Quizzes will appear here.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final q = items[i];
        final done = attempted.contains(q.id);
        final attempt = state.attempts.where((a) => a.quizId == q.id).firstOrNull;
        return GestureDetector(
          onTap: () => done ? context.push('/quiz-result/${attempt?.id}') : context.push('/quiz/${q.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: done ? AppColors.success.withValues(alpha: 0.3) : AppColors.darkBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(q.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                if (done && attempt != null) _Badge('${attempt.score}/${attempt.totalMarks}', AppColors.success)
                else _Badge('${q.questions.length} Qs', AppColors.primary),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _Tag(q.subject, AppColors.primary),
                const SizedBox(width: 8),
                const Icon(Icons.timer_outlined, size: 13, color: AppColors.darkMuted),
                const SizedBox(width: 3),
                Text('${q.durationMinutes} min', style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                const Spacer(),
                Text(done ? 'View Results' : 'Take Quiz', style: TextStyle(color: done ? AppColors.success : AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final String t; final Color c;
  const _Tag(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500)));
}

class _Badge extends StatelessWidget {
  final String t; final Color c;
  const _Badge(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withValues(alpha: 0.3))),
    child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)));
}
